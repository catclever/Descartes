module Amber
  module Agent
    class MessageQueue
      attr_reader :history

      def initialize(logger)
        @logger = logger
        @history = []
      end

      # Adds the initial prompt block to history.
      # Must be called first.
      def seed_prompt(content)
        @history << { role: 'user', content: content }
      end

      # Add standard message
      def add(msg_hash)
        @history << msg_hash
      end

      # Core mechanism for Stage 2 Eviction (Token/Turn Sliding Window)
      # Retains the very first message (the system instructions) and the last `keep_turns` messages.
      def evict!(keep_turns = 15)
        # We need at least the initial prompt + some history to slide
        return if @history.size <= keep_turns + 1

        @logger.warn "[Amber::MessageQueue] Eviction Triggered: Sliding context window down to #{keep_turns} turns to avoid token explosion."
        
        # Keep initial seed (index 0) and the tail
        @history = [@history.first] + @history.last(keep_turns)
      end

      # Core mechanism for Stage 1 Eviction Warning
      # Injects a warning if the history is getting long and a recent warning hasn't been emitted
      def heartbeat_check!(threshold = 20)
        return false if @history.size <= threshold
        
        # Don't inject if we've already warned in the last 3 turns
        recent_warning = @history.last(3).any? do |msg| 
          msg[:content].to_s.include?("Memory limit approaching")
        end
        return false if recent_warning

        @logger.warn "[Amber::MessageQueue] Heartbeat Warning: Injecting memory limit warning."
        @history << { 
          role: 'user', 
          content: "[WARNING] Memory limit approaching. Your context window is filling up. Please summarize important context into your 'inner_thought', or submit the final result using a yielding tool (e.g. 'send_message') if your job is completed." 
        }
        true
      end

      # Formats history array into RubyLLM expected format (array of hashes)
      def to_llm_payload
        @history
      end
    end
  end
end
