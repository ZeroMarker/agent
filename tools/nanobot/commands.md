# 命令参考

## 主命令

```bash
nanobot [OPTIONS] COMMAND [ARGS]...
```

全局选项：
- `-v, --version` — 显示版本
- `--install-completion` — 安装 shell 补全
- `--show-completion` — 显示 shell 补全脚本
- `-h, --help` — 显示帮助

## 核心命令

### onboard — 初始化配置

```bash
nanobot onboard
```

交互式初始化向导，创建配置文件、工作空间、记忆目录。

### gateway — 启动网关

启动 nanobot 网关，包含所有已配置的频道、心跳、定时任务。

```bash
nanobot gateway -c ~/.nanobot/config.json
nanobot gateway -p 18790 -c ~/.nanobot/config.json  # 指定端口
nanobot gateway -v -c ~/.nanobot/config.json         # 详细日志
```

选项：
- `-p, --port` — 网关端口
- `-w, --workspace` — 工作空间目录
- `-v, --verbose` — 详细输出
- `-c, --config` — 配置文件路径

### agent — 直接对话

```bash
nanobot agent -m "你好" -c ~/.nanobot/config.json
nanobot agent -c ~/.nanobot/config.json              # 交互模式
nanobot agent -s my-session -m "你好" -c ~/.nanobot/config.json  # 指定会话
```

选项：
- `-m, --message` — 发送的消息
- `-s, --session` — 会话 ID（默认 `cli:direct`）
- `-w, --workspace` — 工作空间目录
- `-c, --config` — 配置文件路径
- `--markdown / --no-markdown` — 是否渲染 Markdown（默认渲染）
- `--logs / --no-logs` — 是否显示运行时日志

### serve — 启动 API 服务器

启动 OpenAI 兼容的 API 服务器（`/v1/chat/completions`）。

```bash
nanobot serve -c ~/.nanobot/config.json
nanobot serve -p 8900 -c ~/.nanobot/config.json      # 指定端口
nanobot serve -H 0.0.0.0 -c ~/.nanobot/config.json   # 监听所有接口
```

选项：
- `-p, --port` — API 服务器端口
- `-H, --host` — 绑定地址
- `-t, --timeout` — 请求超时（秒）
- `-v, --verbose` — 详细输出
- `-w, --workspace` — 工作空间目录
- `-c, --config` — 配置文件路径

### status — 查看状态

```bash
nanobot status
```

## 频道管理

### channels — 频道命令

```bash
nanobot channels status   # 查看频道状态
nanobot channels login    # 登录频道（扫码等）
```

## 其他命令

### plugins — 插件管理

```bash
nanobot plugins list      # 列出插件
```

### provider — 提供者管理

```bash
nanobot provider list     # 列出提供者
```
