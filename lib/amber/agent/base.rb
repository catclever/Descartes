require 'ruby_llm'
require 'logger'
require_relative '../tools/submit_job_output_tool'

module Amber
  module Agent
    class Base
      attr_reader :name, :system_prompt, :llm

      def initialize(name:, profile_name: 'openai', system_prompt: nil, tools: [], logger: nil)
        @name = name.to_sym
        @system_prompt = system_prompt || "You are a helpful AI assistant. You must use tools to submit your result."
        
        @tools = tools
        # Always append default SubmitOutput tool if not present to ensure the loop can exit
        unless @tools.any? { |t| t.tool_name == 'submit_job_output' }
          @tools << Amber::Tool::SubmitOutput
        end

        @logger = logger || Logger.new($stdout, level: Logger::INFO)
        
        # Initialize ruby_llm instance using profile name
        @llm = RubyLlm::LLMService.new(profile_name: profile_name, logger: @logger)
      end

      # The execution loop given a job context
      def execute(context, job_description)
        @logger.info "[Amber::Agent::#{@name}] Starting Agent Loop for job: #{job_description}"
        
        # 1. Prepare initial conversation history
        history = [
          { role: 'user', content: build_initial_prompt(context, job_description) }
        ]

        # 2. ReAct / Tool Dispatch Loop
        max_turns = 10
        turns = 0

        loop do
          turns += 1
          if turns > max_turns
            @logger.warn "[Amber::Agent::#{@name}] Exceeded max turns (#{max_turns}). Forcing exit."
            return "Error: Agent exceeded maximum allowed reasoning turns."
          end

          @logger.debug "[Amber::Agent::#{@name}] Turn #{turns} - Calling LLM..."
          
          # Call ruby_llm with full history and registered tools
          llm_tools = @tools.map(&:to_llm_schema)

          response = @llm.call_with_system(
            system_prompt: @system_prompt,
            conversation_history: history,
            tools: llm_tools
          )

          # Add Assistant's response to history
          history << { role: 'assistant', content: response.content || "", tool_calls: response.tool_calls }

          # If the LLM didn't call any tools, we warn it and force it to.
          unless response.has_tool_calls?
            @logger.warn "[Amber::Agent::#{@name}] Turn #{turns} - LLM responded without tools. Prompting to use tools."
            history << { 
              role: 'user', 
              content: "You must use the provided tools to interact with the environment or submit your final answer via 'submit_job_output'. Plain text replies are discarded." 
            }
            next
          end

          # 3. Execute requested tools
          @logger.info "[Amber::Agent::#{@name}] LLM requested #{response.tool_calls.size} tool(s)."
          
          # Return value tracking - if 'submit_job_output' is called, we break the loop
          job_finished = false
          final_result = nil

          response.tool_calls.each do |tool_call|
            tool_name = tool_call.dig(:function, :name)
            tool_args_json = tool_call.dig(:function, :arguments)
            tool_call_id = tool_call[:id] || "call_#{rand(1000)}" # Fallback for some formats
            
            @logger.debug "[Amber::Agent::#{@name}] Executing Tool: #{tool_name} with args: #{tool_args_json}"
            
            tool_result = execute_tool(tool_name, tool_args_json, context)
            
            # If the LLM decided to submit the job output, flag loop for exit
            if tool_name == 'submit_job_output'
              job_finished = true
              final_result = tool_result
            end

            # Append tool result back to history so LLM can observe it in the next loop
            history << { 
              role: 'tool', 
              tool_call_id: tool_call_id, 
              name: tool_name, 
              content: tool_result.to_s 
            }
          end

          if job_finished
             @logger.info "[Amber::Agent::#{@name}] Finished execution via explicit submission."
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
          
          Explore the environment using your tools. Once finished, you MUST call 'submit_job_output'.
        PROMPT
      end

      def execute_tool(tool_name, args_json, context)
        tool_class = @tools.find { |t| t.tool_name == tool_name }
        
        unless tool_class
          @logger.error "Agent tried to call unknown tool: #{tool_name}"
          return "Error: Unknown tool '#{tool_name}'"
        end

        begin
          args_hash = JSON.parse(args_json)
          tool_instance = tool_class.new(context)
          tool_instance.execute(args_hash)
        rescue StandardError => e
          @logger.error "Tool execution failed: #{e.message}"
          "Error executing tool: #{e.message}"
        end
      end
    end
  end
end
