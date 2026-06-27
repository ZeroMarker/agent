# 自定义命令

## 创建命令

在 `.mimocode/commands/` 或 `~/.config/mimocode/commands/` 中创建 markdown 文件：

```markdown
---
description: Run tests with coverage
agent: build
model: mimo/mimo-v2.5-pro
---

Run the full test suite with coverage report and show any failures.
```

使用：`/test`

## JSON 配置

```json
{
  "command": {
    "test": {
      "template": "Run the full test suite with coverage.",
      "description": "Run tests with coverage",
      "agent": "build"
    }
  }
}
```

## 提示词语法

- `$ARGUMENTS` — 所有参数
- `$1`, `$2`, `$3` — 位置参数
- `` !`command` `` — Shell 命令输出注入
- `@file` — 文件引用

## 选项

| 选项 | 说明 |
|------|------|
| `template` | 提示词模板（必需） |
| `description` | 描述 |
| `agent` | 执行代理 |
| `subtask` | 强制子代理运行 |
| `model` | 覆盖模型 |
