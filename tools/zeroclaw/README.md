# ZeroClaw

最快的 AI 助手。基于 Rust 编写，支持多频道、多模型、自主运行。

## 核心特性

- **多频道支持**：QQ、DingTalk、Telegram、Discord、Slack、WeChat(企业微信) 等
- **多模型支持**：DeepSeek、OpenAI、Anthropic、Google 等
- **自主运行**：daemon 模式 + cron 调度 + 心跳监控
- **安全沙箱**：命令白名单、路径限制、操作审批
- **记忆系统**：SQLite/向量存储，自动保存对话上下文

## 安装

```bash
# 预编译版（不含 DingTalk/QQ 等频道）
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash

# 源码编译版（全频道）
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash -s -- --source --preset full
```

## 快速开始

```bash
# 1. 初始化配置
zeroclaw quickstart

# 2. 注册为系统服务
zeroclaw service install

# 3. 启动服务
zeroclaw service start

# 4. 查看状态
zeroclaw status
```

## 文档目录

- [命令参考](commands.md) - 所有 CLI 命令
- [配置指南](config.md) - config.toml 配置详解
- [频道配置](channels.md) - QQ/DingTalk/Telegram 等频道设置
- [安全与权限](security.md) - 权限控制、沙箱、审批
- [故障排查](troubleshooting.md) - 常见问题与解决方案

## 项目信息

- 版本：v0.8.1
- 仓库：https://github.com/zeroclaw-labs/zeroclaw
- 配置文件：`~/.zeroclaw/config.toml`
- 数据目录：`~/.zeroclaw/`
