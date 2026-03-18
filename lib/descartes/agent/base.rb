# frozen_string_literal: true

require "ruby_llm"
require "llm_json"
require "logger"
require_relative "message_queue"
require_relative "working_note"
require_relative "token_monitor"
require_relative "../tool_registry"

module Descartes
  module Agent
    class Base
      attr_reader :name, :system_prompt, :llm

      def initialize(name:, profile_name: "openai", system_prompt: nil, tools: [], logger: nil, max_turns: 30,
                     timeout: nil)
        @name = name.to_sym
        @system_prompt = system_prompt || "You are a helpful AI assistant. You must use tools to submit your result."
        @max_turns = max_turns

        @logger = logger || Logger.new($stdout, level: Logger::INFO)

        @tools = tools.map do |t|
          if t.is_a?(Symbol) || t.is_a?(String)
            tool_class = Descartes::ToolRegistry.get_tool(t)
            @logger.warn "[Descartes::Agent::Base] Tool '#{t}' not found in registry." unless tool_class
            tool_class
          else
            t
          end
        end.compact

        # Merge explicitly requested tools with base survival tools from the Registry
        default_tools = Descartes::ToolRegistry.get_default_tools
        default_tools.each do |dt|
          @tools << dt unless @tools.include?(dt)
        end

        # Initialize ruby_llm instance using profile name
        @llm = RubyLLM::LLMService.new(profile_name: profile_name, timeout: timeout, logger: @logger)
      end

      # The execution loop given a job context
      def execute(context, job_description, run_max_turns: nil)
        @logger.info "[Descartes::Agent::#{@name}] Starting Agent Loop for job: #{job_description}"

        # 1. Prepare isolated Agent components
        # Initialize Message Queue with the agent's LLM for sliding window summarization
        queue = MessageQueue.new(@logger, llm: @llm)
        working_note = WorkingNote.new

        queue.seed_prompt(build_initial_prompt(context, job_description))

        # 2. ReAct / Tool Dispatch Loop
        turns = 0
        actual_max_turns = run_max_turns || @max_turns

        api_failed_count = 0

        loop do
          turns += 1
          if turns > actual_max_turns
            @logger.warn "[Descartes::Agent::#{@name}] Exceeded max turns (#{actual_max_turns}). Forcing exit."
            return "Error: Agent exceeded maximum allowed reasoning turns."
          end

          # Stage 1 Eviction Warning (Heartbeat Check)
          queue.heartbeat_check!

          # Stage 2 Eviction (Sliding Window)
          queue.evict!

          @logger.debug "[Descartes::Agent::#{@name}] Turn #{turns} - Calling LLM..."

          # Inject WorkingNote state dynamically into the System Prompt for this turn
          dynamic_system_prompt = @system_prompt.dup
          unless working_note.empty?
            dynamic_system_prompt << "\n\n<WORKING_NOTE_STATE>\n"
            dynamic_system_prompt << "The following are your private notes retrieved from memory. "
            dynamic_system_prompt << "Use `write_working_note` to update them if necessary.\n"
            working_note.dump.each do |k, v|
              dynamic_system_prompt << "[#{k}]: #{v}\n"
            end
            dynamic_system_prompt << "</WORKING_NOTE_STATE>\n"
          end

          # Call ruby_llm with full history and registered tools
          llm_tools = @tools.map(&:to_llm_schema)

          begin
            response = @llm.call_with_system(
              system_prompt: dynamic_system_prompt,
              conversation_history: queue.to_llm_payload,
              tools: llm_tools
            )
            api_failed_count = 0 # reset on success
          rescue defined?(RubyLLM::APIError) ? RubyLLM::APIError : StandardError, StandardError => e
            # Catch RubyLLM::APIError, or standard errors if network timeout
            api_failed_count += 1
            status = e.respond_to?(:status) && e.status ? e.status : 500

            # 401, 403, 404: Fatal Exit
            if [401, 403, 404].include?(status)
              @logger.error "[Descartes::Agent::#{@name}] Fatal API Error #{status}: #{e.message}. Halting job."
              return "Error: Fatal LLM API Failure (#{status}) - #{e.message}"
            end

            # 400: Context Eviction
            if status == 400
              if api_failed_count <= 2
                @logger.warn "[Descartes::Agent::#{@name}] Turn #{turns} - HTTP 400 (Bad Request). Popping last message from context and retrying."
                queue.pop_last_message!
              else
                @logger.warn "[Descartes::Agent::#{@name}] Turn #{turns} - HTTP 400 persists. Popping whole tool group."
                queue.pop_last_tool_group! || queue.pop_last_message!
              end
              turns -= 1
              next
            end

            # 429, 5xx, or Timeout: Exponential Backoff
            if status == 429 || status >= 500 || e.class.name.include?("Timeout") || e.class.name.include?("SystemCallError")
              if api_failed_count > 3
                @logger.error "[Descartes::Agent::#{@name}] Max API retries reached for status #{status}. Failing job."
                return "Error: LLM API Failure - #{e.message}"
              end

              base_sleep = status == 429 ? 10 : 2
              sleep_time = base_sleep * (2**(api_failed_count - 1))
              @logger.warn "[Descartes::Agent::#{@name}] API Error (#{status}): #{e.message}, retrying in #{sleep_time}s..."
              sleep(sleep_time)
              turns -= 1
              next
            end

            # Catch-all for other unhandled statuses
            @logger.error "[Descartes::Agent::#{@name}] Unhandled API Error (#{status}): #{e.message}. Failing job."
            return "Error: Unhandled LLM API Failure - #{e.message}"
          end

          # Add Assistant's response to history ONLY if it actually contains text or tools.
          # Perfectly blank hallucinations (no text, no tool) cause downstream OpenAI 400 errors.
          queue.add({ role: "assistant", content: response.content || "", tool_calls: response.tool_calls }) if (response.content && !response.content.strip.empty?) || response.has_tool_calls?

          # If the LLM didn't call any tools, we warn it and force it to.
          unless response.has_tool_calls?
            @logger.warn "[Descartes::Agent::#{@name}] Turn #{turns} - LLM responded without tools. Prompting to use tools."
            @logger.debug "\n--- DEBUG LLM RAW STRING ---\n#{response.content}\n--- END DEBUG ---"

            queue.add({
                        role: "user",
                        content: "You must use the provided tools to interact with the environment or submit your final answer via 'send_message'. Plain text replies are discarded."
                      })
            next
          end

          # 3. Execute requested tools
          @logger.info "[Descartes::Agent::#{@name}] LLM requested #{response.tool_calls.size} tool(s)."

          # Return value tracking - if a yielding tool like 'send_message' is called, we break the loop
          job_finished = false
          final_result = nil

          response.tool_calls.each do |tool_call|
            tool_name = tool_call.dig(:function, :name)
            tool_args_json = tool_call.dig(:function, :arguments)
            tool_call_id = tool_call[:id] || "call_#{rand(1000)}" # Fallback for some formats

            @logger.debug "[Descartes::Agent::#{@name}] Executing Tool: #{tool_name} with args: #{tool_args_json}"

            # Lookup the tool class to check if it yields control
            tool_class = @tools.find { |t| t.tool_name == tool_name }

            tool_result = execute_tool(tool_name, tool_args_json, context, working_note)

            # If the LLM used an Explicit Yield tool, flag loop for exit
            if tool_class&.yields_control?
              job_finished = true
              final_result = tool_result
            end

            # Append tool result back to history so LLM can observe it in the next loop
            queue.add({
                        role: "tool",
                        tool_call_id: tool_call_id,
                        name: tool_name,
                        content: tool_result.to_s
                      })
          end

          if job_finished
            @logger.info "[Descartes::Agent::#{@name}] Finished execution via explicit submission."
            return final_result
          end
        end
      end

      private

      def build_initial_prompt(context, job_description)
        <<~PROMPT
          Your goal is to complete the following job:
          "#{job_description}"

          Here is your current shared context environment snapshot:
          #{context.snapshot.to_json}

          Explore the environment using your tools. Once finished, you MUST call 'send_message'.
        PROMPT
      end

      def execute_tool(tool_name, args_json, context, working_note)
        tool_class = @tools.find { |t| t.tool_name == tool_name }

        unless tool_class
          @logger.error "Agent tried to call unknown tool: #{tool_name}"
          return "Error: Unknown tool '#{tool_name}'"
        end

        begin
          args_hash = LLMJSON.parse(args_json || "{}")
          tool_instance = tool_class.new(context, working_note)
          tool_instance.execute(args_hash)
        rescue StandardError => e
          @logger.error "Tool execution failed: #{e.message}"
          "Error executing tool: #{e.message}"
        end
      end
    end
  end
end
