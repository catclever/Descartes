# frozen_string_literal: true

require_relative "tools/base_tool"

module Descartes
  class ToolRegistry
    class << self
      def load_all!
        @registry = { default: {}, builtin: {}, external: {} }

        # Load from default directory
        Dir[File.join(__dir__, "tools/default/*.rb")].each do |file|
          require_relative file
        end

        # Load from builtin directory
        Dir[File.join(__dir__, "tools/builtin/*.rb")].each do |file|
          require_relative file
        end

        # Indexing all subclasses of Descartes::Tool::Base
        reindex!
      end

      def reindex!
        @registry = { default: {}, builtin: {}, external: {} }
        ObjectSpace.each_object(Class).select { |klass| klass < Descartes::Tool::Base }.each do |tool_class|
          next unless tool_class.tool_name

          # Determine category based on file path of the execute method
          begin
            source_file = tool_class.instance_method(:execute).source_location&.first || ""
          rescue NameError
            source_file = ""
          end

          if source_file.include?("tools/default")
            @registry[:default][tool_class.tool_name.to_sym] = tool_class
          elsif source_file.include?("tools/builtin")
            @registry[:builtin][tool_class.tool_name.to_sym] = tool_class
          else
            @registry[:external][tool_class.tool_name.to_sym] = tool_class
          end
        end
      end

      def get_default_tools
        @registry[:default].values
      end

      def get_tool(name)
        sym_name = name.to_sym
        @registry[:builtin][sym_name] || @registry[:external][sym_name] || @registry[:default][sym_name]
      end
    end
  end
end
