# 故障排除

## 日志

- macOS/Linux: `~/.local/share/mimocode/log/`
- Windows: `%USERPROFILE%\.local\share\mimocode\log`

调试：`mimo --log-level DEBUG`

## 存储

- macOS/Linux: `~/.local/share/mimocode/`
- Windows: `%USERPROFILE%\.local\share\mimocode`

## 常见问题

### 无法启动

1. 检查日志
2. `mimo --print-logs`
3. `mimo upgrade`

### 身份验证问题

1. `/connect` 重新认证
2. 检查 API 密钥有效性
3. 检查网络连接

### 模型不可用

1. 检查提供商认证
2. 验证模型名称 `providerId/modelId`
3. `mimo models` 查看可用模型

### ProviderInitError

```bash
rm -rf ~/.local/share/mimocode
# 然后 /connect 重新认证
```

### AI_APICallError

```bash
rm -rf ~/.cache/mimocode
# 重启 MiMo Code
```

### Linux 复制/粘贴

```bash
# X11
apt install -y xclip
# Wayland
apt install -y wl-clipboard
```
