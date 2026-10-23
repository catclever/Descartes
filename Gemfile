# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in descartes.gemspec
gemspec

if ENV["CI"] || !Dir.exist?(File.expand_path("../llm_json", __dir__))
  gem "llm_json", github: "catclever/llm_json"
  gem "ruby_llm", github: "catclever/ruby_llm"
else
  gem "llm_json", path: "../llm_json"
  gem "ruby_llm", path: "../ruby_llm"
end

gem "rack"
gem "puma"
gem "faye-websocket"
gem "eventmachine"

gem "irb"
gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"
