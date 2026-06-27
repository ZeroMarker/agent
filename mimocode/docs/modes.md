# 工作模式

## 内置模式

- **`build`** — 默认主代理，完整工具权限，用于通用开发
- **`plan`** — 受限主代理，只读分析和规划（禁用 write/edit/patch/bash）
- **`compose`** — 通过内置技能编排工作的主代理

子代理：**`general`** / **`explore`** — 由主代理调用处理委派任务。

## Compose 模式

Compose 附带 13 个技能，按类别分组：

| 类别 | 技能 | 用途 |
|------|------|------|
| 测试 | `compose:tdd` | 测试驱动开发 |
| 调试 | `compose:debug` | 系统化调试 |
| 调试 | `compose:verify` | 完成前验证 |
| 协作 | `compose:brainstorm` | 头脑风暴 |
| 协作 | `compose:plan` | 撰写实施计划 |
| 协作 | `compose:execute` | 执行已批准的计划 |
| 协作 | `compose:parallel` | 派发并行代理 |
| 协作 | `compose:review` | 请求代码审查 |
| 协作 | `compose:feedback` | 接收审查反馈 |
| 协作 | `compose:worktree` | git worktree 中工作 |
| 协作 | `compose:merge` | 完成开发分支 |
| 协作 | `compose:subagent` | 子代理驱动开发 |
| 元 | `compose:new-skill` | 编写新技能 |

## 切换

按 **Tab** 键在模式间切换。
