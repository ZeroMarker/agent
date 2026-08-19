# rclone PikPak 挂载专项

本目录是 rclone PikPak 挂载的**项目内落盘**（版本化、可恢复），运行中的唯一事实来源是 systemd 服务单元。

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `README.md` | 本说明 |
| `mount.sh` | 手动备用挂载脚本（参数自动读取服务单元，零漂移） |
| `systemd/rclone-pikpak.service` | 服务单元**落盘副本**，与 `/etc/systemd/system/` 同步 |
| `../software/rclone.md` | 通用 rclone 使用文档（命令、排障、安全） |

## 架构

```
/system/etc/systemd/system/rclone-pikpak.service   ← 运行时唯一事实来源
        │ 安装/同步             │ 参数解析
        ▼                      ▼
  systemd/rclone-pikpak.service (落盘)   mount.sh (手动备用)
        │
        ▼
rclone mount pik: /home/ubuntu/pik（后台常驻，开机自启、崩溃自拉起）
```

## 快速上手

已安装机器上日常操作：

```bash
systemctl status rclone-pikpak      # 状态
sudo systemctl restart rclone-pikpak  # 重启
journalctl -u rclone-pikpak -f      # 系统日志
tail -f ~/rclone_pikpak.log         # rclone 日志
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

## 修改参数

所有挂载参数集中在服务单元 `ExecStart`（缓存、预读、目录刷新等），手动脚本不重复维护：

```bash
# 编辑 /etc/systemd/system/rclone-pikpak.service 的 ExecStart 行
sudo nano /etc/systemd/system/rclone-pikpak.service
sudo systemctl daemon-reload && sudo systemctl restart rclone-pikpak

# 改完同步回项目落盘
sudo cp /etc/systemd/system/rclone-pikpak.service systemd/rclone-pikpak.service
```

## 关键设计决策

- **参数单一来源**：服务单元 `ExecStart` 内联全部参数，`mount.sh` 启动时自动解析该行，杜绝双份维护漂移。
- **手动备用**：仅 systemd 异常时 `bash mount.sh`（自动加 `--daemon` 转后台）。
- **守护策略**：`Restart=on-failure`（崩溃 10s 拉起）、`OOMScoreAdjust=-500`（1.6G 内存小机器防杀）、`ExecStartPre` 启动前清理死挂载。
- **特性**：`--vfs-cache-mode full` + 10G/2h 缓存边界、256M 预读、5 分钟目录刷新、`allow_other` 支持 SMB/Docker 访问。