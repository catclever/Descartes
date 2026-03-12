require_relative '../base_tool'

module Descartes
  module Tool
    class InnerThought < Base
      name 'inner_thought'
      description 'A private space for internal reasoning. Use this tool to think step-by-step, plan actions, or process intermediate context. This thought loop continues implicitly without yielding control.'
      
      # Implicit heartbeat: this DOES NOT yield control. Loop keeps running.
      
      parameters(
        type: 'object',
        properties: {
          thought: { type: 'string', description: 'Your internal reasoning, plan, or analysis.' }
        },
        required: ['thought']
      )

      def execute(args)
        # We record the thought into the history natively since tool calls are tracked.
        # This string is the immediate response back into the Tool observation history.
        "Thought processed."
      end
    end
  end
end
