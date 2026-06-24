# 故障排查

## 服务管理

### 服务无法启动

```bash
# 查看服务状态
zeroclaw service status

# 查看日志
zeroclaw service logs

# 检查配置
zeroclaw config list

# 验证配置
zeroclaw config migrate
```

### 配置错误

```
Error: Failed to deserialize config file
```

原因：配置文件格式错误或使用了无效值。

```bash
# 检查配置 Schema
zeroclaw config schema

# 重新生成配置
zeroclaw config generate > config.toml

# 迁移配置版本
zeroclaw config migrate
```

### 权限级别无效

```
Error: unknown variant `semi_autonomous`, expected one of `readonly`, `supervised`, `full`
```

修复：
```bash
# 正确的值
zeroclaw config set autonomy.level full
```

## 频道问题

### QQ 机器人不回复

1. **检查配置**：
   ```bash
   zeroclaw config get channels.qq.enabled
   zeroclaw config get channels.qq.app_id
   ```

2. **检查日志**：
   ```bash
   zeroclaw service logs | grep -i qq
   ```

3. **检查 daemon_state**：
   ```bash
   cat ~/.zeroclaw/daemon_state.json
   ```
   确认 `channel:qq` 的 `status` 为 `"ok"`。

4. **常见原因**：
   - `app_id` 或 `app_secret` 错误
   - 机器人未上线
   - `allowed_users` 不包含发送者
   - 频道未编译（需源码编译）

### DingTalk 机器人不回复

1. **检查配置**：
   ```bash
   zeroclaw config get channels.dingtalk.enabled
   ```

2. **检查日志**：
   ```bash
   zeroclaw service logs | grep -i dingtalk
   ```

3. **常见原因**：
   - `client_id` 或 `client_secret` 错误
   - 机器人未发布
   - IP 白名单未配置

### 频道编译缺失

```
Configured but not compiled in this binary:
  DingTalk  🚫 configured, not compiled
```

**解决方案**：源码编译完整版。

```bash
# 在有足够内存的机器上编译
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
cargo build --release --features channels-full

# 上传到服务器
scp target/release/zeroclaw user@server:~/.cargo/bin/zeroclaw

# 重启服务
ssh user@server "zeroclaw service restart"
```

> **注意**：1GB 内存的机器编译会很慢（30+ 分钟），建议在本地编译后上传。

## 模型问题

### 模型不响应

```bash
# 测试模型
zeroclaw agent -a default -m "你好"

# 检查模型可用性
zeroclaw doctor models
```

### API 密钥错误

```bash
# 检查密钥
zeroclaw config get providers.models.deepseek.api_key

# 重新设置
zeroclaw config set providers.models.deepseek.api_key
```

### 超时

```bash
# 增加超时时间
zeroclaw config set providers.models.deepseek.timeout_secs 300
```

## 内存问题

### 内存不足

```
error: process didn't exit successfully: signal: 9 (SIGKILL)
```

原因：编译或运行时内存不足。

**解决方案**：
1. 增加 swap 空间
2. 在其他机器编译后上传
3. 减少 `max_concurrent` 设置

### 添加 Swap

```bash
# 创建 2GB swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久启用
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 权限问题

### 命令被拒绝

```
Error: Command not in allowed_commands
```

修复：
```bash
# 添加命令到白名单
# 编辑 config.toml 的 allowed_commands 列表
```

### 路径被禁止

```
Error: Path is in forbidden_paths
```

修复：
```bash
# 从 forbidden_paths 移除该路径
# 或使用 --allow-degraded-security 启动
zeroclaw daemon --allow-degraded-security
```

## 二进制文件问题

### 二进制文件丢失

```
bash: /root/.cargo/bin/zeroclaw: No such file or directory
```

**原因**：`rm` 命令在白名单中，agent 删除了二进制文件。

**解决方案**：
```bash
# 重新安装
curl -fsSL https://github.com/zeroclaw-labs/zeroclaw/releases/download/v0.8.1/install.sh | bash

# 或从备份恢复
cp ~/.cargo/bin/zeroclaw.bak ~/.cargo/bin/zeroclaw
```

**预防措施**：
1. 不要把 `rm` 加入 `allowed_commands`
2. 备份二进制文件：`cp ~/.cargo/bin/zeroclaw ~/.cargo/bin/zeroclaw.bak`

### 版本不匹配

```bash
# 检查版本
zeroclaw --version

# 更新
zeroclaw update
```

## 网络问题

### Gateway 无法访问

```bash
# 检查端口
ss -tlnp | grep 42617

# 检查防火墙
sudo ufw status
sudo ufw allow 42617

# 检查配置
zeroclaw config get gateway.host
zeroclaw config get gateway.port
```

### Webhook 调用失败

```bash
# 配对
curl -X POST http://127.0.0.1:42617/pair -H "X-Pairing-Code: YOUR_CODE"

# 发送消息
curl -X POST http://127.0.0.1:42617/webhook \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
```

## 日志调试

### 启用详细日志

```bash
# 启动时启用详细日志
zeroclaw daemon --log-level debug -v

# 或修改服务配置
zeroclaw service stop
# 编辑 systemd service 文件添加 --log-level debug
zeroclaw service start
```

### 查看实时日志

```bash
# 服务日志
zeroclaw service logs

# 或直接查看 journalctl
journalctl -u zeroclaw -f
```

## 常用诊断命令

```bash
# 完整状态
zeroclaw status

# 诊断
zeroclaw doctor

# 安全状态
zeroclaw security status

# 自检
zeroclaw self-test

# 频道健康检查
zeroclaw channel doctor

# 模型可用性
zeroclaw doctor models
```
