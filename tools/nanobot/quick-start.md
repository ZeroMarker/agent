# 快速开始

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/HKUDS/nanobot/main/scripts/install.sh | sh
```

脚本会通过 `uv tool` 安装 `nanobot-ai`（PyPI 包），可执行文件位于 `~/.local/bin/nanobot`。安装完成后需要将 `~/.local/bin` 加入 PATH：

```bash
export PATH=$PATH:~/.local/bin
```

本机（2026-08-18，aarch64）安装结果：`🐈 nanobot v0.3.0`（PyPI 包 `nanobot-ai`）。

## 当前环境（本机部署）

| 项目 | 值 |
| --- | --- |
| 版本 | v0.3.0（PyPI 包 `nanobot-ai`，uv tool 安装） |
| 可执行文件 | `~/.local/bin/nanobot` |
| 配置 | `~/.nanobot/config.json` |
| 工作空间 | `~/.nanobot/workspace`（Git 存储，含 SOUL.md/AGENTS.md/USER.md/HEARTBEAT.md） |
| 模型提供者 | `openai_codex`（ChatGPT 账号 OAuth，自动读取 `~/.codex/auth.json`，无需 API Key） |
| 模型 | `openai-codex/gpt-5.6-sol`（预设 `codex-oauth`，`reasoningEffort: high`） |
| 备用方案 | `codex-luna` 预设（OpenAI API，`gpt-5.6-luna`，需余额）；`opencodeGo`（DeepSeek V4，复用 pi 密钥） |
| 网关 | systemd 服务 `nanobot.service`，`http://127.0.0.1:18791`（health：`/health`） |
| WebSocket 频道 | `ws://127.0.0.1:8765/` |

## 初始化

```bash
nanobot onboard
```

这会创建：
- `~/.nanobot/config.json` — 主配置文件
- `~/.nanobot/workspace/` — 工作空间（v0.3.0 起为 Git 存储）
  - `SOUL.md` — AI 人格设定
  - `AGENTS.md` — Agent 配置
  - `USER.md` — 用户信息
  - `HEARTBEAT.md` — 定时任务
  - `memory/` `prompts/` `skills/` — 记忆、提示词与技能目录

## 配置

编辑 `~/.nanobot/config.json`：

### 1. 设置模型提供者

```json
{
  "providers": {
    "deepseek": {
      "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

### 2. 设置默认模型

```json
{
  "agents": {
    "defaults": {
      "model": "deepseek-v4-flash",
      "provider": "deepseek",
      "temperature": 0.7
    }
  }
}
```

### 3. 配置 QQ 频道

```json
{
  "channels": {
    "qq": {
      "enabled": true,
      "appId": "your-app-id",
      "secret": "your-app-secret",
      "allowFrom": ["*"]
    }
  }
}
```

### 4. 配置其他频道

参考 [频道配置](channels.md)。

## 启动

### 启动网关（包含所有频道）

```bash
nanobot gateway --foreground -c ~/.nanobot/config.json
```

后台管理：

```bash
nanobot gateway status    # 查看后台网关状态
nanobot gateway logs      # 查看后台网关日志
nanobot gateway stop      # 停止
nanobot gateway restart   # 重启
nanobot gateway install-service   # 安装 systemd 用户服务
```

### 生产环境：systemd 托管（推荐）

本机以系统级 systemd 服务托管网关，支持内存限制与崩溃自动重启：

```bash
sudo systemctl start nanobot         # 启动
sudo systemctl enable nanobot        # 开机自启
sudo systemctl status nanobot        # 查看状态
journalctl -u nanobot -f             # 实时日志
```

Health check：`curl http://127.0.0.1:18791/health`

本机服务配置见 `/etc/systemd/system/nanobot.service`，以 `ubuntu` 用户运行 `nanobot gateway --foreground`，含 `MemoryHigh=2G / MemoryMax=3G` 与 `Restart=always`。低内存机器（1.6GB）调优方案见 [optimization-strategy.md](optimization-strategy.md)。

### 直接对话测试

```bash
nanobot agent -m "你好" --no-markdown -c ~/.nanobot/config.json
```

> 注：v0.3.0 中若模型返回 reasoning 流，CLI 退出时可能打印 httpcore 的 `generator didn't stop after athrow()` 无害告警，不影响输出与退出码。

## 验证

```bash
nanobot status                                # 状态（含各 provider 配置情况）
nanobot agent -m "你好" --no-markdown          # 直接对话测试
nanobot channels status                        # 查看频道状态
curl http://127.0.0.1:18791/health             # 网关健康检查
```

## 下一步

- [命令参考](commands.md) - 所有 CLI 命令
- [配置指南](config.md) - 完整配置说明
- [频道配置](channels.md) - 更多频道设置
- [故障排查](troubleshooting.md) - 常见问题
