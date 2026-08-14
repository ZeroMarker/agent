# 配置文件

MiMo Code 以 JSON/JSONC 配置文件管理所有运行时参数。

## 顶层字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `model` | string | 默认模型 `provider_id/model_id` |
| `small_model` | string | 轻量任务模型 |
| `provider` | object | 提供商连接选项 |
| `agent` | object | 自定义代理定义 |
| `default_agent` | string | 默认代理 |
| `command` | object | 自定义命令模板 |
| `permission` | object | 工具权限规则 |
| `tool` | object | 工具调用风格 |
| `mcp` | object | MCP 服务器 |
| `plugin` | array | 插件列表 |
| `skills` | object | 技能加载源 |
| `lsp` | object | LSP 集成 |
| `formatter` | object | 代码格式化 |
| `instructions` | array | 指令文件路径 |
| `share` | string | 分享模式 |
| `autoupdate` | boolean/"notify" | 自动更新 |
| `compaction` | object | 上下文压缩策略 |

## 完整示例

```json
{
  "$schema": "https://mimo.xiaomi.com/mimocode/config.json",
  "model": "mimo/mimo-v2.5-pro",
  "default_agent": "build",
  "share": "manual",
  "permission": {
    "*": "ask",
    "bash": "allow"
  },
  "compaction": { "auto": true, "prune": true }
}
```

## 变量替换

- `{env:VAR}` — 环境变量
- `{file:path}` — 文件内容

## Schema

添加 `"$schema"` 启用编辑器补全：

```json
{ "$schema": "https://mimo.xiaomi.com/mimocode/config.json" }
```
