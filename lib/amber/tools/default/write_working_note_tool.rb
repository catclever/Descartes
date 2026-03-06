require_relative '../base_tool'

module Amber
  module Tool
    class WriteWorkingNote < Base
      name 'write_working_note'
      description 'Save a temporary key-value pair to your private memory. Use this to remember state across turns, especially if your conversation history starts to get long and risks being forgotten.'
      
      parameters(
        type: 'object',
        properties: {
          key: { type: 'string', description: 'The unique identifier for this note.' },
          value: { type: 'string', description: 'The information to remember.' }
        },
        required: ['key', 'value']
      )

      def execute(args)
        if @working_note.nil?
          return "Error: WorkingNote environment not available."
        end
        
        @working_note.set_note(args['key'], args['value'])
        "Successfully saved note '#{args['key']}'."
      end
    end
  end
end
