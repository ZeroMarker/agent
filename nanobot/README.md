# Nanobot

超轻量级个人 AI 助手，支持 QQ/Telegram/Discord/WeChat/Slack 等多频道。

- GitHub: https://github.com/HKUDS/nanobot
- 文档: https://nanobot.wiki
- 版本: v0.2.1
- Stars: 44k+
- 语言: Python

## 核心特性

- **多频道支持**：QQ、Telegram、Discord、WeChat、Slack、Email、飞书等
- **多模型支持**：DeepSeek、OpenAI、Anthropic、Gemini、Moonshot 等 30+ 提供者
- **工具系统**：文件操作、Shell 执行、Web 搜索/抓取、定时任务等
- **WebUI**：内置浏览器界面
- **MCP 支持**：Model Context Protocol 服务器
- **记忆系统**：自动保存对话上下文
- **Dream 模式**：定期整理记忆

## 文档目录

- [快速开始](quick-start.md) - 安装与配置
- [命令参考](commands.md) - 所有 CLI 命令
- [配置指南](config.md) - config.json 配置详解
- [频道配置](channels.md) - QQ/Telegram/Discord 等频道设置
- [故障排查](troubleshooting.md) - 常见问题与解决方案

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/HKUDS/nanobot/main/scripts/install.sh | sh
```

## 快速开始

```bash
# 1. 初始化配置
nanobot onboard

# 2. 编辑配置（填入 API Key、频道信息）
vi ~/.nanobot/config.json

# 3. 启动网关（包含所有频道）
nanobot gateway -c ~/.nanobot/config.json
```

## 配置文件位置

- 配置：`~/.nanobot/config.json`
- 工作空间：`~/.nanobot/workspace`
- 记忆：`~/.nanobot/memory/
- 日志：`~/.nanobot/nanobot.log`
