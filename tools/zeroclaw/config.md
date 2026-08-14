# 配置指南

配置文件位置：`~/.zeroclaw/config.toml`

## 基础配置

```toml
schema_version = 2
```

## 模型提供者 (providers)

```toml
[providers]
fallback = "deepseek"  # 默认 fallback 提供者

[providers.models.deepseek]
model = "deepseek-v4-flash"
api_key = "your-api-key"  # 或使用 enc2: 加密存储
max_tokens = 4096
temperature = 0.7
timeout_secs = 120
wire_api = "chat_completions"
```

支持的提供者类型：
- `deepseek` - DeepSeek
- `openai` - OpenAI (GPT-4o 等)
- `anthropic` - Anthropic (Claude 等)
- `google` - Google (Gemini 等)
- `openrouter` - OpenRouter
- `ollama` - 本地 Ollama

### 提供者选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `model` | 模型 ID | - |
| `api_key` | API 密钥 | - |
| `max_tokens` | 最大输出 token | 4096 |
| `temperature` | 温度 | 0.7 |
| `timeout_secs` | 超时秒数 | 120 |
| `wire_api` | API 格式 | chat_completions |
| `kind` | 提供者实现类型 | - |
| `fallback` | 备选提供者列表 | [] |
| `fallback_models` | 备选模型列表 | [] |
| `native_tools` | 原生工具调用 | null |
| `merge_system_into_user` | 合并 system 到 user | false |
| `think` | 启用思维链 | null |

## 自主权限 (autonomy)

```toml
[autonomy]
level = "full"                    # readonly / supervised / full
workspace_only = false            # 是否限制在工作空间内
max_actions_per_hour = 100        # 每小时最大操作数
require_approval_for_medium_risk = false  # 中风险是否需要审批
block_high_risk_commands = false  # 是否阻止高风险命令
shell_timeout_secs = 60           # shell 超时

allowed_commands = [
    "git", "npm", "cargo", "ls", "cat", "grep", "find",
    "echo", "pwd", "wc", "head", "tail", "date", "df",
    "du", "uname", "uptime", "hostname", "python", "python3",
    "pip", "node", "free", "curl", "wget", "ssh", "scp",
    "docker", "systemctl", "ps", "kill", "chmod", "chown",
    "mkdir", "rm", "cp", "mv", "tar",
]

forbidden_paths = [
    "/etc/shadow", "/etc/gshadow",
    "~/.ssh/id_*", "~/.gnupg", "~/.aws/credentials",
]

auto_approve = [
    "file_read", "memory_recall", "web_search_tool",
    "web_fetch", "calculator", "glob_search", "content_search",
]
```

### 权限级别

| 级别 | 说明 |
|------|------|
| `readonly` | 只读，不能执行任何操作 |
| `supervised` | 受监督，需要审批 |
| `full` | 完全自主 |

## 安全配置 (security)

```toml
[security.sandbox]
backend = "auto"           # sandbox 实现

[security.resources]
max_memory_mb = 512        # 最大内存
max_cpu_time_seconds = 60  # 最大 CPU 时间
max_subprocesses = 10      # 最大子进程数

[security.audit]
enabled = true             # 启用审计
log_path = "audit.log"     # 审计日志路径

[security.otp]
enabled = false            # 启用 OTP 验证
method = "totp"            # OTP 方式

[security.estop]
enabled = false            # 启用紧急停止
```

## 频道配置 (channels)

```toml
[channels]
cli = true                 # 启用 CLI 频道
message_timeout_secs = 300 # 消息超时
session_persistence = true # 会话持久化

[channels.qq]
enabled = true
allowed_users = ["*"]      # 允许的用户，* 表示所有
app_id = "your-app-id"
app_secret = "your-secret"

[channels.dingtalk]
enabled = true
allowed_users = ["*"]
client_id = "your-client-id"
client_secret = "your-secret"
```

详见 [频道配置](channels.md)。

## 记忆系统 (memory)

```toml
[memory]
backend = "sqlite"                # sqlite / postgres / qdrant
auto_save = true                  # 自动保存
search_mode = "hybrid"            # hybrid / vector / fts
embedding_provider = "none"       # 嵌入提供者
conversation_retention_days = 30  # 对话保留天数
```

## Gateway 配置

```toml
[gateway]
port = 42617                # 监听端口
host = "127.0.0.1"          # 监听地址
require_pairing = true      # 需要配对
allow_public_bind = false   # 允许公网绑定
```

## 调度器 (scheduler)

```toml
[scheduler]
enabled = true
max_tasks = 64              # 最大任务数
max_concurrent = 4          # 最大并发数
```

## 心跳 (heartbeat)

```toml
[heartbeat]
enabled = true
interval_minutes = 30       # 心跳间隔
```

## Agent 配置

```toml
[agent]
compact_context = true
max_tool_iterations = 10
max_history_messages = 50
max_context_tokens = 32000
```

## 浏览器

```toml
[browser]
enabled = true
allowed_domains = ["*"]
native_headless = true
```

## Web 抓取

```toml
[web_fetch]
enabled = true
allowed_domains = ["*"]
max_response_size = 500000
timeout_secs = 30

[web_search]
enabled = true
provider = "duckduckgo"
max_results = 5
```

## 费用控制

```toml
[cost]
enabled = true
daily_limit_usd = 10.0
monthly_limit_usd = 100.0
warn_at_percent = 80
```

## 配置管理命令

```bash
# 查看所有配置
zeroclaw config list

# 获取某个值
zeroclaw config get autonomy.level

# 设置值
zeroclaw config set autonomy.level full

# 查看配置 Schema
zeroclaw config schema

# 初始化未配置的部分
zeroclaw config init channels.telegram

# 迁移配置版本
zeroclaw config migrate
```
