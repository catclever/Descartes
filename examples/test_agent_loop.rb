# frozen_string_literal: true

require_relative "../lib/descartes"

puts "Building Descartes Agent Body & Soul DSL..."

body = Descartes::Body.define :analyzer_squad do
  config do
    profile :glm, provider: :glm, model: "glm-5"
  end

  roster do
    agent :analyzer, profile: :glm, system_prompt: "You are a String analysis AI."
  end
end

soul = Descartes::Soul.define :string_analysis do
  inject_context prompt: "Can you analyze this string 'Hello World' and reverse it?"

  job :request_analysis do
    description "Pass the user's string to the Agent to analyze and reverse it."

    # Needs to ensure the prompt is loaded into memory
    depends_on { |ctx| !ctx.get(:prompt).nil? }

    # Assign predefined agent execution
    assignee :analyzer
  end
end

puts "\nExecuting Descartes Body..."
body.animate(soul)
puts "\nDone!"
