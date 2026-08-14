# 频道配置

nanobot 支持多种消息频道，配置在 `~/.nanobot/config.json` 的 `channels` 部分。

## 支持的频道

| 频道 | 配置键 | 状态 |
|------|--------|------|
| QQ | `qq` | ✅ |
| Telegram | `telegram` | ✅ |
| Discord | `discord` | ✅ |
| Slack | `slack` | ✅ |
| 飞书 (Feishu) | `feishu` | ✅ |
| 企业微信 (WeCom) | `wecom` | ✅ |
| 微信 (Weixin) | `weixin` | ✅ |
| Email | `email` | ✅ |
| Signal | `signal` | ✅ |
| WhatsApp | `whatsapp` | ✅ |
| MS Teams | `msteams` | ✅ |
| WebSocket | `websocket` | ✅ |
| MoChat | `mochat` | ✅ |

## QQ 频道

### 1. 创建 QQ 机器人

1. 前往 [QQ 开放平台](https://q.qq.com/)
2. 创建机器人应用
3. 获取 `appId` 和 `secret`

### 2. 配置

```json
{
  "channels": {
    "qq": {
      "enabled": true,
      "appId": "your-app-id",
      "secret": "your-app-secret",
      "allowFrom": ["*"],
      "msgFormat": "plain",
      "ackMessage": "⏳ Processing..."
    }
  }
}
```

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 启用 | `false` |
| `appId` | QQ 机器人 App ID | - |
| `secret` | App Secret | - |
| `allowFrom` | 允许的用户，`*` 表示所有 | `[]` |
| `msgFormat` | 消息格式 (`plain` / `markdown`) | `plain` |
| `ackMessage` | 收到消息后的确认消息 | `⏳ Processing...` |

### 3. 限制允许用户

```json
"allowFrom": ["123456789", "987654321"]
```

## Telegram 频道

### 1. 创建 Telegram Bot

1. 在 Telegram 找 @BotFather
2. 发送 `/newbot` 创建机器人
3. 获取 bot token

### 2. 配置

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "your-bot-token",
      "mode": "polling",
      "allowFrom": ["*"],
      "replyToMessage": false,
      "reactEmoji": "👀",
      "groupPolicy": "mention",
      "streaming": true
    }
  }
}
```

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 启用 | `false` |
| `token` | Bot Token | - |
| `mode` | 模式 (`polling` / `webhook`) | `polling` |
| `allowFrom` | 允许的用户 | `[]` |
| `replyToMessage` | 回复原消息 | `false` |
| `groupPolicy` | 群组策略 (`mention` / `open`) | `mention` |
| `streaming` | 流式输出 | `true` |

## Discord 频道

### 1. 创建 Discord Bot

1. 前往 [Discord Developer Portal](https://discord.com/developers/applications)
2. 创建应用 -> 添加 Bot
3. 获取 bot token
4. 邀请机器人到服务器

### 2. 配置

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "your-bot-token",
      "allowFrom": ["*"],
      "groupPolicy": "mention",
      "streaming": true
    }
  }
}
```

## Slack 频道

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "mode": "socket",
      "botToken": "xoxb-your-token",
      "appToken": "xapp-your-token",
      "allowFrom": ["*"],
      "replyInThread": true,
      "groupPolicy": "mention"
    }
  }
}
```

## 飞书频道

```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "your-app-id",
      "appSecret": "your-app-secret",
      "allowFrom": ["*"],
      "groupPolicy": "mention"
    }
  }
}
```

## Email 频道

```json
{
  "channels": {
    "email": {
      "enabled": true,
      "imapHost": "imap.gmail.com",
      "imapPort": 993,
      "imapUsername": "your-email@gmail.com",
      "imapPassword": "your-password",
      "smtpHost": "smtp.gmail.com",
      "smtpPort": 587,
      "smtpUsername": "your-email@gmail.com",
      "smtpPassword": "your-password",
      "allowFrom": ["*"]
    }
  }
}
```

## 企业微信 (WeCom)

```json
{
  "channels": {
    "wecom": {
      "enabled": true,
      "botId": "your-bot-id",
      "secret": "your-secret",
      "allowFrom": ["*"]
    }
  }
}
```

## 微信 (Weixin)

```json
{
  "channels": {
    "weixin": {
      "enabled": true,
      "allowFrom": ["*"],
      "token": "your-token"
    }
  }
}
```

## 通用选项

所有频道通用的配置选项：

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 是否启用 | `false` |
| `allowFrom` | 允许的用户列表，`*` 表示所有 | `[]` |
| `groupPolicy` | 群组消息策略 | 因频道而异 |

## 频道管理命令

```bash
# 查看频道状态
nanobot channels status

# 登录频道（扫码等）
nanobot channels login
```

## 常见问题

### QQ 机器人不回复

1. 检查 `appId` 和 `secret` 是否正确
2. 检查 `allowFrom` 是否包含发送者
3. 确认机器人已在 QQ 开放平台上线
4. 查看日志是否有错误

### 频道启动失败

1. 检查端口是否被占用
2. 检查 token/密钥是否正确
3. 查看日志：`cat ~/.nanobot/nanobot.log`

### 多频道冲突

每个频道使用不同的端口和连接方式，一般不会冲突。如果 gateway 端口被占用，修改 `gateway.port`。
