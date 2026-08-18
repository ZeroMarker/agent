# 配置指南

配置文件位置：`~/.nanobot/config.json`

## Agent 配置

```json
{
  "agents": {
    "defaults": {
      "workspace": "~/.nanobot/workspace",
      "model": "deepseek-v4-flash",
      "provider": "deepseek",
      "temperature": 0.7,
      "maxTokens": 4096,
      "contextWindowTokens": 32768,
      "maxToolIterations": 200,
      "maxMessages": 60,
      "consolidationRatio": 0.3,
      "idleCompactAfterMinutes": 30,
      "botName": "nanobot",
      "botIcon": "🐈",
      "timezone": "UTC",
      "dream": {
        "enabled": true,
        "intervalH": 2
      }
    }
  }
}
```

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `model` | 模型名称 | `anthropic/claude-opus-4-5` |
| `provider` | 提供者 | `auto` |
| `temperature` | 温度 | `0.1` |
| `maxTokens` | 最大输出 token | `4096` |
| `contextWindowTokens` | 上下文窗口大小 | `32768` |
| `maxToolIterations` | 最大工具调用次数 | `200` |
| `maxMessages` | 最大消息数 | `60` |
| `consolidationRatio` | 历史消息压缩比例 | `0.3` |
| `idleCompactAfterMinutes` | 空闲自动压缩间隔（分钟），`0` 关闭 | `0` |
| `botName` | 机器人名称 | `nanobot` |
| `botIcon` | 机器人图标 | `🐈` |
| `timezone` | 时区 | `UTC` |

> 注：2026-08-03 因低内存（1.6GB）机器 OOM，已将 `contextWindowTokens` 65536→32768、`maxMessages` 120→60、`consolidationRatio` 0.5→0.3，并启用 `idleCompactAfterMinutes: 30`。详见 [optimization-strategy.md](optimization-strategy.md)。

## 模型提供者

支持 30+ 提供者（v0.3.0 每个提供者统一为 `apiKey` / `apiBase` / `apiType` / `extraHeaders` 等字段）。

```json
{
  "providers": {
    "deepseek": {
      "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
    },
    "openai": {
      "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
    },
    "anthropic": {
      "apiKey": "sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx"
    },
    "openrouter": {
      "apiKey": "sk-or-xxxxxxxxxxxxxxxxxxxxxxxx"
    },
    "opencodeGo": {
      "apiKey": "<opencode-go key>",
      "apiBase": "https://opencode.ai/zen/go/v1"
    }
  }
}
```

> 本机实际使用 `opencodeGo` 提供者 + `deepseek-v4-flash` 模型，密钥直接复用 pi 的 `~/.pi/agent/auth.json`（`opencode-go` 字段），无需额外注册 API。`apiType` 仅 `auto` / `chat_completions` / `responses` 三选一；其中 `api_type` 字段只有 `providers.openai` 允许显式设置，其余提供者保持 `auto` 即可。

### 支持的提供者

| 提供者 | 说明 |
|--------|------|
| `deepseek` | DeepSeek |
| `openai` | OpenAI |
| `anthropic` | Anthropic |
| `openrouter` | OpenRouter |
| `gemini` | Google Gemini |
| `moonshot` | Moonshot (Kimi) |
| `minimax` | MiniMax |
| `dashscope` | 阿里通义 |
| `zhipu` | 智谱 |
| `siliconflow` | SiliconFlow |
| `volcengine` | 火山引擎 |
| `groq` | Groq |
| `ollama` | 本地 Ollama |
| `vllm` | vLLM |
| 更多... | 见 config.json |

### OAuth 账号授权（免 API Key）

nanobot 支持用 **账号登录（OAuth）** 代替 API Key，直接复用本机其他 CLI 的登录会话：

| 提供者 key | 账号 | 自动读取的会话 | 默认模型 | 调用通道 |
| --- | --- | --- | --- | --- |
| `openai_codex` | ChatGPT 账号 | `~/.codex/auth.json` | `openai-codex/gpt-5.6-sol`（已验证 `gpt-5.6-luna` 也可用） | `chatgpt.com/backend-api/codex/responses` |
| `xai_grok` | xAI 账号 | `~/.grok/auth.json` | 见 status | Grok 专线 |
| `github_copilot` | GitHub 账号 | `~/.copilot` 会话 | 见 status | Copilot 通道 |

`nanobot status` 会以 `✓ (OAuth)` 标记已检测到的会话。无需配置 `apiKey`，`providers.openai_codex` 等留空即可：

```json
{
  "providers": {
    "openai_codex": {
      "apiKey": null,
      "apiBase": null,
      "apiType": "auto"
    }
  }
}
```

