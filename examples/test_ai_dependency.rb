require_relative '../lib/amber'

puts "Testing Semantic AI Dependencies..."

engine = Amber::Engine.build do
  environment user_input: "Hi, I need my email address verified.",
              user_account: { email: 'test@example.com', verified: false }

  # Define an agent to handle the job once AI dependency triggers it
  agent :verification_bot, profile_name: 'openai', system_prompt: "You verify accounts."

  job :process_verification do
    # AI condition evaluating the context
    depends_on_ai "Has the user asked to verify their email?"

    action "Handle verification process"
    executed_by_agent :verification_bot
  end
end

puts "\nExecuting Amber Engine with Semantic Evaluation..."
engine.run!
puts "\nDone!"
