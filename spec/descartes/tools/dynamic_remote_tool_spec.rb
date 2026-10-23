# frozen_string_literal: true

require "spec_helper"
require "descartes/tools/dynamic_remote_tool"

RSpec.describe Descartes::Tool::DynamicRemoteTool do
  let(:tool_schema) do
    {
      "name" => "fetch_weather",
      "description" => "Fetches weather for a given city",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "city" => { "type" => "string" }
        },
        "required" => ["city"]
      }
    }
  end

  let(:channel) { double("Channel") }
  let(:result_queue) { Queue.new }
  let(:timeout) { 1 }

  let(:tool_class) { described_class.create(tool_schema, channel, result_queue, timeout: timeout) }
  let(:context) { double("Context") }
  let(:working_note) { double("WorkingNote") }
  let(:tool_instance) { tool_class.new(context, working_note) }

  describe ".create" do
    it "creates a subclass of Descartes::Tool::DynamicRemoteTool" do
      expect(tool_class.superclass).to eq(Descartes::Tool::DynamicRemoteTool)
    end

    it "sets the tool name, description, and parameters" do
      expect(tool_class.tool_name).to eq("fetch_weather")
      expect(tool_class.tool_description).to eq("Fetches weather for a given city")
      expect(tool_class.tool_parameters).to eq(tool_schema["parameters"])
    end
  end

  describe "#execute" do
    let(:args) { { "city" => "London" } }

    before do
      # Mock SecureRandom to have a predictable call_id
      allow(SecureRandom).to receive(:hex).with(8).and_return("12345678")
    end

    it "sends the correct payload to the channel and returns the result from the queue" do
      expected_payload = {
        type: "execute_tool",
        call_id: "12345678",
        tool: "fetch_weather",
        arguments: args
      }.to_json

      expect(channel).to receive(:send).with(expected_payload)

      # Simulate another thread pushing the result to the queue
      Thread.new do
        sleep 0.1
        result_queue.push("Weather in London is sunny")
      end

      result = tool_instance.execute(args)
      expect(result).to eq("Weather in London is sunny")
    end

    it "returns a timeout error message when the queue times out" do
      expected_payload = {
        type: "execute_tool",
        call_id: "12345678",
        tool: "fetch_weather",
        arguments: args
      }.to_json

      expect(channel).to receive(:send).with(expected_payload)

      # Do not push anything to the queue so it times out
      result = tool_instance.execute(args)
      expect(result).to eq("Error: Tool execution timed out after #{timeout}s")
    end
  end
end
