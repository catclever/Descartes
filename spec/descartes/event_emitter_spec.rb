# frozen_string_literal: true

require "spec_helper"
require "descartes/event_emitter"
require "descartes/agent/base"

RSpec.describe Descartes::EventEmitter do
  let(:dummy_class) do
    Class.new do
      include Descartes::EventEmitter
    end
  end

  let(:emitter) { dummy_class.new }

  describe "#on and #emit" do
    it "registers and calls a listener for a specific event" do
      called = false
      payload_received = nil

      emitter.on(:test_event) do |payload|
        called = true
        payload_received = payload
      end

      emitter.emit(:test_event, { data: 123 })

      expect(called).to be true
      expect(payload_received).to eq({ data: 123 })
    end

    it "calls multiple listeners for the same event" do
      count = 0
      emitter.on(:increment) { count += 1 }
      emitter.on(:increment) { count += 2 }

      emitter.emit(:increment)

      expect(count).to eq(3)
    end

    it "calls catch-all (:all) listeners for any event" do
      called_events = []
      emitter.on(:all) do |event, payload|
        called_events << event
      end

      emitter.emit(:event_one, 1)
      emitter.emit(:event_two, 2)

      expect(called_events).to include(:event_one, :event_two)
    end

    it "handles blocks with varying arities safely" do
      results = []
      emitter.on(:arity_test) { results << :no_args }
      emitter.on(:arity_test) { |payload| results << payload }
      emitter.on(:arity_test) { |event, payload| results << [event, payload] }

      emitter.emit(:arity_test, "hello")

      expect(results).to eq([
        :no_args,
        "hello",
        [:arity_test, "hello"]
      ])
    end

    it "rescues errors in callbacks without breaking emission" do
      results = []
      emitter.on(:error_test) { raise "Callback error" }
      emitter.on(:error_test) { results << :success }

      expect { emitter.emit(:error_test) }.not_to raise_error
      expect(results).to eq([:success])
    end
  end
end

RSpec.describe Descartes::Agent::Base do
  let(:agent) { described_class.new(name: "test_agent") }
  let(:context) { double("Context", snapshot: {}) }
  let(:job_description) { "Test job" }
  let(:llm_response) { double("Response", content: nil, tool_calls: [], has_tool_calls?: false) }

  before do
    allow(agent.llm).to receive(:call_with_system).and_return(llm_response)
    # Stub message queue to avoid side effects
    allow_any_instance_of(Descartes::Agent::MessageQueue).to receive(:add)
    allow_any_instance_of(Descartes::Agent::MessageQueue).to receive(:evict!)
    allow_any_instance_of(Descartes::Agent::MessageQueue).to receive(:heartbeat_check!)
    allow_any_instance_of(Descartes::Agent::MessageQueue).to receive(:seed_prompt)
    allow_any_instance_of(Descartes::Agent::MessageQueue).to receive(:to_llm_payload).and_return([])
  end

  describe "EventEmitter hooks" do
    it "emits :thought when the LLM generates text" do
      allow(llm_response).to receive(:content).and_return("I am thinking.")
      allow(llm_response).to receive(:has_tool_calls?).and_return(true) # to avoid tool prompt loop

      # Mock a tool call to yield and break loop
      tool_call = { function: { name: "test_tool", arguments: "{}" } }
      allow(llm_response).to receive(:tool_calls).and_return([tool_call])

      tool_class = double("ToolClass", tool_name: "test_tool", yields_control?: true, to_llm_schema: {})
      tool_instance = double("ToolInstance")
      allow(tool_class).to receive(:new).and_return(tool_instance)
      allow(tool_instance).to receive(:execute).and_return("result")
      agent.instance_variable_set(:@tools, [tool_class])

      thought_received = nil
      agent.on(:thought) { |payload| thought_received = payload }

      agent.execute(context, job_description)

      expect(thought_received).to eq("I am thinking.")
    end

    it "emits :tool_call_start and :tool_call_end when dispatching a tool" do
      tool_call = { function: { name: "my_tool", arguments: '{"arg": 1}' } }
      allow(llm_response).to receive(:has_tool_calls?).and_return(true)
      allow(llm_response).to receive(:tool_calls).and_return([tool_call])

      tool_class = double("ToolClass", tool_name: "my_tool", yields_control?: true, to_llm_schema: {})
      tool_instance = double("ToolInstance")
      allow(tool_class).to receive(:new).and_return(tool_instance)
      allow(tool_instance).to receive(:execute).and_return("tool_done")
      agent.instance_variable_set(:@tools, [tool_class])

      tool_starts = []
      tool_ends = []

      agent.on(:tool_call_start) { |payload| tool_starts << payload }
      agent.on(:tool_call_end) { |payload| tool_ends << payload }

      agent.execute(context, job_description)

      expect(tool_starts.first).to eq({ tool: "my_tool", arguments: '{"arg": 1}' })
      expect(tool_ends.first).to eq({ tool: "my_tool", result: "tool_done" })
    end

    it "emits :finished when the agent explicitly yields control" do
      tool_call = { function: { name: "yield_tool", arguments: "{}" } }
      allow(llm_response).to receive(:has_tool_calls?).and_return(true)
      allow(llm_response).to receive(:tool_calls).and_return([tool_call])

      tool_class = double("ToolClass", tool_name: "yield_tool", yields_control?: true, to_llm_schema: {})
      tool_instance = double("ToolInstance")
      allow(tool_class).to receive(:new).and_return(tool_instance)
      allow(tool_instance).to receive(:execute).and_return("final_answer")
      agent.instance_variable_set(:@tools, [tool_class])

      finished_result = nil
      agent.on(:finished) { |payload| finished_result = payload }

      result = agent.execute(context, job_description)

      expect(result).to eq("final_answer")
      expect(finished_result).to eq("final_answer")
    end

    it "emits :error when maximum turns are exceeded" do
      # Make agent loop indefinitely to hit max turns
      allow(llm_response).to receive(:has_tool_calls?).and_return(false)

      error_emitted = nil
      agent.on(:error) { |payload| error_emitted = payload }

      result = agent.execute(context, job_description, run_max_turns: 1)

      expect(result).to include("exceeded maximum allowed reasoning turns")
      expect(error_emitted).to include("exceeded maximum allowed reasoning turns")
    end

    it "emits :error when a fatal API error occurs" do
      allow(agent.llm).to receive(:call_with_system).and_raise(StandardError.new("Unauthorized"))

      # Mock the status method on the error
      error_class = Class.new(StandardError) do
        def status; 401; end
      end
      allow(agent.llm).to receive(:call_with_system).and_raise(error_class.new("Unauthorized"))

      error_emitted = nil
      agent.on(:error) { |payload| error_emitted = payload }

      result = agent.execute(context, job_description)

      expect(result).to include("Fatal LLM API Failure (401)")
      expect(error_emitted).to include("Fatal LLM API Failure (401)")
    end
  end
end
