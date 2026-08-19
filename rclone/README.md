# rclone

[rclone](https://rclone.org/) 是用于访问和管理云存储的命令行工具，支持复制、同步、挂载和文件列表等操作。本机已配置一个 PikPak 远程，并由 systemd 服务挂载到 `~/pik`。

本目录是 rclone 在项目内的**唯一落盘位置**（文档 + 脚本 + 服务单元副本，版本化、可恢复）。

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `README.md`（本文件） | 唯一 rclone 文档：环境、安装、日常操作、参数、排障 |
| `mount.sh` | 手动备用挂载脚本（参数自动读取服务单元，零漂移） |
| `systemd/rclone-pikpak.service` | 服务单元**落盘副本**，与 `/etc/systemd/system/` 同步 |

## 当前环境

| 项目 | 值 |
| --- | --- |
| rclone 版本 | `v1.60.1-DEV` |
| 远程名称 | `pik` |
| 配置文件 | `~/.config/rclone/rclone.conf` |
| 本地挂载点 | `~/pik` |
| 挂载方式 | systemd 服务 `rclone-pikpak.service`（已启用，开机自启） |
| 服务单元（运行时） | `/etc/systemd/system/rclone-pikpak.service`（**自包含，参数全部内联，单一事实来源**） |
| 服务单元（项目落盘） | `systemd/rclone-pikpak.service`（与 /etc 同步，改完记得回拷） |
| 手动备用脚本 | `mount.sh`（参数自动读取服务单元，零漂移） |
| 日志文件 | `~/rclone_pikpak.log` |
| 依赖配置 | `/etc/fuse.conf` 已开启 `user_allow_other`（供 `--allow-other`） |

> 配置文件包含认证信息，不要提交到 Git、发送给他人或直接粘贴到日志中。

## 架构

```
/etc/systemd/system/rclone-pikpak.service   ← 运行时唯一事实来源
        │ 安装/同步            │ 参数解析
        ▼                     ▼
  systemd/rclone-pikpak.service (落盘)   mount.sh (手动备用)
        │
        ▼
rclone mount pik: /home/ubuntu/pik（后台常驻，开机自启、崩溃自拉起）
```

## 快速检查

```bash
# 查看版本和已配置的远程名称
rclone version
rclone listremotes

# 测试远程是否可访问；只读取目录
rclone lsd pik:

# 查看指定目录下的文件
rclone ls pik:"My Upload"

# 检查挂载是否在线
systemctl status rclone-pikpak
findmnt ~/pik
ls ~/pik
```

## 挂载 PikPak（systemd 服务，推荐）

```bash
# 查看状态
systemctl status rclone-pikpak

# 重启（修改参数后生效）
sudo systemctl restart rclone-pikpak

# 停止 / 启动 / 禁用自启
sudo systemctl stop rclone-pikpak
sudo systemctl start rclone-pikpak
sudo systemctl disable rclone-pikpak
```

### 服务单元内容（参数内联，单一事实来源）

```ini
[Unit]
Description=Rclone PikPak Mount
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Environment=HOME=/home/ubuntu
# 启动前：确保挂载点存在；清理可能残留的死挂载（失败不影响启动）
ExecStartPre=/usr/bin/bash -c "mkdir -p /home/ubuntu/pik && (fusermount3 -u /home/ubuntu/pik || true)"
# 所有挂载参数集中在此，修改后 daemon-reload && restart 生效
ExecStart=/usr/bin/rclone mount pik: /home/ubuntu/pik \
    --vfs-cache-mode full \
    --vfs-cache-max-size 10G \
    --vfs-cache-max-age 2h \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 1G \
    --vfs-read-ahead 256M \
    --buffer-size 128M \
    --dir-cache-time 5m \
    --poll-interval 30s \
    --attr-timeout 1s \
    --allow-other \
    --umask 000 \
    --log-file /home/ubuntu/rclone_pikpak.log \
    --log-level INFO
Restart=on-failure
RestartSec=10
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
```

要点：

- **参数只在此处维护**：修改挂载参数只需编辑这个文件，然后 `sudo systemctl daemon-reload && sudo systemctl restart rclone-pikpak`。
- `ExecStartPre` 每次启动前清理可能的死挂载（`fusermount3 -u` 失败忽略，不影响启动）。
- `Restart=on-failure`：rclone 异常退出后 10 秒自动拉起。
- `OOMScoreAdjust=-500`：1.6G 内存小机器上防 OOM killer 优先杀掉 rclone。
- 主进程直接是 rclone（无中间脚本），日志/存活检测均由 systemd 直接管理。

### 手动后台挂载（临时备用，systemd 异常时使用）

```bash
bash mount.sh
```

脚本会**自动解析服务单元中的参数**（保证与系统服务完全一致），追加 `--daemon` 转后台后立即返回。

## 挂载参数说明（对应服务单元 ExecStart）

| 参数 | 值 | 说明 |
| --- | --- | --- |
| `--vfs-cache-mode` | `full` | 全缓存模式：本地缓存完整文件，读性能最佳 |
| `--vfs-cache-max-size` | `10G` | 缓存目录最大占用 10GB，防止磁盘爆满 |
| `--vfs-cache-max-age` | `2h` | 缓存文件最长保留 2 小时，自动清理旧块 |
| `--vfs-read-chunk-size` | `32M` | 每次请求块大小，平衡首帧延迟 |
| `--vfs-read-chunk-size-limit` | `1G` | 单次顺序预读上限，防止拖动进度条时无限下载 |
| `--vfs-read-ahead` | `256M` | 预读缓冲区，提升连续播放流畅度 |
| `--buffer-size` | `128M` | 内存传输缓冲区，加速大文件拷贝 |
| `--dir-cache-time` | `5m` | 目录列表缓存 5 分钟，自动过期后重新拉取 |
| `--poll-interval` | `30s` | 每 30 秒轮询远端变更（PikPak WebDAV 不支持轮询，已自动忽略） |
| `--attr-timeout` | `1s` | 文件属性缓存仅 1 秒，`ls` 立即看到最新信息 |
| `--allow-other` | — | 允许其他用户（SMB/Docker）访问挂载点，需 `/etc/fuse.conf` 开 `user_allow_other` |
| `--umask` | `000` | 挂载目录权限 777，读写无限制 |
| `--log-file` / `--log-level` | `~/rclone_pikpak.log` / `INFO` | 日志文件与等级；排障可改 `DEBUG` |

> 参数实际生效位置在服务单元 `ExecStart` 内，表中内容为其说明。手动脚本 `mount.sh` 不重复维护参数，启动时自动读取单元。
>
> 注意：PikPak WebDAV 后端不支持 `--poll-interval` 轮询，日志会提示
> `poll-interval is not supported by this remote`，目录自动刷新主要靠
> `--dir-cache-time 5m` 过期重拉实现。

## 修改参数

所有挂载参数集中在服务单元 `ExecStart`（缓存、预读、目录刷新等），手动脚本不重复维护：

```bash
# 1) 编辑运行时单元（以 /etc 为准）
sudo nano /etc/systemd/system/rclone-pikpak.service
sudo systemctl daemon-reload && sudo systemctl restart rclone-pikpak

# 2) 改完同步回项目落盘
sudo cp /etc/systemd/system/rclone-pikpak.service systemd/rclone-pikpak.service
```

## 卸载与重启

```bash
# 常规重启（推荐，会自动先清理死挂载再挂载）
sudo systemctl restart rclone-pikpak

# 仅卸载（不停止服务，不推荐直接这样操作）
sudo systemctl stop rclone-pikpak
fusermount3 -u ~/pik

# 确认是否仍有挂载
findmnt ~/pik
```

如果目录忙，可先关闭正在访问 `~/pik` 的程序，再重试卸载。必要时查看进程：

```bash
pgrep -af 'rclone mount pik:'
```

## 安装 / 恢复（新机器）

```bash
# 1. 前提：rclone 已安装、已配置远程 pik（rclone config）
#    --allow-other 需要 /etc/fuse.conf 中启用 user_allow_other
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf

# 2. 安装服务单元
sudo cp systemd/rclone-pikpak.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now rclone-pikpak

# 3. 验证
systemctl status rclone-pikpak
findmnt ~/pik
ls ~/pik
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
tail -50 ~/rclone_pikpak.log

# 持续查看日志
tail -f ~/rclone_pikpak.log

# 或查看 systemd 服务日志（含服务生命周期事件）
journalctl -u rclone-pikpak -n 50
journalctl -u rclone-pikpak -f

# 临时使用详细日志测试
rclone lsd pik: -vv
```

常见问题：

1. **认证失败**：运行 `rclone config` 检查或重新配置 `pik`，不要把密码/token 写入脚本。
2. **目录内容未及时更新**：等待 `--dir-cache-time`（5 分钟）到期，或重启挂载；可按需缩短缓存时间。
3. **写入失败或文件打开异常**：确认使用了 `--vfs-cache-mode full`，并检查本地磁盘空间（缓存上限 10G）。
4. **挂载目录不存在**：脚本会自动 `mkdir -p ~/pik`；手动挂载时需先创建。
5. **`allow_other` 挂载报错**：`fusermount: option allow_other only allowed if 'user_allow_other' is set in /etc/fuse.conf` → 取消 `/etc/fuse.conf` 中 `user_allow_other` 一行的注释。
6. **服务起不来，日志显示 FUSE 错误**：先 `sudo systemctl restart` 让 `ExecStartPre` 清掉死挂载；仍失败再查 `journalctl -u rclone-pikpak -n 50`。
7. **网络不稳定**：查看日志，适当增加超时和重试参数；避免在网络异常时使用高风险的 `sync` 或 `delete`。

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

## 关键设计决策

- **参数单一来源**：服务单元 `ExecStart` 内联全部参数，`mount.sh` 启动时自动解析该行，杜绝双份维护漂移。
- **手动备用**：仅 systemd 异常时 `bash mount.sh`（自动加 `--daemon` 转后台）。
- **守护策略**：`Restart=on-failure`（崩溃 10s 拉起）、`OOMScoreAdjust=-500`（1.6G 内存小机器防杀）、`ExecStartPre` 启动前清理死挂载。
- **流媒体取向**：`--vfs-cache-mode full` + 10G/2h 缓存边界、256M 预读、5 分钟目录刷新、`allow_other` 支持 SMB/Docker 访问。

## 参考资料

- [rclone 官方文档](https://rclone.org/docs/)
- [rclone mount](https://rclone.org/commands/rclone_mount/)
- [VFS 文件缓存](https://rclone.org/commands/rclone_mount/#vfs-file-caching)
- [PikPak 后端说明](https://rclone.org/pikpak/)