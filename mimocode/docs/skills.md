# Skills（代理技能）

技能让 MiMo Code 从仓库或主目录发现可复用的指令。

## 放置文件

在文件夹中放入 `SKILL.md`，搜索位置：

- `.mimocode/skills/**/SKILL.md`
- `~/.config/mimocode/skills/**/SKILL.md`
- `.claude/skills/`、`.agents/skills/`、`.codex/skills/`、`.opencode/skills/`

## Frontmatter

```markdown
---
name: git-release
description: Create consistent releases and changelogs
---

## What I do
- Draft release notes from merged PRs
- Propose a version bump
```

- `name`（必需）— 简短可预测，如 `git-release`
- `description`（必需）— 代理选择技能的唯一信号
- `hidden`（可选）— `true` 时不在列表中显示

## 权限

```json
{
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```
