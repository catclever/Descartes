# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-29

### 🚀 Major Feature: Descartes Hub (Distributed Agent Architecture)
- **Descartes::Hub::Server & Session**: Added high-concurrency Puma-powered WebSocket Hub server to coordinate distributed agent sessions. Supports "Soul in Cloud, Body at Edge" architecture where the LLM reasoning runs on the cloud Hub and tool execution occurs locally on client machines.
- **Descartes::Tool::DynamicRemoteTool**: Dynamic class factory for proxying client-registered tools into native `Descartes::Tool::Base` instances with thread-safe Queue synchronization and configurable timeout safeguard.
- **Descartes::Hub::Protocol**: Comprehensive protocol specification and parser for bidirectional JSON messages (`init`, `execute_tool`, `tool_result`, `stream_event`, `finished`, `error`).
- **Descartes::EventEmitter**: Added event-driven pub/sub mixin to `Descartes::Agent::Base` emitting real-time agent lifecycle hooks (`:thought`, `:tool_call_start`, `:tool_call_end`, `:finished`, `:error`).
- **Flexible Profile Resolution**: Added `DEFAULT_LLM_PROFILE` environment variable support with automatic fallback to `default` profile in `llm.yml`.
- **Standalone CLI**: Added `bin/descartes-hub` for running the Hub server with customizable host and port options.
- **Containerization & Dockge**: Added official `Dockerfile` and `compose.yaml` with Git-based build context and health check endpoint (`/healthz`).
- **Client Reference**: Added end-to-end WebSocket client example in `examples/hub_test_client.rb`.

## [0.1.0] - 2026-03-05

- Initial release: Core Agent loop, context management, token monitoring, and tool registry.
