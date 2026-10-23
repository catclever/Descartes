# frozen_string_literal: true

require_relative "base_tool"
require "securerandom"
require "json"

module Descartes
  module Tool
    class DynamicRemoteTool < Base
      # Factory method to dynamically create a Tool class for a remote tool
      def self.create(tool_schema, channel, result_queue, timeout: 120)
        Class.new(self) do
          name(tool_schema[:name] || tool_schema["name"])
          description(tool_schema[:description] || tool_schema["description"])
          parameters(tool_schema[:parameters] || tool_schema["parameters"])

          define_method(:execute) do |args|
            call_id = SecureRandom.hex(8)
            payload = {
              type: "execute_tool",
              call_id: call_id,
              tool: self.class.tool_name,
              arguments: args
            }.to_json

            channel.send(payload)

            result = result_queue.pop(timeout: timeout)

            if result.nil?
              "Error: Tool execution timed out after #{timeout}s"
            else
              result.to_s
            end
          end
        end
      end
    end
  end
end
