# 自定义工具

TypeScript/JavaScript 定义，可调用任何语言脚本。

## 位置

- 项目：`.mimocode/tools/`
- 全局：`~/.config/mimocode/tools/`

## 结构

```ts
import { tool } from "@@mimocode/cli/plugin"

export default tool({
  description: "Query the project database",
  args: {
    query: tool.schema.string().describe("SQL query to execute"),
  },
  async execute(args) {
    return `Executed query: ${args.query}`
  },
})
```

文件名即工具名称。

## 单文件多工具

```ts
export const add = tool({ ... })
export const multiply = tool({ ... })
```

创建 `math_add` 和 `math_multiply`。

## 上下文

```ts
async execute(args, context) {
  const { agent, sessionID, directory, worktree } = context
}
```

## Python 示例

```ts
import { tool } from "@@mimocode/cli/plugin"
export default tool({
  description: "Add two numbers using Python",
  args: {
    a: tool.schema.number(),
    b: tool.schema.number(),
  },
  async execute(args, context) {
    const script = path.join(context.worktree, ".mimocode/tools/add.py")
    return (await Bun.$`python3 ${script} ${args.a} ${args.b}`.text()).trim()
  },
})
```
