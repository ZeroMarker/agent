# 命令行参考

## 基本命令

```bash
codex                    # 启动 TUI
codex "prompt"           # 使用提示启动
codex app                # 启动桌面应用
codex exec               # 非交互模式
```

## 配置标志

```bash
-c <key>=<value>         # 设置配置项
```

## MCP 管理

```bash
codex mcp add <name> --url <url>
codex mcp list
codex mcp auth <name>
codex mcp logout <name>
codex mcp debug <name>
```

## 升级

```bash
codex upgrade
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `RUST_LOG` | 日志级别配置 |
| `CODEX_SANDBOX_NETWORK_DISABLED` | 沙箱网络禁用标记 |
| `CODEX_SANDBOX` | 沙箱类型（如 `seatbelt`） |
