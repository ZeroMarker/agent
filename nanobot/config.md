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
      "maxTokens": 8192,
      "contextWindowTokens": 65536,
      "maxToolIterations": 200,
      "maxMessages": 120,
      "botName": "nanobot",
      "botIcon": "🐈",
      "timezone": "Asia/Shanghai",
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
| `maxTokens` | 最大输出 token | `8192` |
| `contextWindowTokens` | 上下文窗口大小 | `65536` |
| `maxToolIterations` | 最大工具调用次数 | `200` |
| `maxMessages` | 最大消息数 | `120` |
| `botName` | 机器人名称 | `nanobot` |
| `botIcon` | 机器人图标 | `🐈` |
| `timezone` | 时区 | `UTC` |

## 模型提供者

支持 30+ 提供者，每个提供者配置 `apiKey` 和可选的 `apiBase`。

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
    "moonshot": {
      "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

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
    "port": 18790,
    "heartbeat": {
      "enabled": true,
      "intervalS": 1800,
      "keepRecentMessages": 8
    }
  }
}
```

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
