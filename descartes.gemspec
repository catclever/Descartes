# frozen_string_literal: true

require_relative "lib/descartes/version"

Gem::Specification.new do |spec|
  spec.name = "descartes"
  spec.version = Descartes::VERSION
  spec.authors = ["Kael.Cai"]
  spec.email = ["saint.archangel.satan@gmail.com"]

  spec.summary = "A Ruby framework for reactive LLM agent workflows."
  spec.description = "Descartes provides a tool and agent proxy framework to orchestrate LLM workflows and sandbox code execution."
  spec.homepage = "https://github.com/catclever/descartes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/catclever/descartes"
  spec.metadata["changelog_uri"] = "https://github.com/catclever/descartes/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency "ruby_llm"
  spec.add_dependency "llm_json"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
