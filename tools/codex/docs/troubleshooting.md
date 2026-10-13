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

#### Linux 报 `bwrap: setting up uid map: Permission denied`

Ubuntu 24.04+ 默认设置 `kernel.apparmor_restrict_unprivileged_userns = 1`，会拒绝一切未通过 AppArmor profile 声明 `userns` 权限的程序创建非特权 user namespace。Codex 的 Linux 沙箱依赖系统 `bwrap`，因此创建沙箱失败，典型报错：

```
bwrap: setting up uid map: Permission denied
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
```

诊断：

```bash
cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns   # 1 = 已开启限制
unshare --user --map-root-user echo ok                       # 报 Operation not permitted 即命中此问题
cat /sys/kernel/security/apparmor/profiles | grep bwrap      # 无输出说明未给 bwrap 放行
```

修复：只为 `bwrap` 放行 `userns`，保留全局限制（与 Ubuntu 给 `chrome`/`firefox` 的官方做法一致）：

```bash
sudo tee /etc/apparmor.d/bwrap >/dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile bwrap /usr/bin/bwrap flags=(unconfined) {
  userns,
  include if exists <local/bwrap>
}
EOF
sudo apparmor_parser -r /etc/apparmor.d/bwrap
```

验证：

```bash
bwrap --ro-bind / / --dev /dev --proc /proc echo ok     # 期望输出 ok
codex sandbox -- echo ok                                # 期望输出 ok
```

profile 文件落在 `/etc/apparmor.d/` 下，`apparmor.service` 开机自动加载，重启后仍生效。

> 备选（不推荐）：在 `/etc/sysctl.d/20-apparmor.conf` 写入 `kernel.apparmor_restrict_unprivileged_userns = 0` 全局关闭限制，会同时削弱其他程序的安全性。
>
> 注意：Codex 走的是系统 `/usr/bin/bwrap`；若系统 bwrap 缺失而回退到自带的 `~/.codex/packages/standalone/*/codex-resources/bwrap`，需要给该路径再补一份 profile。

## 获取帮助

- [GitHub Issues](https://github.com/openai/codex/issues)
- [GitHub Discussions](https://github.com/openai/codex/discussions)
- 安全问题: security@openai.com
