# MCP 集成

Model Context Protocol (MCP) 允许 Codex 连接外部工具和数据源。

## 用途

- 外部数据/操作
- 私有应用/工作区数据授权
- Google Docs、Calendar、Slack、GitHub、Notion 等连接器

## 配置

在 `.codex/config.toml` 中配置 MCP 服务器。

## 添加 MCP 服务器

```bash
codex mcp add <name> --url <url>
```

## 管理

```bash
codex mcp list
codex mcp auth <name>
codex mcp logout <name>
codex mcp debug <name>
```

详见: https://developers.openai.com/codex/concepts/customization#mcp
