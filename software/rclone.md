# rclone

[rclone](https://rclone.org/) 是用于访问和管理云存储的命令行工具，支持复制、同步、挂载和文件列表等操作。本机已配置一个 PikPak 远程，并挂载到 `~/pik`。

## 当前环境

| 项目 | 值 |
| --- | --- |
| rclone 版本 | `v1.60.1-DEV` |
| 远程名称 | `pik` |
| 配置文件 | `~/.config/rclone/rclone.conf` |
| 本地挂载点 | `~/pik` |
| 日志文件 | `~/.cache/rclone-pik.log` |

> 配置文件包含认证信息，不要提交到 Git、发送给他人或直接粘贴到日志中。

## 快速检查

```bash
# 查看版本和已配置的远程名称
rclone version
rclone listremotes

# 测试远程是否可访问；只读取目录
rclone lsd pik:

# 查看指定目录下的文件
rclone ls pik:"My Upload"
```

## 挂载 PikPak

### 前台运行

适合调试，按 `Ctrl-C` 停止：

```bash
mkdir -p ~/pik
rclone mount pik: ~/pik \
  --vfs-cache-mode full \
  --dir-cache-time 10m \
  --poll-interval 1m \
  --log-level INFO
```

### 后台运行（当前使用方式）

```bash
mkdir -p ~/pik
nohup rclone mount pik: ~/pik \
  --vfs-cache-mode full \
  --dir-cache-time 10m \
  --poll-interval 1m \
  --log-file ~/.cache/rclone-pik.log \
  --log-level INFO \
  >/dev/null 2>&1 &
```

检查挂载状态：

```bash
mountpoint ~/pik
findmnt -T ~/pik
ls ~/pik
```

## 挂载参数说明

- `pik:`：rclone 配置中的远程名称。
- `~/pik`：本地 FUSE 挂载目录，目录必须存在。
- `--vfs-cache-mode full`：启用完整 VFS 缓存，改善写入、随机读写和部分应用兼容性；会占用本地磁盘空间。
- `--dir-cache-time 10m`：目录列表缓存 10 分钟，减少请求；远端新增文件可能不会立即显示。
- `--poll-interval 1m`：定期检查远端变化。后端不支持时不会替代目录缓存刷新。
- `--log-file ~/.cache/rclone-pik.log`：把日志保存到文件。
- `--log-level INFO`：记录常规信息；排障时可改为 `DEBUG` 或 `-vv`。
- `nohup ... &`：让挂载在后台运行，并在终端退出后继续运行。

## 卸载与重启

```bash
# 卸载
fusermount3 -u ~/pik

# 确认是否仍有挂载
mountpoint ~/pik

# 重新挂载：先卸载，再执行后台挂载命令
```

如果目录忙，可先关闭正在访问 `~/pik` 的程序，再重试卸载。必要时查看进程：

```bash
pgrep -af 'rclone mount pik:'
```

## 常用文件操作

```bash
# 列出目录
rclone lsd pik:

# 复制本地文件到远程
rclone copy ./file.txt pik:"My Upload" -P

# 从远程复制到本地
rclone copy pik:"My Upload/file.txt" ./ -P

# 移动文件
rclone move ./local-dir pik:"My Upload" -P

# 删除前先模拟；确认无误后去掉 --dry-run
rclone delete pik:"My Upload/old-dir" --dry-run
rclone delete pik:"My Upload/old-dir"
```

`copy` 不会删除目标端多余文件；需要镜像同步时才使用 `sync`，并务必先执行 `--dry-run`：

```bash
rclone sync ./local-dir pik:"My Upload" --dry-run -P
```

## 日志与排障

```bash
# 查看最近日志
tail -50 ~/.cache/rclone-pik.log

# 持续查看日志
tail -f ~/.cache/rclone-pik.log

# 临时使用详细日志测试
rclone lsd pik: -vv
```

常见问题：

1. **认证失败**：运行 `rclone config` 检查或重新配置 `pik`，不要把密码/token 写入脚本。
2. **目录内容未及时更新**：等待 `--dir-cache-time` 到期，或重启挂载；可按需缩短缓存时间。
3. **写入失败或文件打开异常**：确认使用了 `--vfs-cache-mode full`，并检查本地磁盘空间。
4. **挂载目录不存在**：先执行 `mkdir -p ~/pik`。
5. **网络不稳定**：查看日志，适当增加超时和重试参数；避免在网络异常时使用高风险的 `sync` 或 `delete`。

## 配置与安全

查看配置文件位置：

```bash
rclone config file
```

交互式管理远程：

```bash
rclone config
```

不要使用 `rclone config show`、`cat ~/.config/rclone/rclone.conf` 等方式把完整配置输出到公共终端或聊天记录。备份配置时应限制文件权限：

```bash
chmod 600 ~/.config/rclone/rclone.conf
```

## 参考资料

- [rclone 官方文档](https://rclone.org/docs/)
- [rclone mount](https://rclone.org/commands/rclone_mount/)
- [VFS 文件缓存](https://rclone.org/commands/rclone_mount/#vfs-file-caching)
- [PikPak 后端说明](https://rclone.org/pikpak/)
