# Nanobot OOM Crash Report

## Incident Summary

**Date**: 2026-06-25 13:22:39 UTC  
**Process**: nanobot (PID: 406656)  
**Exit Code**: Killed by OOM Killer  
**Trigger**: async-std/runtime thread

## Memory Snapshot at Crash

| Metric | Value |
|--------|-------|
| Total VM | 3,044,284 kB (~3 GB) |
| Anonymous RSS | 1,330,768 kB (~1.3 GB) |
| File RSS | 2,816 kB |
| Swap Used | 1,024,612 kB (~1 GB) |
| System RAM | 1.6 GB total |

## Root Cause

The nanobot process exhausted system memory while downloading a large Bilibili video file (396 MB). The crash occurred during:

1. B站视频解析和下载操作
2. Multiple concurrent subagent execution
3. Context window accumulation (65536 tokens)
4. Large file buffering in memory

## System Context

- **Platform**: Alibaba Cloud ECS
- **OS**: Ubuntu with kernel 6.8.0-63-generic
- **RAM**: 1.6 GB
- **Swap**: 2.0 GB (1.0 GB used)
- **vm.swappiness**: 10 (low swap tendency)

## Evidence

### Kernel Log (dmesg)
```
[500082.947849] async-std/runti invoked oom-killer: gfp_mask=0x140cca(GFP_HIGHUSER_MOVABLE|__GFP_COMP), order=0, oom_score_adj=0
[500082.948394] oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),cpuset=/,mems_allowed=0,global_oom,task=nanobot,pid=406656,uid=0
[500082.948422] Out of memory: Killed process 406656 (nanobot) total-vm:3044284kB, anon-rss:1330768kB
```

### Syslog
```
2026-06-25T13:22:40.509571+08:00 kernel: oom-kill:constraint=CONSTRAINT_NONE,task=nanobot,pid=406656
2026-06-25T13:22:40.509572+08:00 kernel: Out of memory: Killed process 406656 (nanobot)
```

### Application Log (nanobot.log)
Last activity before crash:
- 13:22:15 - Sent video file to QQ user
- 13:22:31 - Cleanup temp files
- **No graceful shutdown logged** (killed by kernel)

## Impact

- Service interrupted without graceful shutdown
- QQ channel disconnected
- Pending messages may have been lost
- Temp files partially cleaned up

## Recommendations

See [optimization-strategy.md](./optimization-strategy.md) for prevention measures.
