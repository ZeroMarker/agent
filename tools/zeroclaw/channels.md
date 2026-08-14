# 频道配置

ZeroClaw 支持多种消息频道，每个频道独立配置和运行。

## 支持的频道

| 频道 | 编译特性 | 状态 |
|------|----------|------|
| CLI | 默认包含 | ✅ |
| QQ Official | `channel-qq` | ✅ |
| DingTalk | `channel-dingtalk` | ✅ |
| WeCom (企业微信) | `channel-wecom` | ✅ |
| Telegram | 默认包含 | 需配置 |
| Discord | 默认包含 | 需配置 |
| Slack | 默认包含 | 需配置 |
| WhatsApp Web | 默认包含 | 需配置 |
| Matrix | 默认包含 | 需配置 |
| Email | 默认包含 | 需配置 |
| Lark (飞书) | `channel-lark` | 需配置 |
| Signal | `channel-signal` | 需配置 |
| IRC | `channel-irc` | 需配置 |
| Bluesky | `channel-bluesky` | 需配置 |
| Twitter/X | `channel-twitter` | 需配置 |
| Reddit | `channel-reddit` | 需配置 |
| Twitch | `channel-twitch` | 需配置 |
| MQTT | `channel-mqtt` | 需配置 |
| AMQP | `channel-amqp` | 需配置 |
| Notion | `channel-notion` | 需配置 |

> **注意**：个人微信 (WeChat) 不受支持，仅支持企业微信 (WeCom)。

## 编译特性

预编译版本只包含默认频道。需要其他频道需源码编译：

```bash
# 全频道编译
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash -s -- --source --preset full

# 或手动指定特性
cargo build --release --features channels-full

# 仅编译特定频道
cargo build --release --features channel-qq,channel-dingtalk
```

## QQ Official 配置

### 1. 创建 QQ 机器人

1. 前往 [QQ 开放平台](https://q.qq.com/)
2. 创建机器人应用
3. 获取 `app_id` 和 `app_secret`

### 2. 配置 config.toml

```toml
[channels.qq]
enabled = true
allowed_users = ["*"]           # * 表示允许所有用户
app_id = "your-app-id"
app_secret = "your-app-secret"  # 会自动加密为 enc2: 格式
```

### 3. 限制允许用户

```toml
# 仅允许特定 QQ 号
allowed_users = ["123456789", "987654321"]

# 允许所有人
allowed_users = ["*"]
```

## DingTalk 配置

### 1. 创建钉钉机器人

1. 前往 [钉钉开放平台](https://open.dingtalk.com/)
2. 创建应用 -> 添加机器人
3. 获取 `client_id` 和 `client_secret`

### 2. 配置 config.toml

```toml
[channels.dingtalk]
enabled = true
allowed_users = ["*"]
client_id = "your-client-id"
client_secret = "your-client-secret"
```

## Telegram 配置

### 1. 创建 Telegram Bot

1. 在 Telegram 找 @BotFather
2. 发送 `/newbot` 创建机器人
3. 获取 bot token

### 2. 配置 config.toml

```toml
[channels.telegram]
enabled = true
bot_token = "your-bot-token"
allowed_users = ["*"]
```

### 3. 绑定用户

```bash
zeroclaw channel bind-telegram your_username
```

## Discord 配置

### 1. 创建 Discord Bot

1. 前往 [Discord Developer Portal](https://discord.com/developers/applications)
2. 创建应用 -> 添加 Bot
3. 获取 bot token
4. 邀请机器人到服务器

### 2. 配置 config.toml

```toml
[channels.discord]
enabled = true
bot_token = "your-bot-token"
allowed_users = ["*"]
```

## Slack 配置

```toml
[channels.slack]
enabled = true
bot_token = "xoxb-your-token"
app_token = "xapp-your-token"
allowed_users = ["*"]
```

## Email 配置

```toml
[channels.email]
enabled = true
smtp_host = "smtp.gmail.com"
smtp_port = 587
username = "your-email@gmail.com"
password = "your-password"
from = "your-email@gmail.com"
allowed_users = ["*"]
```

## 频道管理命令

```bash
# 列出所有频道
zeroclaw channel list

# 启动所有频道
zeroclaw channel start

# 频道健康检查
zeroclaw channel doctor

# 添加频道
zeroclaw channel add telegram '{"bot_token":"..."}'

# 移除频道
zeroclaw channel remove my-bot

# 发送消息
zeroclaw channel send 'Hello!' --channel-id telegram --recipient 123456
```

## 常见问题

### QQ 机器人不回复

1. 检查 `app_id` 和 `app_secret` 是否正确
2. 检查机器人是否已上线
3. 查看日志：`zeroclaw service logs | grep -i qq`
4. 确认 `allowed_users` 包含发送者

### DingTalk 机器人不回复

1. 检查 `client_id` 和 `client_secret`
2. 确认机器人已发布
3. 检查安全设置（IP 白名单等）

### 频道编译缺失

```
Configured but not compiled in this binary:
  DingTalk  🚫 configured, not compiled
```

需要源码编译完整版：
```bash
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash -s -- --source --preset full
```
