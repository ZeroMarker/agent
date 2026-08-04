# Nanobot Memory Optimization Strategy

## Overview

This document outlines strategies to prevent OOM kills and optimize nanobot memory usage on resource-constrained systems.

## Priority 1: System-Level Optimizations

### 1.1 Increase Swap Space

**Current**: 2 GB swap  
**Recommended**: 4-8 GB swap

```bash
# Create 4GB swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 1.2 Adjust Swappiness

**Current**: vm.swappiness = 10  
**Recommended**: vm.swappiness = 60

```bash
# Apply immediately
sudo sysctl vm.swappiness=60

# Make permanent
echo 'vm.swappiness=60' | sudo tee -a /etc/sysctl.conf
```

**Rationale**: Higher swappiness encourages kernel to swap out memory pages rather than killing processes.

### 1.3 Configure OOM Killer Behavior

```bash
# Enable OOM killing of allocating task (instead of heuristic)
sudo sysctl vm.oom_kill_allocating_task=1

# Make permanent
echo 'vm.oom_kill_allocating_task=1' | sudo tee -a /etc/sysctl.conf
```

## Priority 2: Nanobot Configuration

### 2.1 Reduce Memory Footprint

Edit `/root/.nanobot/config.json`:

```json
{
  "agents": {
    "defaults": {
      "contextWindowTokens": 32768,
      "maxTokens": 4096,
      "maxMessages": 60,
      "maxConcurrentSubagents": 1,
      "consolidationRatio": 0.3
    }
  }
}
```

**Changes**:
| Parameter | Before | After | Impact |
|-----------|--------|-------|--------|
| contextWindowTokens | 65536 | 32768 | -50% context memory |
| maxTokens | 8192 | 4096 | -50% output buffer |
| maxMessages | 120 | 60 | -50% history retention |
| consolidationRatio | 0.5 | 0.3 | More aggressive cleanup |

### 2.2 Limit File Download Buffering

For large file operations, use streaming approach:
- Avoid loading entire files into memory
- Use chunked downloads with curl/wget
- Set explicit file size limits

## Priority 3: Process Management

### 3.1 Systemd Service with Memory Limits

Create `/etc/systemd/system/nanobot.service`:

```ini
[Unit]
Description=Nanobot AI Assistant
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/root/.local/bin/nanobot serve
Restart=always
RestartSec=10
TimeoutStopSec=30

# Memory limits
MemoryMax=1G
MemoryHigh=800M

# OOM score adjustment
OOMScoreAdjust=-500

# Environment
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable nanobot
sudo systemctl start nanobot
```

### 3.2 Watchdog Script

Create `/usr/local/bin/nanobot-watchdog.sh`:

```bash
#!/bin/bash
# Nanobot Watchdog - Auto-restart on crash

LOG_FILE="/var/log/nanobot-watchdog.log"
CHECK_INTERVAL=30

while true; do
    if ! pgrep -f "nanobot serve" > /dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'): nanobot not running, restarting..." >> "$LOG_FILE"
        systemctl restart nanobot
    fi
    sleep "$CHECK_INTERVAL"
done
```

```bash
sudo chmod +x /usr/local/bin/nanobot-watchdog.sh

# Create systemd service for watchdog
sudo tee /etc/systemd/system/nanobot-watchdog.service << 'EOF'
[Unit]
Description=Nanobot Watchdog
After=nanobot.service

[Service]
Type=simple
ExecStart=/usr/local/bin/nanobot-watchdog.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nanobot-watchdog
sudo systemctl start nanobot-watchdog
```

## Priority 4: Monitoring

### 4.1 Memory Usage Alerts

Create `/usr/local/bin/nanobot-memory-monitor.sh`:

```bash
#!/bin/bash
# Monitor nanobot memory usage

THRESHOLD=800  # MB
LOG_FILE="/var/log/nanobot-memory.log"

