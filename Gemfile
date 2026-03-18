# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in descartes.gemspec
gemspec

if ENV["CI"]
  gem "ruby_llm", github: "catclever/ruby_llm"
  gem "llm_json", github: "catclever/llm_json"
else
  gem "ruby_llm", path: "../ruby_llm"
  gem "llm_json", path: "../llm_json"
end

gem "irb"
gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"
