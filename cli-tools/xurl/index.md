# xurl 使用文档（整理版）

> **xurl** — X (Twitter) API 官方 CLI 工具，curl 风格命令行接口，支持 OAuth 1.0a / OAuth 2.0 (PKCE) / App-only 三种认证方式。
>
> 源码：<https://github.com/xdevplatform/xurl> · 语言：Go · 许可证：MIT

---

## 目录

1. [功能概览](#1-功能概览)
2. [安装](#2-安装)
3. [快速开始](#3-快速开始)
4. [认证配置](#4-认证配置)
5. [应用与账户管理](#5-应用与账户管理)
6. [发起 API 请求](#6-发起-api-请求)
7. [流式响应](#7-流式响应)
8. [令牌管理](#8-令牌管理)
9. [媒体上传](#9-媒体上传)
10. [Webhook 临时设置](#10-webhook-临时设置)
11. [加密聊天 xurl chat](#11-加密聊天-xurl-chat)
12. [MCP 服务器](#12-mcp-服务器)
13. [令牌存储结构](#13-令牌存储结构)
14. [常见问题排查](#14-常见问题排查)

---

## 1. 功能概览

| 功能 | 说明 |
|------|------|
| 多应用支持 | 注册多个 X API 应用，各自持有独立凭据和令牌 |
| OAuth 2.0 PKCE | 标准授权码流程，支持多账户（每应用多个用户） |
| OAuth 1.0a | 传统签名认证 |
| App-only | Bearer Token 认证 |
| 默认选择器 | 交互式 Bubble Tea 选择器或单条命令设置默认应用/用户 |
| 令牌持久化 | `~/.xurl/auth.yml`（YAML），自动从旧版单文件迁移 |
| 请求定制 | 自定义方法、headers、body，`--app` 按请求覆盖应用 |
| 流式支持 | 自动检测流式端点，`-s` 强制流式 |
| 附加能力 | 媒体上传、临时 Webhook、端到端加密聊天（XChat）、MCP 桥接 |

---

## 2. 安装

| 方式 | 命令 | 平台/说明 |
|------|------|-----------|
| Homebrew | `brew install --cask xdevplatform/tap/xurl` | macOS |
| npm | `npm install -g @xdevplatform/xurl` | 通用 |
| Shell 脚本 | `curl -fsSL https://raw.githubusercontent.com/xdevplatform/xurl/main/install.sh \| bash` | 安装到 `~/.local/bin`，无需 sudo |
| Go | `go install github.com/xdevplatform/xurl@latest` | 需 Go 环境 |

> `xurl chat` 仅在 macOS / Linux amd64 可用；其他平台（Windows、Linux arm64/i386）打印不可用提示。源码构建需 cgo：`CGO_ENABLED=1 go install github.com/xdevplatform/xurl@latest`。

---

## 3. 快速开始

```bash
# 1. 注册应用（凭据存入 ~/.xurl/auth.yml）
xurl auth apps add my-app --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET

# 2. OAuth 2.0 授权（浏览器流程）
xurl auth oauth2 --app my-app

# 3. 发起请求
xurl /2/users/me
```

**前置要求：** X 开发者账户 + 应用；开发者门户中注册重定向 URI（默认 `http://localhost:8080/callback`）。

---

## 4. 认证配置

### 4.1 注册应用

```bash
# 基础注册
xurl auth apps add my-app --client-id ID --client-secret SECRET

# 附带存储回调 URI
xurl auth apps add my-app --client-id ID --client-secret SECRET --redirect-uri http://localhost:8080/callback

# 多应用
xurl auth apps add prod-app --client-id PROD_ID --client-secret PROD_SECRET
xurl auth apps add dev-app  --client-id DEV_ID  --client-secret DEV_SECRET
```

> **环境变量方式（旧版）**：设置 `CLIENT_ID` / `CLIENT_SECRET` 环境变量，首次使用时自动保存到当前应用。
>
> **REDIRECT_URI 解析优先级**：环境变量 `REDIRECT_URI` → 应用存储的 `redirect_uri` → 内置默认 `http://localhost:8080/callback`。

### 4.2 OAuth 2.0 用户上下文

```bash
xurl auth oauth2                 # 保存到默认应用
xurl auth oauth2 --app my-app    # 指定应用
xurl auth oauth2 --app my-app YOUR_USERNAME   # 显式用户名（/2/users/me 不可靠时）
```

**无头 / 远程机器**（无浏览器回调）：

```bash
xurl auth oauth2 --app my-app --headless
# 打印授权 URL → 任意设备浏览器打开 → 粘贴重定向 URL 或 code
```

### 4.3 App-only（Bearer Token）

```bash
xurl auth app-only BEARER_TOKEN
cat token.txt | xurl auth app-only -    # 从 stdin 读取，避免进入 shell 历史
```

- 请求时用 `--auth app` 使用
- 别名：`xurl auth app` / `xurl auth bearer`；`--bearer-token TOKEN` 仍接受

### 4.4 OAuth 1.0a

```bash
xurl auth oauth1 --consumer-key KEY --consumer-secret SECRET --access-token TOKEN --token-secret SECRET
```

### 4.5 认证状态与清除

```bash
xurl auth status                                # 查看所有应用认证状态
xurl auth clear --all                           # 清除全部
xurl auth clear --oauth1                        # 清除 OAuth 1.0a
xurl auth clear --oauth2-username USERNAME      # 清除指定用户
xurl auth clear --bearer                        # 清除 bearer
```

---

## 5. 应用与账户管理

```bash
xurl auth apps list                                   # 列出应用
xurl auth apps update my-app --client-id NEW_ID --client-secret NEW_SECRET   # 更新凭据
xurl auth apps update my-app --redirect-uri http://localhost:8080/callback   # 更新回调
xurl auth apps redirect-uri get my-app                # 查看有效/存储的 redirect URI
xurl auth apps redirect-uri set my-app http://localhost:8080/callback        # 设置
xurl auth apps remove old-app                         # 移除应用

xurl auth default                       # 交互式选择器（Bubble Tea）
xurl auth default my-app                # 命令方式：设默认应用
xurl auth default my-app alice          # 命令方式：设默认应用+用户

xurl --app dev-app /2/users/me          # 单请求覆盖应用
```

---

## 6. 发起 API 请求

```bash
# 基础 GET
xurl /2/users/me

# 自定义方法 + body
xurl -X POST /2/tweets -d '{"text":"Hello world!"}'

# 自定义 header
xurl -H "Content-Type: application/json" /2/tweets

# 指定认证类型
xurl --auth oauth2 /2/users/me
xurl --auth oauth1 /2/tweets
xurl --auth app /2/users/me

# 指定 OAuth2 账户
xurl --username johndoe /2/users/me
```

---

## 7. 流式响应

**自动流式端点：**

| 端点 |
|------|
| `/2/tweets/search/stream` |
| `/2/tweets/sample/stream` |
| `/2/tweets/sample10/stream` |
| `/2/tweets/firehose/stream/lang/en` |
| `/2/tweets/firehose/stream/lang/ja` |
| `/2/tweets/firehose/stream/lang/ko` |
| `/2/tweets/firehose/stream/lang/pt` |

```bash
xurl /2/tweets/search/stream    # 自动流式
xurl -s /2/users/me             # -s / --stream 强制任意端点流式
```

---

## 8. 令牌管理

```bash
xurl token                # 默认应用/用户的访问令牌（刷新后持久化）
xurl token --app my-app   # 指定应用
xurl token -u alice       # 指定用户
```

脚本用法（不打开浏览器，安全）：

```bash
TOKEN=$(xurl token) && curl -H "Authorization: Bearer $TOKEN" https://api.x.com/2/users/me
```

> 无可用令牌且无法刷新时，非零退出并提示运行 `xurl auth oauth2`。

---

## 9. 媒体上传

### 9.1 一键上传（推荐）

```bash
xurl media upload path/to/file.mp4     # 自动检测类型/类别
xurl media upload path/to/photo.jpg
xurl media upload --media-type image/jpeg --category tweet_image path/to/image.jpg  # 覆盖

xurl media status MEDIA_ID             # 查询状态
xurl media status --wait MEDIA_ID      # 等待处理完成
```

### 9.2 手动分块上传

```bash
# 1. 初始化
xurl -X POST /2/media/upload/initialize -d '{"total_bytes": FILE_SIZE, "media_type": "video/mp4", "media_category": "tweet_video"}'

# 2. 追加分块（递增 segment_index）
xurl -X POST -F path/to/file.mp4 /2/media/upload/MEDIA_ID/append

# 3. 完成
xurl -X POST /2/media/upload/MEDIA_ID/finalize

# 4. 状态
xurl '/2/media/upload?command=STATUS&media_id=MEDIA_ID'
```

---

## 10. Webhook 临时设置

```bash
# 1. 启动本地 + ngrok 转发（提示输入 ngrok authtoken，或用 NGROK_AUTHTOKEN 环境变量）
xurl webhook start
xurl webhook start -p 8081 -o webhook_events.log

# 2. 向 X API 注册 webhook（用输出的 ngrok URL）
xurl --auth app /2/webhooks -d '{"url": "<ngrok url>"}' -X POST
```

本地服务器自动处理 CRC 握手，记录 POST 事件（`-o` 写入文件）。

---

## 11. 加密聊天 xurl chat

端到端加密 XChat 客户端，基于官方 [chat-xdk](https://github.com/xdevplatform/chat-xdk) 库。**服务器只能看到密文。**

### 11.1 密钥导入（必须，xurl 不生成密钥）

```bash
xurl chat keys restore    # 用 PIN 从 Juicebox 恢复
xurl chat keys import     # 粘贴导出的私钥 blob
xurl chat keys status     # 查看密钥状态和指纹
```

> 需要带 `dm.read` + `dm.write` scope 的 OAuth2 登录；未在账户注册的密钥会被拒绝；私钥存于 `~/.xurl/keys.yml`（权限 600）。

### 11.2 会话操作

```bash
xurl chat conversations                            # 收件箱
xurl chat read @bob [-n 50] [--json]               # 解密历史（自动标记已读）
xurl chat listen @bob                              # 实时监听（Ctrl-C 停止）
xurl chat send @bob "hello"                        # 发送（自动建新 1:1 密钥）
xurl chat send @bob "look" --file photo.png        # 加密附件
xurl chat send @bob "ok" --reply-to SEQUENCE_ID    # 线程回复
xurl chat download @bob MEDIA_HASH_KEY -o out.png  # 下载并解密附件
xurl chat rotate @bob                              # 轮换会话密钥
xurl chat add-members g123 @carol                  # 添加群成员（轮换密钥）
xurl chat mark-read @bob                           # 手动标记已读
xurl chat typing @bob                              # 手动发送输入状态
```

**会话寻址：** `@用户名`、用户 ID、或会话 ID（`123-456` / `g123`）。

**行为细节：**
- `read` / `listen` / `send` 自动标记已读；`send` 自动发送 typing 指示
- 可用 `--no-mark-read` / `--no-typing` 关闭
- `rotate` / `add-members` 更换所有参与者的密钥，仅保护未来消息

---

## 12. MCP 服务器

`xurl mcp` 将 xurl 变为 X API MCP 服务器的桥接器（stdin/stdout 传 JSON-RPC，自动维护 session id 和令牌刷新）。

### MCP 客户端配置示例（Claude Desktop / Cursor 等）

```json
{
  "mcpServers": {
    "xapi": {
      "command": "npx",
      "args": ["-y", "@xdevplatform/xurl", "mcp", "https://api.x.com/mcp"],
      "env": { "CLIENT_ID": "...", "CLIENT_SECRET": "..." },
      "startup_timeout_sec": 300
    }
  }
}
```

### 命令行用法

```bash
xurl mcp                            # 默认端点 https://api.x.com/mcp
xurl mcp https://api.x.com/mcp      # 显式端点
xurl --app my-app mcp               # 使用指定注册应用
```

**要点：**
- 首次运行无缓存令牌时打开浏览器做一次性 OAuth2 登录，之后缓存并自动刷新
- 无头主机先执行 `xurl auth oauth2 --headless` 离线认证
- 应用需注册重定向 URI `http://localhost:8080/callback`（或设置 `REDIRECT_URI`）
- 诊断写入 stderr，stdout 保持纯净 JSON-RPC 通道

---

## 13. 令牌存储结构

```
~/.xurl/
├── auth.yml    # 应用凭据 + 令牌（YAML，多应用）
└── keys.yml    # XChat 私钥（权限 600）
```

示例 `auth.yml`：

```yaml
apps:
  my-app:
    client_id: abc123
    client_secret: secret456
    redirect_uri: http://localhost:8080/callback
    default_user: alice
    oauth2_tokens:
      alice:
        type: oauth2
        oauth2:
          access_token: "..."
          refresh_token: "..."
          expiration_time: 1234567890
    bearer_token:
      type: bearer
      bearer: "AAAA..."
default_app: my-app
```

> **迁移：** 旧版单文件 `~/.xurl` 首次使用时自动迁移为 `~/.xurl/auth.yml`；v1.0 前的 JSON 格式自动转换为 YAML 多应用格式（令牌保留在 `default` 应用中）。

---

## 14. 常见问题排查

### 14.1 `client-forbidden` / `client-not-enrolled`

认证成功但 `xurl whoami` 等读取失败时：

1. `Apps` → `Manage apps`
2. 打开应用
3. `Move to package`
4. 选择 **Pay-per-use**
5. 移动应用到 **Production** 环境

> 这是 X 平台注册问题，非 xurl 本地回调问题。

### 14.2 `/2/users/me` 不返回用户名

改用显式用户名认证：

```bash
xurl auth oauth2 --app my-app YOUR_USERNAME
```

### 14.3 无头机器无法 OAuth

使用 `--headless` 流程（见 [4.2](#42-oauth-20-用户上下文)）。

### 14.4 xurl chat 不可用

- 检查平台是否受支持（macOS / Linux amd64）
- 源码构建需 `CGO_ENABLED=1`
