# 快速开始

## 安装

```bash
# 预编译版（基础频道）
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash

# 源码编译版（全频道，包含 DingTalk/QQ）
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash -s -- --source --preset full
```

## 初始化

```bash
# 运行初始化向导
zeroclaw quickstart
```

向导会引导你配置：
1. 工作空间
2. 模型提供者（DeepSeek/OpenAI/Anthropic 等）
3. 频道（QQ/Telegram/Discord 等）
4. 记忆系统
5. 硬件外设
6. 网络隧道

## 配置模型

### DeepSeek（推荐，国内访问快）

```toml
[providers]
fallback = "deepseek"

[providers.models.deepseek]
model = "deepseek-v4-flash"
api_key = "your-api-key"
max_tokens = 4096
temperature = 0.7
```

### OpenAI

```toml
[providers.models.openai]
model = "gpt-4o"
api_key = "your-api-key"
```

### Anthropic

```toml
[providers.models.anthropic]
model = "claude-sonnet-4-20250514"
api_key = "your-api-key"
```

## 配置频道

### QQ 机器人

```toml
[channels.qq]
enabled = true
allowed_users = ["*"]
app_id = "your-app-id"
app_secret = "your-app-secret"
```

获取 `app_id` 和 `app_secret`：[QQ 开放平台](https://q.qq.com/)

### DingTalk 机器人

```toml
[channels.dingtalk]
enabled = true
allowed_users = ["*"]
client_id = "your-client-id"
client_secret = "your-client-secret"
```

获取 `client_id` 和 `client_secret`：[钉钉开放平台](https://open.dingtalk.com/)

## 启动服务

```bash
# 注册为系统服务（开机自启）
zeroclaw service install

# 启动服务
zeroclaw service start

# 查看状态
zeroclaw status

# 查看日志
zeroclaw service logs
```

## 测试

```bash
# 测试模型响应
zeroclaw agent -a default -m "你好"

# 测试频道
zeroclaw channel doctor

# 查看安全状态
zeroclaw security status
```

## 常用命令

```bash
# 服务管理
zeroclaw service start|stop|restart|status|logs

# 配置管理
zeroclaw config list|get|set|schema

# 频道管理
zeroclaw channel list|doctor|send

# 定时任务
zeroclaw cron list|add|remove

# 记忆管理
zeroclaw memory list|stats|clear

# 诊断
zeroclaw status|doctor|security status
```

## 权限配置

默认权限较严格，根据需要调整：

```toml
[autonomy]
level = "full"                           # 完全自主
workspace_only = false                   # 不限制工作空间
max_actions_per_hour = 100               # 增加操作限制
require_approval_for_medium_risk = false  # 中风险无需审批
block_high_risk_commands = false         # 允许高风险命令
```

详见 [安全与权限](security.md)。

## 下一步

- [命令参考](commands.md) - 所有 CLI 命令
- [配置指南](config.md) - 完整配置说明
- [频道配置](channels.md) - 更多频道设置
- [故障排查](troubleshooting.md) - 常见问题
