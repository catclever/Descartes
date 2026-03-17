# Descartes

[![Ruby](https://img.shields.io/badge/Language-Ruby-red.svg)](https://www.ruby-lang.org/)

**一个用于构建响应式 LLM Agent 工作流的 Ruby 框架。**

Descartes 提供了一套工具和 Agent 代理框架，用于编排大模型 (LLM) 工作流。它的核心定位是协调大语言模型与本地工具、沙盒环境的执行，使自治 Agent 能够进行推理、生成代码并执行实际动作。

---

## 📖 Documentation / 文档

- [English Version](README.md)
- [中文版本](README.zh-CN.md)

---

### 主要特性
- **Agent 编排**: 内置支持将大模型部署为推理引擎 (Soul)，并将决策转化为实际执行的动作 (Body)。
- **工具注册表**: 可以轻松注册和统一管理各种工具，允许 Agent 与底层系统环境及 API 进行交互。
- **沙盒执行**: 在带有资源限制的子进程中安全地执行 Agent 生成的代码。
- **无缝 LLM 集成**: 与 `ruby_llm` 深度集成，能够无缝对接 OpenAI、Anthropic、Gemini 等各大服务商。

### 安装

在项目的 Gemfile 中添加：

```ruby
gem 'descartes', github: 'catclever/descartes'
```

然后执行：
```bash
$ bundle install
```

### 使用指南

```ruby
require 'descartes'

# 具体的 SPSS 工作流体系结构与编排代码示例待补充。
```

### 商业使用与开源协议

本项目基于 [MIT License](https://opensource.org/licenses/MIT) 开源。**完全支持免费商业使用**、修改和分发。
