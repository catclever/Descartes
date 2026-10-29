# Descartes (笛卡尔)

[![Ruby](https://img.shields.io/badge/Language-Ruby-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-0.2.0-green.svg)](lib/descartes/version.rb)

**用于构建响应式与分布式 LLM Agent 的现代 Ruby 框架。**

> *"Cogito, ergo sum."（我思故我在）—— 勒内·笛卡尔*
> 
> Descartes 的核心哲学是将 Agent 的“思维（Soul）”与“躯体（Body）”解耦：**云端大脑集中思考，端侧四肢本地执行**。

---

## 📖 文档导航 / Documentation

- [中文版本 (当前)](README.zh-CN.md)
- [English Version](README.md)

---

## 🌟 核心特性 (v0.2.0 重磅发布)

### 1. 🚀 Descartes Hub（分布式 Agent 通信中枢）
在传统的 Agent 架构中，将私有凭证、本地文件系统访问权或内网数据库访问放到云端容器存在巨大的安全和网络穿透风险。Descartes Hub 创新地提出了 **“云端大脑，端侧四肢”（Soul in Cloud, Body at Edge）** 架构：
- **云端大脑 (Soul)**：Hub 运行在云端或服务器中（基于高性能 Puma + Faye WebSocket），负责统一维护大模型连接、会话状态流转与 ReAct 决策循环。
- **端侧四肢 (Body)**：端侧客户端（开发者笔记本、本地边缘设备、内网服务器）通过标准 WebSocket 连入 Hub，并动态向云端注册本地私有工具（如执行本地 Shell、读取本地代码库、查询私有 MySQL）。
- **零泄露安全架构**：云端无需感知本地真实环境，只下发工具调用指令；客户端在本地安全沙盒执行完后仅回传结果给云端继续推理。

```text
+-------------------------------------------------------------------------+
|                         Descartes Hub (云端大脑)                         |
|                                                                         |
|  [LLM Service] <---> [Agent Base] <---> [Dynamic Remote Tool Proxy]     |
|     (DeepSeek/Kimi/GLM)   (ReAct Loop)       (线程安全阻塞队列)           |
+-------------------------------------------------------------------------+
                                    ▲
                                    │ WebSocket (双向实时通信协议)
                                    ▼
+-------------------------------------------------------------------------+
|                        Edge Client (端侧四肢/本地环境)                     |
|                                                                         |
|  - 声明本地工具: Local File/Git/Terminal/Private DB                       |
|  - 实时接收: Thought 思考流、Tool Call 指令                               |
|  - 本地执行工具并回传结果: {"type": "tool_result", "output": ...}          |
+-------------------------------------------------------------------------+
```

### 2. 🔌 动态远程工具代理 (`DynamicRemoteTool`)
客户端在握手阶段提交标准 JSON Schema 工具定义，Hub 会自动通过元编程动态派生对应的 `Descartes::Tool::Base` 本地代理类。
- **线程安全同步**：内置 Thread Queue 阻塞唤醒机制，云端 LLM 发起工具调用时挂起对应会话，客户端回传结果后瞬间唤醒。
- **超时保护熔断**：提供可配置的工具超时看门狗，防止端侧掉线或阻塞导致云端会话僵死。

### 3. 📡 全链路实时事件流 (`EventEmitter`)
基于 Pub/Sub 机制，Agent 运行时生命周期完全透明可观测：
- `:thought`：大模型实时流式思考与推理文本。
- `:tool_call_start` 与 `:tool_call_end`：工具调用的参数与执行结果。
- `:finished` 与 `:error`：任务完成交付与异常捕获。

### 4. 🧠 强大的单机/独立 Agent 编排能力
即使不使用 Hub，Descartes 也是一个完备的本地 Agent 框架：
- **滑动窗口消息队列**：自动进行上下文窗口压缩与历史总结，告别超长上下文溢出。
- **Token 监控机制**：精准追踪输入、输出 Token 消耗及调用轮次。
- **统一工具注册表**：通过继承 `Descartes::Tool::Base` 几行代码即可定义强类型工具。

---

## 🛠️ 快速安装

在项目的 `Gemfile` 中引入：

```ruby
gem 'descartes', github: 'catclever/descartes'
```

然后执行：
```bash
bundle install
```

---

## 🚀 启动与部署 Descartes Hub

### 方式 1：CLI 直接启动
安装 Gem 后，可以直接使用自带的 CLI 启动 Hub 服务：
```bash
# 默认监听 0.0.0.0:8080，支持指定端口与宿主
bundle exec bin/descartes-hub --port 8089 --host 0.0.0.0
```

### 方式 2：Docker 容器化部署
Descartes 提供官方优化的 Dockerfile，支持基于 GitHub 源码直接构建：
```bash
docker build -t descartes-hub https://github.com/catclever/Descartes.git#main
docker run -d -p 8089:8089 -v $(pwd)/llm.yml:/app/llm.yml:ro descartes-hub
```

### 方式 3：Dockge / Docker Compose
在 Dockge 中创建 Stack，使用标准 `compose.yaml`：
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
      - DEFAULT_LLM_PROFILE=default # 灵活指定默认使用的模型 profile
    volumes:
      - ./config/llm.yml:/app/llm.yml:ro
```

---

## ⚙️ 模型配置指南 (`llm.yml`)

Descartes 原生支持多模型 Profile 与自动回退。在 `llm.yml`（或 `config/llm.yml`）中配置：

```yaml
# 1. 默认模型（支持 DeepSeek / Kimi / GLM 等兼容 OpenAI 格式的服务）
default:
  format: "openai"
  base_url: "http://172.16.51.7:48787/v1"
  model: "deepseek-v4.1-flash"
  api_key: "your-api-key"
  max_tokens: 8192
  timeout: 120

# 2. 备用模型配置
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

> **提示**：可以通过环境变量 `DEFAULT_LLM_PROFILE` 指定默认使用的 profile（如 `kimi` 或 `default`），客户端未传 profile 时将自动平滑回退。

---

## 💻 客户端接入示例（分布式调用）

客户端可以是任何语言（Ruby、Python、Node.js、Go 等），只需连接 WebSocket：

```ruby
require 'faye/websocket'
require 'eventmachine'
require 'json'

EM.run do
  ws = Faye::WebSocket::Client.new('ws://localhost:8089/')

  ws.on :open do
    # 1. 发送 init 握手并向云端注册本地私有工具
    ws.send({
      type: "init",
      task_name: "calculator_job",
      prompt: "请计算 123 与 456 的和",
      tools: [
        {
          name: "add_numbers",
          description: "在客户端本地执行两个数的相加",
          parameters: {
            type: "object",
            properties: {
              a: { type: "integer", description: "加数" },
              b: { type: "integer", description: "被加数" }
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
      puts "[Thought 流] #{msg['data']}" if msg["event"] == "thought"
    when "execute_tool"
      # 2. 云端要求端侧执行工具，端侧本地执行并回传
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
      puts "🎉 任务圆满完成: #{msg['result']}"
      EM.stop
    end
  end
end
```

---

## 📋 单元测试与质量保证

Descartes 拥有 100% 的 RSpec 测试覆盖，确保核心逻辑的稳定性：

```bash
bundle exec rspec
```

---

## 📄 开源许可

本项目采用 [MIT License](LICENSE.txt) 许可证。完全支持免费商业使用、修改与二次分发。
