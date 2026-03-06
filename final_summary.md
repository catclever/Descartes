# Amber Repository Summary

Amber is a Ruby gem project by Kael.Cai. It appears to be an LLM orchestration and agent framework.

## Repository Structure

### Root Files
- Configuration: Gemfile, Gemfile.lock, Rakefile, amber.gemspec
- Documentation: README.md, CHANGELOG.md, CODE_OF_CONDUCT.md, LICENSE.txt
- Project files: llm.yml, notification files

### Directories
- bin/ - Executables
- examples/ - Examples
- lib/ - Main library (18 Ruby files)
- sig/ - Type signatures
- spec/ - Tests

## Key Components

### Core
- amber.rb - Main entry
- context.rb - Context management
- engine.rb - Core orchestration
- tool_registry.rb - Tool management

### Agent System
- agent/base.rb - Base agent
- agent/message_queue.rb - Messaging
- agent/working_note.rb - Working notes

### Engine
- engine/planner.rb - Job planning
- engine/evaluator.rb - Job evaluation

### Orchestration
- orchestration/job.rb - Job management
- sandbox/executor.rb - Safe execution

### Tools
- tools/base_tool.rb - Tool base
- tools/builtin/ - Code executor, job spawner
- tools/default/ - Inner thought, send message, write notes

## Requirements
- Ruby >= 3.2.0
- ruby_llm gem

## Status
Active development of LLM agent orchestration framework.
