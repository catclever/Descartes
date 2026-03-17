# Descartes

[![Ruby](https://img.shields.io/badge/Language-Ruby-red.svg)](https://www.ruby-lang.org/)

**A Ruby framework for reactive LLM agent workflows.**

Descartes provides a tool and agent proxy framework to orchestrate LLM workflows. It is designed to seamlessly orchestrate Large Language Models (LLMs) with local tools and sandbox environments, enabling autonomous agents to reason, generate code, and execute actions.

---

## 📖 Documentation / 文档

- [English Version](README.md)
- [中文版本](README.zh-CN.md)

---
## English Version

### Features
- **Agent Orchestration**: Built-in support for deploying LLMs as reasoning engines (Souls) and executing actions (Bodies).
- **Tool Registry**: Easily register and load customized tools that allow agents to interact with local systems and external APIs.
- **Sandbox Execution**: Secure subprocess execution of agent-generated code with resource limits.
- **Seamless LLM Integration**: Tightly integrated with `ruby_llm` to interact with providers like OpenAI, Anthropic, and Gemini.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'descartes', github: 'catclever/descartes'
```

And then execute:
```bash
$ bundle install
```

### Usage

```ruby
require 'descartes'

# Detailed usage instructions and architecture to be supplemented based on your SPSS workflows.
```

### License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). It fully supports commercial use.
