# 故障排查

## 安装问题

### Python 版本不满足

```
Error: Python >= 3.11 is required
```

**解决方案**：升级 Python 到 3.11+。

### venv 创建失败

```
Error: ensurepip is not available
```

**解决方案**：

```bash
# Debian/Ubuntu
apt install python3.12-venv

# CentOS/RHEL
yum install python3-venv
```

### pip 安装失败（PEP 668）

```
error: externally-managed-environment
```

**解决方案**：

```bash
# 使用 --break-system-packages
pip3 install --break-system-packages nanobot-ai

# 或使用安装脚本（推荐）
curl -fsSL https://raw.githubusercontent.com/HKUDS/nanobot/main/scripts/install.sh | sh
```

## 启动问题

### 端口被占用

```
OSError: [Errno 98] error while attempting to bind on address ('127.0.0.1', 18790): address already in use
```

**解决方案**：

```bash
# 查看占用端口的进程
ss -tlnp | grep 18790

# 杀掉占用进程
kill <PID>

# 或修改 gateway 端口
# 编辑 config.json: "gateway": { "port": 18791 }
```

### 配置文件不存在

```
Error: Config file not found
```

**解决方案**：

```bash
# 初始化配置
nanobot onboard

# 或指定配置文件路径
nanobot gateway -c /path/to/config.json
```

## 模型问题

### API Key 错误

```
Error: {'message': 'Invalid API key'}
```

**解决方案**：

```bash
# 检查配置
cat ~/.nanobot/config.json | grep apiKey

# 重新设置
vi ~/.nanobot/config.json
```

### 模型名称错误

```
Error: The supported API model names are deepseek-v4-pro or deepseek-v4-flash, but you passed deepseek/deepseek-chat
```

**解决方案**：

使用正确的模型名称：
- DeepSeek: `deepseek-v4-flash` 或 `deepseek-v4-pro`
- OpenAI: `gpt-4o` 或 `gpt-4o-mini`
- Anthropic: `claude-sonnet-4-20250514`

### 超时

```
Error: Request timed out
```

**解决方案**：

```json
{
  "api": {
    "timeout": 300.0
  }
}
```

## 频道问题

### QQ 机器人不回复

1. **检查配置**：
   ```bash
   cat ~/.nanobot/config.json | python3 -c "import sys,json; c=json.load(sys.stdin); print(c['channels']['qq'])"
   ```

2. **检查日志**：
   ```bash
   tail -50 ~/.nanobot/nanobot.log
   ```

3. **常见原因**：
   - `appId` 或 `secret` 错误
   - `allowFrom` 不包含发送者
   - 机器人未在 QQ 开放平台上线

### Telegram 机器人不回复

1. 检查 token 是否正确
2. 确认 bot 已启动（发送 `/start`）
3. 如果使用 webhook，检查 URL 配置

### Discord 机器人不回复

1. 检查 token 是否正确
2. 确认 bot 已邀请到服务器
3. 检查 intents 配置

## 权限问题

### 命令执行被拒绝

```
Error: Command not allowed
```

**解决方案**：

```json
{
  "tools": {
    "exec": {
      "enable": true,
      "allowPatterns": ["*"],
      "denyPatterns": []
    },
    "restrictToWorkspace": false
  }
}
```

## 内存问题

### 内存不足

```
Error: Process killed (OOM)
```

**解决方案**：

1. 减少 `contextWindowTokens`
2. 减少 `maxMessages`
3. 增加 swap 空间

```bash
# 创建 2GB swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 日志调试

### 查看实时日志

```bash
tail -f ~/.nanobot/nanobot.log
```

### 启动时显示日志

```bash
nanobot agent -m "你好" -c ~/.nanobot/config.json --logs
```

## 常用诊断命令

```bash
# 查看状态
nanobot status

# 查看频道状态
nanobot channels status

# 测试 agent
nanobot agent -m "你好" -c ~/.nanobot/config.json

# 查看日志
tail -50 ~/.nanobot/nanobot.log
```
