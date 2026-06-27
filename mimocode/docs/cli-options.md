# 命令行参数

## tui

```bash
mimo [project]
```

| 标志 | 简写 | 说明 |
|------|------|------|
| `--continue` | `-c` | 继续上一个会话 |
| `--session` | `-s` | 会话 ID |
| `--fork` | — | 分叉会话 |
| `--prompt` | — | 初始提示词 |
| `--model` | `-m` | 模型 provider/model |
| `--agent` | — | 代理 |

## run

```bash
mimo run [message..]
```

| 标志 | 简写 | 说明 |
|------|------|------|
| `--command` | — | 运行命令 |
| `--continue` | `-c` | 继续会话 |
| `--share` | — | 分享会话 |
| `--model` | `-m` | 模型 |
| `--file` | `-f` | 附加文件 |
| `--format` | — | default/json |
| `--dangerously-skip-permissions` | — | 自动批准权限 |

## serve / web

```bash
mimo serve
mimo web
```

| 标志 | 说明 |
|------|------|
| `--port` | 监听端口 |
| `--hostname` | 主机名 |
| `--mdns` | 启用 mDNS |

## 全局标志

| 标志 | 说明 |
|------|------|
| `--help` | 帮助 |
| `--version` | 版本 |
| `--print-logs` | 日志输出到 stderr |
| `--log-level` | DEBUG/INFO/WARN/ERROR |