while true; do
    PID=$(pgrep -f "nanobot serve")
    if [ -n "$PID" ]; then
        RSS=$(ps -o rss= -p "$PID" 2>/dev/null)
        RSS_MB=$((RSS / 1024))
        
        if [ "$RSS_MB" -gt "$THRESHOLD" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - nanobot using ${RSS_MB}MB (threshold: ${THRESHOLD}MB)" >> "$LOG_FILE"
            # Optional: send alert or restart
            # systemctl restart nanobot
        fi
    fi
    sleep 60
done
```

### 4.2 Log Rotation

Create `/etc/logrotate.d/nanobot`:

```
/var/log/nanobot-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

## Priority 5: Usage Guidelines

### 5.1 Avoid Concurrent Large Operations

**Don't**:
- Download multiple large files simultaneously
- Run complex analysis while downloading
- Accumulate excessive conversation history

**Do**:
- Process large files sequentially
- Clear temp files after operations
- Monitor memory before starting tasks

### 5.2 File Operation Best Practices

```bash
# Use streaming downloads
curl -L -o output.mp4 "URL" --max-filesize 500M

# Set memory limits for tools
ulimit -v 2000000  # 2GB virtual memory limit

# Clean up immediately after use
rm -f /tmp/nanobot_*
```

## Implementation Checklist

- [x] Increase swap space to 4GB (2026-08-03: `/swapfile` resized to 3G, fstab persisted)
- [x] Adjust vm.swappiness to 60 (2026-08-03: sysctl.conf cleaned duplicate entries, now `vm.swappiness=60`)
- [x] Update nanobot config.json (2026-08-03: contextWindowTokens 32768, maxMessages 60, consolidationRatio 0.3, idleCompactAfterMinutes 30)
- [x] Create systemd service with memory limits (2026-08-03: `/etc/systemd/system/nanobot.service`, MemoryMax=1G / MemoryHigh=800M / OOMScoreAdjust=-500, Restart=always)
- [x] Deploy watchdog script (replaced by systemd `Restart=always`, no separate watchdog needed)
- [x] Set up memory monitoring (2026-08-03: `/usr/local/bin/nanobot-memory-monitor.sh` + systemd timer, every 5min → `/var/log/nanobot-memory.log`)
- [x] Configure log rotation (2026-08-03: `/etc/logrotate.d/nanobot` for nanobot + ffmpeg logs)
- [x] Test with large file operations (2026-08-03: `vm.oom_kill_allocating_task=1` also enabled)

## Applied Changes (2026-08-03)

Deployed on the 1.6GB ECS after the second OOM-type crash (2026-08-03):

| 项 | 变更前 | 变更后 |
|----|--------|--------|
| swap | 2GB | 3GB（`/swapfile` 重建为 3G，fstab 持久化）|
| vm.swappiness | 10 | 60 |
| vm.oom_kill_allocating_task | 0 | 1 |
| contextWindowTokens | 65536 | 32768 |
| maxMessages | 120 | 60 |
| consolidationRatio | 0.5 | 0.3 |
| idleCompactAfterMinutes | 0（关闭） | 30 |
| NANOBOT_MAX_CONCURRENT_REQUESTS | 3 | 2（systemd Environment）|
| 网关端口 | 18790 | 18791（被 picoclaw 占用）|
| 托管方式 | 手动进程（无自动恢复） | systemd 服务（Restart=always）|
| 内存限制 | 无 | MemoryHigh=800M / MemoryMax=1G / OOMScoreAdjust=-500 |

### 服务管理

```bash
systemctl start nanobot        # 启动
systemctl status nanobot       # 查看状态
journalctl -u nanobot -f       # 查看日志
systemctl restart nanobot      # 重启
```

Health check: `curl http://127.0.0.1:18791/health`

## Expected Outcomes

1. **Stability**: No more OOM kills under normal operation
2. **Recovery**: Automatic restart within 30 seconds if crash occurs
3. **Visibility**: Memory usage logged and monitored
4. **Performance**: Slightly reduced context window, but more reliable service

## References

- Linux OOM Killer: `man oom_killer`
- Systemd Resource Control: `man systemd.resource-control`
- Kernel Swappiness: `Documentation/admin-guide/sysctl/vm.rst`
