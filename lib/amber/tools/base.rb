module Amber
  module Tool
    class Base
      class << self
        attr_reader :tool_name, :tool_description, :tool_parameters

        def name(name)
          @tool_name = name.to_s
        end

        def description(desc)
          @tool_description = desc
        end

        # Define JSON Schema parameters
        def parameters(hash)
          @tool_parameters = hash
        end

        # Convert tool definition into standard LLM schema format
        def to_llm_schema
          {
            type: "function",
            function: {
              name: @tool_name,
              description: @tool_description,
              parameters: @tool_parameters || { type: "object", properties: {}, required: [] }
            }
          }
        end
      end

      # Execution environment injected by Agent
      attr_accessor :context, :working_directory

      def initialize(context)
        @context = context
      end

      # Override this in subclasses
      def execute(args)
        raise NotImplementedError, "Subclasses must implement #execute(args)"
      end
    end
  end
end
