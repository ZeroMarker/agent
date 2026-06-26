# WeClaw 技术文档

## 目录

- [项目概述](#项目概述)
- [架构设计](#架构设计)
- [目录结构](#目录结构)
- [核心模块](#核心模块)
  - [Agent 系统](#agent-系统)
  - [配置系统](#配置系统)
  - [iLink 客户端](#ilink-客户端)
  - [消息处理](#消息处理)
  - [API 服务](#api-服务)
  - [CLI 命令](#cli-命令)
- [数据流](#数据流)
- [配置参考](#配置参考)
- [部署指南](#部署指南)
- [开发指南](#开发指南)

---

## 项目概述

WeClaw 是一个 **微信 AI Agent 桥接器**，使用 Go 语言编写。它通过腾讯 iLink API 连接微信，将微信消息路由到各类 AI Agent（Claude、Codex、Gemini、Kimi、Cursor 等），并将 Agent 回复发送回微信。

**核心特性：**

- 支持三种 Agent 模式：ACP（JSON-RPC over stdio）、CLI（进程级隔离）、HTTP（OpenAI 兼容 API）
- 自动检测已安装的 AI Agent
- 多 Agent 广播（`@cc @cx hello` 同时发送到多个 Agent）
- 媒体消息支持（图片、视频、语音、文件）
- 主动消息推送（CLI + HTTP API）
- 自动更新、后台守护、系统服务集成

---

## 架构设计

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  微信用户    │ ──→ │  iLink API   │ ──→ │  Monitor        │
│             │ ←── │  (腾讯服务器) │ ←── │  (长轮询)       │
└─────────────┘     └──────────────┘     └────────┬────────┘
                                                   │
                                          ┌────────▼────────┐
                                          │    Handler       │
                                          │  (消息路由/命令) │
                                          └────────┬────────┘
                                                   │
                    ┌──────────────────────────────┼──────────────────────────────┐
                    │                              │                              │
           ┌────────▼────────┐           ┌────────▼────────┐           ┌────────▼────────┐
           │   ACP Agent     │           │   CLI Agent     │           │   HTTP Agent    │
           │ (JSON-RPC/stdio)│           │ (进程/消息)     │           │ (OpenAI API)    │
           └─────────────────┘           └─────────────────┘           └─────────────────┘
```

**设计模式：**

1. **Agent 接口 + 工厂模式** — 统一接口，按需创建
2. **双重检查锁** — 线程安全的懒加载 Agent
3. **指数退避重连** — 长轮询断线自动恢复
4. **自动权限审批** — ACP 模式自动允许所有权限请求（微信无法交互）
5. **附件安全校验** — 本地文件路径需在允许的根目录内（含符号链接解析）

---

## 目录结构

```
weclaw/
├── main.go                        # 入口点 → cmd.Execute()
├── go.mod / go.sum                # Go 模块定义
├── Makefile                       # make dev (热重载)
├── Dockerfile                     # 多阶段构建
├── install.sh                     # 一键安装脚本
├── .air.toml                      # 热重载配置
│
├── agent/                         # Agent 抽象层
│   ├── agent.go                   # Agent 接口 + AgentInfo + 辅助函数
│   ├── acp_agent.go               # ACP Agent (JSON-RPC over stdio, ~1056 行)
│   ├── cli_agent.go               # CLI Agent (每消息一个进程)
│   ├── http_agent.go              # HTTP Agent (OpenAI 兼容 API)
│   └── env_test.go                # 环境变量合并测试
│
├── api/                           # HTTP API 服务
│   └── server.go                  # POST /api/send, GET /health
│
├── cmd/                           # CLI 命令 (cobra)
│   ├── root.go                    # 根命令, version, Execute()
│   ├── start.go                   # weclaw start — 主运行时 (435 行)
│   ├── login.go                   # weclaw login — 二维码登录
│   ├── send.go                    # weclaw send — 主动消息
│   ├── stop.go                    # weclaw stop
│   ├── status.go                  # weclaw status
│   ├── restart.go                 # weclaw restart
│   ├── update.go                  # weclaw update / version
│   ├── proc_unix.go               # Unix Setsid 守护进程
│   └── proc_windows.go            # Windows 空实现
│
├── config/                        # 配置系统
│   ├── config.go                  # Config 结构体, Load/Save, 别名构建
│   ├── config_test.go             # 配置序列化/环境变量测试
│   ├── detect.go                  # 自动检测已安装 AI Agent
│   └── detect_test.go             # 检测测试
│
├── ilink/                         # iLink (微信) API 客户端
│   ├── client.go                  # HTTP 客户端 (getupdates, sendmessage 等)
│   ├── types.go                   # iLink 协议类型定义
│   ├── auth.go                    # 二维码登录, 凭证持久化
│   └── monitor.go                 # 长轮询循环 + 指数退避 + 同步缓冲
│
├── messaging/                     # 消息处理 & 媒体管道
│   ├── handler.go                 # 核心消息路由 (813 行)
│   ├── handler_test.go            # 命令解析测试
│   ├── sender.go                  # 发送文本回复 + 输入指示器
│   ├── markdown.go                # Markdown → 纯文本转换
│   ├── media.go                   # 媒体下载/上传/发送管道
│   ├── media_test.go              # URL 提取测试
│   ├── attachment.go              # 本地附件提取 & 安全校验
│   ├── attachment_test.go         # 附件路径测试
│   ├── cdn.go                     # 微信 CDN 上传/下载 (AES-128-ECB)
│   └── linkhoard.go               # URL 书签 (Linkhoard 格式)
│
├── service/                       # 系统服务配置
│   ├── com.fastclaw.weclaw.plist  # macOS launchd
│   └── weclaw.service             # Linux systemd
│
└── previews/                      # README 截图
```

---

## 核心模块

### Agent 系统

#### Agent 接口

```go
// agent/agent.go
type Agent interface {
    Chat(ctx context.Context, conversationID string, message string) (string, error)
    ResetSession(ctx context.Context, conversationID string) (string, error)
    Info() AgentInfo
    SetCwd(cwd string)
}
```

| 方法 | 说明 |
|------|------|
| `Chat` | 发送消息并获取回复。`conversationID` 为微信用户 ID |
| `ResetSession` | 重置会话状态（ACP 返回新 session ID，CLI/HTTP 返回空） |
| `Info` | 返回 Agent 元数据（名称、类型、模型、命令、PID） |
| `SetCwd` | 运行时切换工作目录 |

#### ACP Agent (`acp_agent.go`)

通过 **JSON-RPC 2.0 over stdio** 与 AI Agent 通信，是最复杂的 Agent 类型。

**协议自动检测：**
- 二进制为 `codex` 且含 `app-server` 参数 → `codex_app_server` 协议
- 其他 → `legacy_acp` 协议

**生命周期：**
1. `Start(ctx)` — 启动子进程，建立 stdin/stdout 管道，4MB scanner 缓冲，执行 initialize 握手（30s 超时）
2. `Chat()` — 获取/创建 session，发送 `session/prompt`，收集流式通知，拼接返回文本
3. `Stop()` — 终止子进程

**Legacy ACP 协议流程：**
```
initialize → session/new → session/prompt → [session/update 通知流]
```

**Codex App Server 协议流程：**
```
initialize + initialized → thread/start → turn/start → [agent_message_delta 事件流] → turn/completed
```

**权限处理：** 自动允许所有权限请求（发送 `selected` + `allow`），因微信无法进行交互式审批。

#### CLI Agent (`cli_agent.go`)

每条消息启动一个新进程。支持两种模式：

| 模式 | 命令 | 特性 |
|------|------|------|
| Claude CLI | `claude -p <msg> --output-format stream-json --verbose` | 支持 `--resume` 多轮对话，流式 JSON |
| Codex CLI | `codex exec <msg>` | 非流式，等待完整输出 |

配置支持 `--dangerously-skip-permissions`（Claude）和 `--skip-git-repo-check`（Codex）跳过权限检查。

#### HTTP Agent (`http_agent.go`)

OpenAI 兼容的 Chat Completions 客户端。维护内存中的对话历史（默认最多 20 轮），无服务端 session。

通过 `max_history` 控制历史轮数：
- `0` — 禁用历史，每条消息独立发送（仅 system + user）
- `1` ~ `N` — 保留最近 N 轮对话历史
- 未设置 — 默认 20 轮

> **注意：** 部分 API 端点（如 nanobot serve）仅支持单条 user message，需设置 `"max_history": 0`，否则会返回 `400: Only a single user message is supported` 错误。

```json
POST /v1/chat/completions
{
  "model": "deepseek-v4-flash",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "hello"},
    {"role": "assistant", "content": "..."},
    ...
  ]
}
```

---

### 配置系统

#### 配置文件结构

路径：`~/.weclaw/config.json`

```go
// config/config.go
type Config struct {
    DefaultAgent string                 `json:"default_agent"`
    APIAddr      string                 `json:"api_addr,omitempty"`
    SaveDir      string                 `json:"save_dir,omitempty"`
    Agents       map[string]AgentConfig `json:"agents"`
}

type AgentConfig struct {
    Type         string            // "acp" | "cli" | "http"
    Command      string            // 二进制路径
    Args         []string          // 额外 CLI 参数
    Aliases      []string          // 自定义触发别名
    Cwd          string            // 工作目录
    Env          map[string]string // 额外环境变量
    Model        string            // 模型名称
    SystemPrompt string            // 系统提示词
    Endpoint     string            // HTTP 类型的端点 URL
    APIKey       string            // HTTP 类型的 API Key
    Headers      map[string]string // HTTP 类型的自定义请求头
    MaxHistory   int               // HTTP 类型的最大历史轮数
}
```

#### 环境变量覆盖

| 变量 | 说明 |
|------|------|
| `WECLAW_DEFAULT_AGENT` | 覆盖默认 Agent |
| `WECLAW_API_ADDR` | 覆盖 API 监听地址 |
| `WECLAW_SAVE_DIR` | 覆盖文件保存目录 |
| `OPENCLAW_GATEWAY_URL` | OpenClaw HTTP 回退端点 |
| `OPENCLAW_GATEWAY_TOKEN` | OpenClaw API Token |

#### 自动检测 (`detect.go`)

`DetectAndConfigure(cfg)` 按优先级扫描已安装的 AI Agent：

```
claude (ACP) > claude (CLI) > codex (ACP) > codex (CLI) > cursor > kimi > gemini > opencode > openclaw > pi > copilot > droid > iflow > kiro > qwen
```

检测逻辑：
1. 先用 `exec.LookPath` 查找二进制
2. 回退到 login shell（`zsh -lic which <binary>`）
3. ACP 优先于 CLI（当两者都可用时）
4. 检测到新 Agent 时自动追加到配置并保存

#### 别名系统

内置别名（不可覆盖）：

| 别名 | Agent |
|------|-------|
| `/cc` | claude |
| `/cx` | codex |
| `/cs` | cursor |
| `/km` | kimi |
| `/gm` | gemini |
| `/ocd` | opencode |
| `/oc` | openclaw |
| `/pi` | pi |
| `/cp` | copilot |
| `/dr` | droid |
| `/if` | iflow |
| `/kr` | kiro |
| `/qw` | qwen |

内置命令（保留）：`/info`, `/help`, `/new`, `/clear`, `/cwd`

自定义别名在配置中定义：
```json
{
  "agents": {
    "claude": {
      "type": "acp",
      "aliases": ["ai", "c"]
    }
  }
}
```

---

### iLink 客户端

iLink 是腾讯的微信机器人 API（`ilinkai.weixin.qq.com`）。

#### 核心类型 (`ilink/types.go`)

| 类型 | 说明 |
|------|------|
| `WeixinMessage` | 收到的消息，含 `FromUserID`, `MessageType`, `ItemList` 等 |
| `MessageItem` | 多态消息体：`TextItem`, `ImageItem`, `VoiceItem`, `VideoItem`, `FileItem` |
| `MediaInfo` | CDN 引用：`EncryptQueryParam`, `AESKey`, `EncryptType` |
| `Credentials` | 登录凭证：`BotToken`, `ILinkBotID`, `BaseURL`, `ILinkUserID` |

#### 认证流程 (`ilink/auth.go`)

```
1. FetchQRCode() → /ilink/bot/get_bot_qrcode?bot_type=3
2. PollQRStatus() → 长轮询 /ilink/bot/get_qrcode_status?qrcode=<code>
3. 返回 Credentials (BotToken, ILinkBotID, BaseURL, ILinkUserID)
4. 保存到 ~/.weclaw/accounts/<normalized_id>.json
```

#### 长轮询 Monitor (`ilink/monitor.go`)

```go
type Monitor struct {
    client        *Client
    handler       MessageHandler    // func(ctx, client, msg)
    getUpdatesBuf string            // 同步缓冲（断线恢复）
    bufPath       string            // 持久化到磁盘
    failures      int
    lastActivity  time.Time
}
```

**特性：**
- 指数退避：3s → 6s → 12s → 24s → 48s → 60s（上限）
- Session 过期自动恢复（errcode -14）
- 同步缓冲持久化（崩溃恢复）
- 连续 5 次失败提示重新登录

---

### 消息处理

#### Handler (`messaging/handler.go`)

核心消息路由器（813 行），处理从微信收到的所有消息。

**处理流程：**

```
1. 过滤：仅处理用户消息 (MessageTypeUser) 且已完成 (MessageStateFinish)
2. 去重：使用 message_id 避免重复处理（尤其是语音消息）
3. 提取文本：从 TextItem 或 VoiceItem.Text（语音转文字）
4. 图片保存：无文本但有图片且配置了 saveDir → 保存到磁盘
5. URL 拦截：纯 URL 消息且配置了 saveDir → 保存到 Linkhoard（书签）
6. 内置命令：/info, /help, /new, /cwd
7. 命令解析：/name message 或 @name message
8. 路由：
   - 无前缀 → 默认 Agent
   - 仅名称（无消息）→ 切换默认 Agent（持久化到配置）
   - 单 Agent + 消息 → 发送到该 Agent
   - 多 Agent → 并行广播，回复独立到达
```

**多 Agent 广播：**
```
@cc @cx 解释这段代码
→ 同时发送到 claude 和 codex
→ 两个回复分别到达
```

#### 媒体管道

**发送流程：**
1. `ExtractImageURLs()` — 从 Markdown 提取图片 URL
2. `SendMediaFromURL()` — 下载 → 分类 → CDN 上传 → 发送消息
3. CDN 上传使用 **AES-128-ECB** 加密（随机 16 字节 key）

**附件安全：**
- `extractLocalAttachmentPaths()` — 扫描回复中的本地文件路径
- `isAllowedAttachmentPath()` — 路径必须在允许的根目录下（workspace 或 agent cwd），含符号链接解析防止路径遍历

#### Markdown 转换

`MarkdownToPlainText()` 将 Markdown 转为微信友好的纯文本：
- 代码块 → 保留内容，移除围栏
- 链接 → 仅显示文本
- 表格 → 空格分隔行
- 图片 → 完全移除
- 加粗/斜体/删除线 → 纯文本
- 列表 → `• ` 标记

---

### API 服务 (`api/server.go`)

HTTP 服务用于主动推送消息，默认监听 `127.0.0.1:18011`。

**端点：**

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/send` | 发送文本和/或媒体到微信用户 |
| `GET` | `/health` | 健康检查，返回 "ok" |

**请求体：**
```json
{
  "to": "user_id@im.wechat",
  "text": "Hello from weclaw",
  "media_url": "https://example.com/photo.png"
}
```

---

### CLI 命令

| 命令 | 说明 |
|------|------|
| `weclaw start` | 启动桥接服务（默认后台运行） |
| `weclaw start -f` | 前台运行（调试用） |
| `weclaw login` | 添加微信账号（扫码登录） |
| `weclaw send --to <id> --text "..."` | 主动发送消息 |
| `weclaw send --to <id> --media "url"` | 主动发送媒体 |
| `weclaw stop` | 停止服务 |
| `weclaw status` | 查看运行状态 |
| `weclaw restart` | 重启服务 |
| `weclaw update` | 自动更新到最新版本 |
| `weclaw version` | 显示版本信息 |

**守护进程模式 (`cmd/start.go`):**
- 杀死已有的 weclaw 进程
- 重新执行自身 `start -f`，Unix 下使用 `Setsid` 脱离终端
- PID 保存到 `~/.weclaw/weclaw.pid`
- 日志写入 `~/.weclaw/weclaw.log`

---

## 数据流

```
微信用户
  │ (发送消息)
  ▼
iLink API (腾讯) ←── Monitor.GetUpdates() 长轮询
  │
  ▼
Monitor.Run() → handler.HandleMessage(ctx, client, msg)
  │
  ▼
Handler.parseCommand() → 解析别名 → 路由
  │
  ▼
agent.Chat(ctx, conversationID, message)
  │
  ├─→ ACPAgent: stdin → JSON-RPC → stdout → readLoop → notifyCh
  ├─→ CLIAgent: exec "claude -p ..." → 解析 stream-json
  └─→ HTTPAgent: POST /v1/chat/completions → 解析 JSON
  │
  ▼ (回复字符串)
Handler.sendReplyWithMedia()
  │
  ├─→ MarkdownToPlainText()
  ├─→ ExtractImageURLs() → CDN 上传
  ├─→ extractLocalAttachmentPaths()
  └─→ SendTextReply() via iLink API
  │
  ▼
微信用户 (收到回复)
```

---

## 配置参考

### 完整配置示例

```json
{
  "default_agent": "claude",
  "api_addr": "127.0.0.1:18011",
  "save_dir": "~/Downloads/weclaw",
  "agents": {
    "claude": {
      "type": "acp",
      "command": "/usr/local/bin/claude-agent-acp",
      "env": {
        "ANTHROPIC_API_KEY": "sk-ant-xxx"
      },
      "model": "sonnet",
      "aliases": ["ai", "c"]
    },
    "codex": {
      "type": "acp",
      "command": "/usr/local/bin/codex",
      "args": ["app-server", "--listen", "stdio://"],
      "env": {
        "OPENAI_API_KEY": "sk-xxx"
      }
    },
    "claude-cli": {
      "type": "cli",
      "command": "/usr/local/bin/claude",
      "cwd": "/home/user/my-project",
      "args": ["--dangerously-skip-permissions"]
    },
    "nanobot": {
      "type": "http",
      "endpoint": "http://127.0.0.1:8900/v1/chat/completions",
      "model": "deepseek-v4-flash",
      "max_history": 0
    },
    "openclaw": {
      "type": "http",
      "endpoint": "https://api.example.com/v1/chat/completions",
      "api_key": "sk-xxx",
      "model": "openclaw:main",
      "headers": {
        "X-Custom-Header": "value"
      },
      "max_history": 30
    }
  }
}
```

---

## 部署指南

### 一键安装

```bash
curl -sSL https://raw.githubusercontent.com/fastclaw-ai/weclaw/main/install.sh | sh
```

### Go 安装

```bash
go install github.com/fastclaw-ai/weclaw@latest
```

### Docker

```bash
# 构建
docker build -t weclaw .

# 登录（交互式 — 扫码）
docker run -it -v ~/.weclaw:/root/.weclaw weclaw login

# 启动（HTTP Agent）
docker run -d --name weclaw \
  -v ~/.weclaw:/root/.weclaw \
  -e OPENCLAW_GATEWAY_URL=https://api.example.com \
  -e OPENCLAW_GATEWAY_TOKEN=sk-xxx \
  weclaw

# 查看日志
docker logs -f weclaw
```

> **注意：** ACP 和 CLI Agent 需要将二进制挂载到容器内。Docker 镜像仅包含 WeClaw 本体。HTTP Agent 开箱即用。

### 系统服务

**macOS (launchd):**
```bash
cp service/com.fastclaw.weclaw.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.fastclaw.weclaw.plist
```

**Linux (systemd):**
```bash
sudo cp service/weclaw.service /etc/systemd/system/
sudo systemctl enable --now weclaw
```

### 配置 nanobot 作为 Agent

```bash
# 1. 启动 nanobot 的 OpenAI 兼容 API 服务
nohup nanobot serve -p 8900 &

# 2. 编辑 ~/.weclaw/config.json，添加 nanobot agent
cat > ~/.weclaw/config.json << 'EOF'
{
  "default_agent": "nanobot",
  "agents": {
    "nanobot": {
      "type": "http",
      "endpoint": "http://127.0.0.1:8900/v1/chat/completions",
      "model": "deepseek-v4-flash",
      "max_history": 0
    }
  }
}
EOF

# 3. 重启 WeClaw
weclaw restart
```

> **重要：** nanobot serve 仅支持单条 user message，必须设置 `"max_history": 0` 禁用历史累积，否则多轮对话会报 400 错误。

---

## 开发指南

### 热重载开发

```bash
# 需要安装 air: go install github.com/air-verse/air@latest
make dev
```

### 构建

```bash
go build -o weclaw .
```

### 测试

```bash
go test ./...
```

### 添加新 Agent 类型

1. 在 `agent/` 下实现 `Agent` 接口
2. 在 `config/detect.go` 的 `agentCandidates` 中添加检测项
3. 在 `cmd/start.go` 的 `createAgentByName` 中添加创建逻辑
4. 在 `messaging/handler.go` 的内置别名中添加映射

### 发布

```bash
git tag v0.x.x
git push origin v0.x.x
```

GitHub Actions 会自动构建 `darwin/linux/windows` × `amd64/arm64` 的二进制，创建 Release 并上传所有产物及校验和。
