# Descartes

[![Ruby](https://img.shields.io/badge/Language-Ruby-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-0.2.0-green.svg)](lib/descartes/version.rb)

**A modern Ruby framework for reactive and distributed LLM Agent workflows.**

> *"Cogito, ergo sum." (I think, therefore I am.) — René Descartes*
> 
> Descartes decouples an AI Agent's "Soul" from its "Body": **Centralized reasoning in the cloud, secure native tool execution at the edge.**

---

## 📖 Documentation

- [English Version (Current)](README.md)
- [中文版本 (Chinese Version)](README.zh-CN.md)

---

## 🌟 Key Features (v0.2.0 Release)

### 1. 🚀 Descartes Hub (Distributed Agent Orchestration)
In traditional agent architectures, placing private credentials, production database credentials, or local shell permissions inside cloud containers introduces major security and networking challenges. Descartes Hub solves this with the **"Soul in Cloud, Body at Edge"** model:
- **The Cloud Brain (Soul)**: The Hub runs centrally in the cloud or server environment (powered by Puma + Faye WebSocket). It manages LLM reasoning, conversation state machines, and the ReAct execution loop.
- **The Edge Body (Body)**: Client applications (developer laptops, edge devices, on-prem servers) connect to the Hub over standard WebSockets and dynamically register local private tools (e.g., executing shell commands, reading local files, querying private databases).
- **Zero-Trust Security**: The cloud never needs direct access to your local private environment or credentials. It simply issues JSON-RPC tool call requests; your client executes them locally and returns only the final output to the cloud.

```text
+-------------------------------------------------------------------------+
|                        Descartes Hub (Cloud Brain)                      |
|                                                                         |
|  [LLM Service] <---> [Agent Base] <---> [Dynamic Remote Tool Proxy]     |
|   (DeepSeek/Kimi/GLM)   (ReAct Loop)       (Thread-safe Queue sync)     |
+-------------------------------------------------------------------------+
                                    ▲
                                    │ Bidirectional WebSocket Protocol
                                    ▼
+-------------------------------------------------------------------------+
|                       Edge Client (Local Environment)                   |
|                                                                         |
|  - Declare local tools: Local File, Git, Terminal, Private DB           |
|  - Receive real-time: Thought streaming, Tool Call requests             |
|  - Execute tool locally & reply: {"type": "tool_result", "output": ...} |
+-------------------------------------------------------------------------+
```

### 2. 🔌 Dynamic Remote Tool Proxy (`DynamicRemoteTool`)
When a client connects and sends tool definitions (standard JSON Schema), the Hub dynamically creates native `Descartes::Tool::Base` subclasses:
- **Thread-Safe Synchronization**: Uses a thread-safe Queue to suspend the agent loop when a tool call is dispatched and immediately resumes when the client returns the tool output.
- **Timeout Protection**: Safeguards against client disconnections or hung processes with configurable timeouts.

### 3. 📡 Full Real-Time Lifecycle Streaming (`EventEmitter`)
Built-in pub/sub event hooks give you complete visibility into the agent's execution:
- `:thought`: Real-time streaming thoughts and reasoning text from the LLM.
- `:tool_call_start` & `:tool_call_end`: Dispatched tool arguments and completed tool results.
- `:finished` & `:error`: Agent task resolution or unrecoverable error events.

### 4. 🧠 Autonomous Agent Foundation (`Descartes::Agent::Base`)
Descartes is also a complete standalone agent framework:
- **Sliding-Window Message Queue**: Automatically compacts and summarizes conversation history to avoid exceeding token limits.
- **Token Monitor**: Precisely tracks token consumption and iteration turns.
- **Type-safe Tool Registry**: Easily register and manage native tools by subclassing `Descartes::Tool::Base`.

---

## 🛠️ Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'descartes', github: 'catclever/descartes'
```

And then execute:
```bash
bundle install
```

---

## 🚀 Running & Deploying Descartes Hub

### Option 1: Standalone CLI
Use the built-in CLI executable:
```bash
# Default is 0.0.0.0:8080
bundle exec bin/descartes-hub --port 8089 --host 0.0.0.0
```

### Option 2: Docker Container
Build directly from GitHub source:
```bash
docker build -t descartes-hub https://github.com/catclever/Descartes.git#main
docker run -d -p 8089:8089 -v $(pwd)/llm.yml:/app/llm.yml:ro descartes-hub
```

### Option 3: Dockge / Docker Compose
Deploy as a stack in Dockge or Docker Compose with `compose.yaml`:
```yaml
services:
  descartes-hub:
    image: descartes-hub:latest
    build:
      context: https://github.com/catclever/Descartes.git#main
    container_name: descartes-hub
    restart: unless-stopped
    ports:
      - "8089:8089"
    environment:
      - PORT=8089
      - HOST=0.0.0.0
      - DEFAULT_LLM_PROFILE=default # Switch active model profile effortlessly
    volumes:
      - ./config/llm.yml:/app/llm.yml:ro
```

---

## ⚙️ Model Configuration (`llm.yml`)

Descartes supports multiple model profiles and automatic fallbacks:

```yaml
# 1. Default model profile (OpenAI-compatible, DeepSeek, Kimi, GLM, etc.)
default:
  format: "openai"
  base_url: "http://172.16.51.7:48787/v1"
  model: "deepseek-v4.1-flash"
  api_key: "your-api-key"
  max_tokens: 8192
  timeout: 120

# 2. Alternative profiles
kimi:
  format: "openai"
  base_url: "https://api.moonshot.cn/v1"
  model: "kimi-k2.6"
  api_key: "sk-..."
  max_tokens: 8192
  timeout: 120

glm:
  format: "openai"
  base_url: "https://open.bigmodel.cn/api/coding/paas/v4"
  model: "glm-4.7"
  api_key: "..."
  temperature: 0.95
```

> **Note**: You can specify `DEFAULT_LLM_PROFILE` in your environment (e.g. `DEFAULT_LLM_PROFILE=kimi`) to switch models globally without touching client code.

---

## 💻 Client Quickstart (Distributed Execution)

Connect from Ruby (or any language with a WebSocket library):

```ruby
require 'faye/websocket'
require 'eventmachine'
require 'json'

EM.run do
  ws = Faye::WebSocket::Client.new('ws://localhost:8089/')

  ws.on :open do
    # 1. Send init handshake with local tool definitions
    ws.send({
      type: "init",
      task_name: "calculator_job",
      prompt: "Please calculate the sum of 123 and 456 using your tool.",
      tools: [
        {
          name: "add_numbers",
          description: "Adds two integers together on the client machine.",
          parameters: {
            type: "object",
            properties: {
              a: { type: "integer", description: "First integer" },
              b: { type: "integer", description: "Second integer" }
            },
            required: ["a", "b"]
          }
        }
      ]
    }.to_json)
  end

  ws.on :message do |event|
    msg = JSON.parse(event.data)
    case msg["type"]
    when "stream_event"
      puts "[Thought] #{msg['data']}" if msg["event"] == "thought"
    when "execute_tool"
      # 2. Hub asks client to execute tool locally
      call_id = msg["call_id"]
      args = msg["arguments"]
      result = args["a"] + args["b"]
      
      ws.send({
        type: "tool_result",
        call_id: call_id,
        status: "ok",
        output: result.to_s
      }.to_json)
    when "finished"
      puts "🎉 Completed: #{msg['result']}"
      EM.stop
    end
  end
end
```

---

## 📋 Test Suite

All features are covered by comprehensive RSpec unit tests:

```bash
bundle exec rspec
```

---

## 📄 License

Descartes is open-source software licensed under the [MIT License](LICENSE.txt). Free for commercial and private use.
