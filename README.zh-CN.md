# Descartes (中文文档)

[![Ruby](https://img.shields.io/badge/Language-Ruby-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-0.2.0-green.svg)](lib/descartes/version.rb)

**轻量、响应式的 Ruby LLM Agent 工作流框架与 SDK。**

> *"我思故我在。" (Cogito, ergo sum.) — 勒内·笛卡尔 (René Descartes)*

Descartes 是一个精简且零冗余依赖的 Ruby AI Agent 核心开发库，专注于模型交互、工具调度、会话滑动窗口压缩、Token 监控与生命周期流式事件派发。

> [!NOTE]
> 如果您需要部署分布式 WebSocket 云端大脑服务以协调边缘端执行，请参阅独立的 **[Descartes Hub](../descartes-hub)** (`descartes-hub` gem)。

---

## 🌟 核心特性

### 1. 🧠 自治 Agent 循环 (`Descartes::Agent::Base`)
- **ReAct 循环**：完善的思考-工具调用-结果观察循环，保障多轮推理与任务交付。
- **滑动窗口历史管理**：智能裁剪与压缩历史对话，防止超出模型上下文 Token 窗口。
- **Token 监控**：精确统计 Token 消耗量并提供最大迭代轮次熔断保护。
- **容错恢复**：优雅处理无效工具调用参数、网络重试及最大轮次退出。

### 2. 📡 实时生命周期事件流 (`EventEmitter`)
内置发布/订阅事件钩子，全面掌控 Agent 执行流程：
- `:thought`：大模型实时生成的思考文本流。
- `:tool_call_start`：工具调用启动事件（包含工具名称及入参）。
- `:tool_call_end`：工具执行完毕事件（包含输出结果）。
- `:finished`：任务顺利完成终态。
- `:error`：异常或超时错误事件。

### 3. 🔌 灵活的工具体系 (`Descartes::ToolRegistry`)
- **原生工具**：通过继承 `Descartes::Tool::Base` 便捷定义本地工具。
- **动态远程工具代理**：通过 `Descartes::Tool::DynamicRemoteTool` 代理端侧或远端工具，支持线程安全队列与超时控制。
- **自动注册**：内置标准工具开箱即用。

### 4. 🪶 纯净轻量架构
- 作为纯粹的 SDK，移除重型 Web/WebSocket 服务器依赖（`puma`, `faye-websocket`, `rack` 已独立至 `descartes-hub`）。
- 底层直接基于 `ruby_llm` 与 `llm_json` 构建。

---

## 🛠️ 安装指南

在项目的 `Gemfile` 中添加：

```ruby
gem 'descartes', github: 'catclever/descartes'
```

然后执行：

```bash
bundle install
```

---

## 💻 快速开始

```ruby
require 'descartes'

# 1. 创建 Agent 实例
agent = Descartes::Agent::Base.new(
  name: "assistant_agent",
  profile_name: "default",
  system_prompt: "你是一个乐于助人的 AI 助手。"
)

# 2. 监听事件
agent.on(:thought) do |text|
  puts "[思考] #{text}"
end

agent.on(:finished) do |result|
  puts "🎉 交付: #{result}"
end

# 3. 执行任务
context = Descartes::Context.new(task_name: "demo_job")
result = agent.execute(context, "请简要介绍你自己。")
puts result
```

---

## 🌐 分布式 Hub 服务

若需启动分布式 WebSocket 服务协调端侧设备，请使用独立的 **[Descartes Hub](../descartes-hub)**：

```bash
cd ../descartes-hub
bundle exec bin/descartes-hub --port 8089 --host 0.0.0.0
```

---

## 📋 运行测试

```bash
bundle exec rspec
```

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE.txt) 开源。
