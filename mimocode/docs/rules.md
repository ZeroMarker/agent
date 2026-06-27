# 规则

通过 `AGENTS.md` 文件为 MiMo Code 提供自定义指令。

## 初始化

```
/init
```

扫描项目并生成 `AGENTS.md`。**建议提交到 Git。**

## 文件位置

| 位置 | 说明 |
|------|------|
| 项目根目录 `AGENTS.md` | 项目特定规则 |
| `~/.config/mimocode/AGENTS.md` | 全局个人规则 |
| `CLAUDE.md` / `~/.claude/CLAUDE.md` | Claude Code 兼容回退 |

优先级：`AGENTS.md` > `CLAUDE.md`

## 自定义指令

在 `mimocode.json` 中引用外部文件：

```json
{
  "instructions": [
    "CONTRIBUTING.md",
    "docs/guidelines.md",
    ".cursor/rules/*.md",
    "https://raw.githubusercontent.com/org/shared-rules/main/style.md"
  ]
}
```

所有指令与 `AGENTS.md` 合并。
