# 会话与上下文

## 会话存储

会话数据保存在 `$MIMOCODE_HOME/` 下，按工作目录分组。

## 启动与恢复

```bash
mimo                    # 新会话
mimo --continue         # 继续最近会话 (-c)
mimo --session <id>     # 按 ID 恢复 (-s)
mimo --continue --fork  # 分叉会话
```

## TUI 中切换会话

- `/new` (`ctrl+x n`) — 开始新会话
- `/sessions` (`ctrl+x l`) — 列出并切换会话

## 上下文压缩

对话变长时自动压缩，也可手动触发：

```
/compact    # 别名 /summarize，快捷键 ctrl+x c
```

配置：

```json
{
  "compaction": {
    "auto": true,
    "prune": true,
    "reserved": 10000
  }
}
```

## 导出与导入

```bash
mimo export [sessionID]           # 导出为 JSON
mimo import session.json          # 从文件导入
mimo import https://opncd.ai/s/abc123  # 从链接导入
```
