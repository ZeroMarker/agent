# 故障排除

## 日志

```bash
codex -c log_dir=./.codex-log
tail -F ./.codex-log/codex-tui.log
```

非交互模式默认 `RUST_LOG=error`，消息内联输出。

## 常见问题

### 安装问题

1. 确认系统要求（macOS 12+、Ubuntu 20.04+、Windows 11 WSL2）
2. 检查 Git 版本（2.23+）
3. 确认内存充足（4GB 最低）

### 认证问题

1. 尝试重新登录 ChatGPT
2. 检查 API Key 有效性
3. 确认网络可访问 OpenAI API

### 构建问题

```bash
# 清理并重新构建
cargo clean
cargo build

# 更新依赖
cargo update
```

### 沙箱问题

- Linux: 确认 `bwrap` 可用
- macOS: 应使用 Seatbelt (`/usr/bin/sandbox-exec`)
- Windows: 需要 WSL2

## 获取帮助

- [GitHub Issues](https://github.com/openai/codex/issues)
- [GitHub Discussions](https://github.com/openai/codex/discussions)
- 安全问题: security@openai.com
