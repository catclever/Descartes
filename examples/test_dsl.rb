require_relative '../lib/descartes'

puts "Building Descartes Body & Soul DSL..."

# 1. Define the reusable Body
body = Descartes::Body.define :basic_runner do
  config do
    profile :default, provider: :openai, model: 'gpt-4o-mini'
  end
end

# 2. Define the specific Soul (Workflow + Context)
soul = Descartes::Soul.define :parsing_flow do
  inject_context user_id: 123, status: 'started'

  job :parse_input do
    description "Read input from user"
    execute do |ctx|
      puts "--> [Job: parse_input] Running! Reading user ID: #{ctx.get(:user_id)}"
      ctx.set(:input_received, true)
      "Input Parsed Return Value"
    end
  end

  job :generate_response do
    depends_on :parse_input
    
    description "Generate AI response based on input"
    execute do |ctx|
      puts "--> [Job: generate_response] Running! Input Received flag is: #{ctx.get(:input_received)}"
      ctx.set(:response_ready, true)
    end
  end

  job :dynamic_delivery do
    depends_on :generate_response
    description "Deliver the response back to the user channel"
    # No `execute` or `assignee` provided intentionally to test fallback
  end
end

puts "\nExecuting Descartes Body.animate..."
body.animate(soul)
puts "\nDone!"
