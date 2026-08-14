# 安全与权限

ZeroClaw 提供多层安全控制：权限级别、命令白名单、路径限制、沙箱、审批机制。

## 权限级别

```toml
[autonomy]
level = "full"  # readonly / supervised / full
```

| 级别 | 说明 | 适用场景 |
|------|------|----------|
| `readonly` | 只读，不能执行任何操作 | 仅查询 |
| `supervised` | 受监督，中/高风险需审批 | 日常使用 |
| `full` | 完全自主，无需审批 | 生产环境 |

## 命令白名单

```toml
[autonomy]
allowed_commands = [
    "git", "npm", "cargo", "ls", "cat", "grep", "find",
    "curl", "wget", "ssh", "docker", "systemctl", "ps", "kill",
    "chmod", "chown", "mkdir", "rm", "cp", "mv", "tar",
]
```

只有列表中的命令可以被执行。不在列表中的命令会被拒绝。

### 推荐白名单

**基础（只读）**：
```toml
allowed_commands = ["ls", "cat", "grep", "find", "echo", "pwd", "wc", "head", "tail", "date", "df", "du", "uname", "uptime", "hostname"]
```

**开发（包含构建工具）**：
```toml
allowed_commands = ["git", "npm", "cargo", "python", "python3", "pip", "node", "make", "gcc", "g++"]
```

**运维（包含系统管理）**：
```toml
allowed_commands = ["curl", "wget", "ssh", "scp", "docker", "systemctl", "ps", "kill", "chmod", "chown", "mkdir", "rm", "cp", "mv", "tar"]
```

## 路径限制

```toml
[autonomy]
forbidden_paths = [
    "/etc/shadow",      # 密码文件
    "/etc/gshadow",     # 组密码
    "~/.ssh/id_*",      # SSH 私钥
    "~/.gnupg",         # GPG 密钥
    "~/.aws/credentials", # AWS 凭证
]
```

被禁止的路径无法被读取或写入。

### 默认禁止路径

```toml
forbidden_paths = [
    "/etc", "/root", "/home", "/usr", "/bin", "/sbin",
    "/lib", "/opt", "/boot", "/dev", "/proc", "/sys",
    "/var", "/tmp", "~/.ssh", "~/.gnupg", "~/.aws", "~/.config",
]
```

> **警告**：默认配置非常严格。根据实际需要逐步放开。

## 操作审批

```toml
[autonomy]
require_approval_for_medium_risk = true   # 中风险需要审批
block_high_risk_commands = true           # 阻止高风险命令
max_actions_per_hour = 20                 # 每小时最大操作数
```

### 风险级别

- **低风险**：`file_read`, `memory_recall`, `web_search` 等
- **中风险**：`file_write`, `shell`, `http_request` 等
- **高风险**：`rm -rf`, `chmod 777`, 系统关键操作等

### 自动批准

```toml
auto_approve = [
    "file_read",
    "memory_recall",
    "web_search_tool",
    "web_fetch",
    "calculator",
    "glob_search",
    "content_search",
]
```

## 沙箱

```toml
[security.sandbox]
backend = "auto"  # auto / firejail / none

[security.resources]
max_memory_mb = 512        # 最大内存
max_cpu_time_seconds = 60  # 最大 CPU 时间
max_subprocesses = 10      # 最大子进程数
memory_monitoring = true   # 内存监控
```

## OTP 验证

```toml
[security.otp]
enabled = false
method = "totp"            # totp / hotp
token_ttl_secs = 30        # token 有效期
cache_valid_secs = 300     # 缓存有效期

gated_actions = [          # 需要 OTP 的操作
    "shell",
    "file_write",
    "browser_open",
]
```

## 紧急停止 (E-Stop)

```toml
[security.estop]
enabled = false
state_file = "/root/.zeroclaw/estop-state.json"
require_otp_to_resume = true
```

```bash
# 查看紧急停止状态
zeroclaw estop

# 激活紧急停止
zeroclaw estop engage

# 恢复
zeroclaw estop resume
```

## 审计日志

```toml
[security.audit]
enabled = true
log_path = "audit.log"
max_size_mb = 100
sign_events = false
```

## 费用控制

```toml
[cost]
enabled = true
daily_limit_usd = 10.0      # 每日限额
monthly_limit_usd = 100.0   # 每月限额
warn_at_percent = 80         # 警告阈值
allow_override = false       # 允许覆盖
```

## 安全检查命令

```bash
# 查看安全状态
zeroclaw security status

# 运行诊断
zeroclaw doctor

# 自检
zeroclaw self-test
```

## 最佳实践

1. **最小权限原则**：只开放必要的命令和路径
2. **分级管理**：不同环境使用不同权限级别
3. **审计日志**：始终启用审计日志
4. **费用控制**：设置合理的每日/每月限额
5. **紧急停止**：保留紧急停止机制
6. **定期审查**：定期检查 `zeroclaw security status`
