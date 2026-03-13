# frozen_string_literal: true

require_relative "descartes/version"
require_relative "descartes/body"
require_relative "descartes/soul"
require_relative "descartes/sandbox/executor"
require_relative "descartes/tool_registry"

# Pre-load all tools in the standard directory structure
Descartes::ToolRegistry.load_all!

module Descartes
  class Error < StandardError; end
  # The core module exposing Engine.build for DSL
end