切换到 OAuth 模型（采用预设方式）:

```json
{
  "modelPresets": {
    "codex-oauth": {
      "model": "openai-codex/gpt-5.6-sol",
      "provider": "openai_codex",
      "reasoningEffort": "high"
    }
  },
  "agents": {
    "defaults": {
      "modelPreset": "codex-oauth"
    }
  }
}
```

改完执行 `sudo systemctl restart nanobot`。

> **本机现状（2026-08-18）**：默认走 `codex-oauth-luna` 预设（ChatGPT 账号 OAuth，`openai-codex/gpt-5.6-luna`），已验证可正常对话。备用方案：`codex-luna` 预设（`providers.openai` API 密钥，模型 `gpt-5.6-luna`，需 API 余额）与 `opencodeGo`（DeepSeek V4）。
> **注意**：OAuth 会话会过期，过期后需重新在对应 CLI（`codex` / `grok`）或 `nanobot provider login <provider>` 登录。

## 频道配置

详见 [频道配置](channels.md)。

## 工具配置

```json
{
  "tools": {
    "web": {
      "enable": true,
      "search": {
        "provider": "duckduckgo",
        "maxResults": 5,
        "timeout": 30
      },
      "fetch": {
        "useJinaReader": true
      }
    },
    "exec": {
      "enable": true,
      "timeout": 60
    },
    "cliApps": {
      "enable": true,
      "installTimeout": 300,
      "runTimeout": 60
    },
    "restrictToWorkspace": false
  }
}
```

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `web.enable` | 启用 Web 工具 | `true` |
| `web.search.provider` | 搜索引擎 | `duckduckgo` |
| `exec.enable` | 启用 Shell 执行 | `true` |
| `exec.timeout` | Shell 超时 | `60` |
| `cliApps.enable` | 启用 CLI 应用 | `true` |
| `restrictToWorkspace` | 限制在工作空间内 | `false` |

## API 服务器配置

```json
{
  "api": {
    "host": "127.0.0.1",
    "port": 8900,
    "timeout": 120.0
  }
}
```

## 网关配置

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18791,
    "heartbeat": {
      "enabled": true,
      "intervalS": 1800,
      "keepRecentMessages": 8
    }
  }
}
```

> 注：2026-08-03 起网关端口由 `18790` 改为 `18791`，因 `18790` 已被 picoclaw gateway 占用。

## 工作空间文件

工作空间目录：`~/.nanobot/workspace/`

| 文件 | 用途 | 加载时机 |
|------|------|----------|
| `SOUL.md` | AI 人格设定、行为规则、常用命令速查 | 每次对话自动加载 |
| `AGENTS.md` | 项目级指令、工作流约定 | 每次对话自动加载 |
| `USER.md` | 用户信息、偏好 | 每次对话自动加载 |
| `HEARTBEAT.md` | 定时任务清单 | heartbeat cron 触发时加载 |
| `memory/MEMORY.md` | 长期记忆 | 按需加载 |

### SOUL.md 示例

```markdown
# Soul

I am nanobot 🐈, a personal AI assistant.

## Core Principles

- Solve by doing, not by describing what I would do.
- Keep responses short unless depth is asked for.

## 常用命令速查

### tk（TikTok 直播录制）

`tk` 是定义在 `~/scripts/ffmpeg.sh` 的函数。

**正确用法**：
​```bash
source ~/scripts/ffmpeg.sh && tk <tiktok_username>
​```

**注意**：不要用 find_files 搜索 tk 命令，不要扫描 /root/tiktok 目录（会卡死）。
```

### AGENTS.md 示例

```markdown
# Agent Instructions

## 工作流约定

- 使用 `apply_patch` 更新任务列表
- 使用 `edit_file` 做小范围精确替换
- 使用 `write_file` 创建或重写整个文件

## 常用命令

### tk（TikTok 直播录制）
...
```

### 关键提示

- **SOUL.md 优先级最高**：放最重要的规则和命令速查
- **避免大目录扫描**：在 SOUL.md 中明确禁止扫描已知大目录（如 `/root/tiktok`）
- **命令定义提前告知**：如果 bot 需要调用自定义命令，在 SOUL.md 中写明用法，避免 bot 盲目搜索

## MCP 服务器

```json
{
  "tools": {
    "mcpServers": {
      "my-server": {
        "command": "node",
        "args": ["server.js"],
        "env": {}
      }
    }
  }
}
```

## 图片生成

```json
{
  "tools": {
    "imageGeneration": {
      "enabled": true,
      "provider": "openrouter",
      "model": "openai/gpt-5.4-image-2",
      "defaultAspectRatio": "1:1",
      "maxImagesPerTurn": 4
    }
  }
}
```
