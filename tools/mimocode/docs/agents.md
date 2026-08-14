# Agents（代理）

## 类型

- **主代理** — 直接交互（Tab 切换）：`build`、`plan`
- **子代理** — 主代理调用或 `@` 提及：`general`、`explore`

## 内置代理

| 代理 | 模式 | 说明 |
|------|------|------|
| Build | primary | 默认，完整工具权限 |
| Plan | primary | 只读分析和规划 |
| General | subagent | 通用多步骤任务 |
| Explore | subagent | 快速只读代码探索 |
| Compaction | primary | 隐藏，上下文压缩 |
| Title | primary | 隐藏，生成会话标题 |

## 配置

### JSON

```json
{
  "agent": {
    "code-reviewer": {
      "description": "Reviews code for best practices",
      "mode": "subagent",
      "model": "mimo/mimo-v2.5-pro",
      "prompt": "You are a code reviewer.",
      "tools": { "write": false, "edit": false }
    }
  }
}
```

### Markdown

`~/.config/mimocode/agents/review.md`:

```markdown
---
description: Reviews code for quality
mode: subagent
tools:
  write: false
  edit: false
---

You are in code review mode.
```

## 选项

`description`、`model`、`prompt`、`mode`（primary/subagent/all）、`temperature`、`steps`、`tools`、`permission`、`hidden`、`color`、`top_p`
