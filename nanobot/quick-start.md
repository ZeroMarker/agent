# 快速开始

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/HKUDS/nanobot/main/scripts/install.sh | sh
```

安装完成后需要将 `~/.local/bin` 加入 PATH：

```bash
export PATH=$PATH:~/.local/bin
```

## 初始化

```bash
nanobot onboard
```

这会创建：
- `~/.nanobot/config.json` — 主配置文件
- `~/.nanobot/SOUL.md` — AI 人格设定
- `~/.nanobot/AGENTS.md` — Agent 配置
- `~/.nanobot/memory/` — 记忆目录
- `~/.nanobot/workspace/` — 工作空间

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
nanobot gateway -c ~/.nanobot/config.json
```

### 启动 API 服务器（OpenAI 兼容）

```bash
nanobot serve -c ~/.nanobot/config.json
```

### 直接对话测试

```bash
nanobot agent -m "你好" -c ~/.nanobot/config.json
```

## 验证

```bash
# 测试 agent
nanobot agent -m "你好" -c ~/.nanobot/config.json

# 查看状态
nanobot status

# 查看频道状态
nanobot channels status
```

## 下一步

- [命令参考](commands.md) - 所有 CLI 命令
- [配置指南](config.md) - 完整配置说明
- [频道配置](channels.md) - 更多频道设置
- [故障排查](troubleshooting.md) - 常见问题
