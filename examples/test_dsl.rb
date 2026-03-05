require_relative '../lib/amber'

puts "Building Amber Engine DSL..."

engine = Amber::Engine.build do
  environment user_id: 123, status: 'started'

  job :parse_input do
    action "Read input from user"
    executed_by do |ctx|
      puts "--> [Job: parse_input] Running! Reading user ID: #{ctx.get(:user_id)}"
      ctx.set(:input_received, true)
      "Input Parsed Return Value"
    end
  end

  job :generate_response do
    depends_on :parse_input
    
    action "Generate AI response based on input"
    executed_by do |ctx|
      puts "--> [Job: generate_response] Running! Input Received flag is: #{ctx.get(:input_received)}"
      ctx.set(:response_ready, true)
    end
  end

  job :dynamic_delivery do
    depends_on :generate_response
    action "Deliver the response back to the user channel"
    # No `executed_by` block provided intentionally to test the 'Undefined Agent' fallback
  end
end

puts "\nExecuting Amber Engine..."
engine.run!
puts "\nDone!"
