require_relative '../base_tool'

module Amber
  module Tool
    class SendMessage < Base
      name 'send_message'
      description 'Submit the final answer, result, or conclusion of the current job to the shared context.'
      yields_control true
      parameters(
        type: 'object',
        properties: {
          key: { type: 'string', description: 'The context key to store the result in.' },
          value: { type: 'string', description: 'The data/result to store.' }
        },
        required: ['key', 'value']
      )

      def execute(args)
        @context.set(args['key'], args['value'])
        "Successfully saved output to context key '#{args['key']}'"
      end
    end
  end
end
