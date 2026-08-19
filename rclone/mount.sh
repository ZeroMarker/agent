#!/bin/bash
# ====================================================
#  Rclone PikPak 手动备用挂载脚本
#  ⚠️  正式挂载由 systemd 服务托管：
#         systemctl status/restart rclone-pikpak
#      本脚本仅供临时手动挂载（系统服务异常时不阻塞使用）。
#
#  设计要点：
#  - 参数【不在此处维护】——统一以服务单元
#    /etc/systemd/system/rclone-pikpak.service 的 ExecStart 为准，
#    此处启动时自动解析该行（含续行），保证与系统服务完全一致、零漂移。
#  - 追加 --daemon 转入后台守护进程，脚本立即返回。
#  - 同样依赖 /etc/fuse.conf 的 user_allow_other（--allow-other 需要）。
#
#  日志：$HOME/rclone_pikpak.log（tail -f 实时查看）
# ====================================================

MOUNT_POINT="${HOME:-/root}/pik"
SERVICE_FILE="/etc/systemd/system/rclone-pikpak.service"

# 创建挂载点（如果不存在）
mkdir -p "$MOUNT_POINT" 2>/dev/null || true

# 从服务单元提取 ExecStart 的 rclone 挂载命令（合并续行、去首尾空白）
# 示例：ExecStart=/usr/bin/rclone mount pik: /home/ubuntu/pik \
#           --vfs-cache-mode full \
#           ...
RCLONE_CMD=$(awk '
  /^ExecStart=/ {
    sub(/^ExecStart=/, "");
    line = $0;
    while (line ~ /\\$/) {
      sub(/\\$/, "", line);
      if ((getline next_line) > 0) line = line " " next_line;
    }
    gsub(/  +/, " ", line);   # 压缩续行缩进为单空格
    gsub(/^ | $/, "", line);  # 去首尾空白
    print line;
    exit;
  }
' "$SERVICE_FILE")

if [ -z "$RCLONE_CMD" ]; then
    echo "❌ 未能从 $SERVICE_FILE 解析出 rclone 命令"
    exit 1
fi

echo "使用服务单元参数：$RCLONE_CMD"
# 手动运行：追加 --daemon 转后台守护进程（不在参数里重复维护）
eval "$RCLONE_CMD --daemon"

if [ $? -eq 0 ]; then
    echo "✅ PikPak 已手动挂载到 $MOUNT_POINT（后台守护进程）"
    echo "📁 正式方式仍为 systemd：systemctl status rclone-pikpak"
    echo "🔍 查看实时日志：tail -f ${HOME:-/root}/rclone_pikpak.log"
else
    echo "❌ 挂载失败，请检查日志：${HOME:-/root}/rclone_pikpak.log"
fi