# MCP 服务器

通过 Model Context Protocol 添加外部工具。

> MCP 服务器会占用上下文空间，请谨慎选择。

## 本地服务器

```json
{
  "mcp": {
    "my-mcp": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-command"],
      "enabled": true,
      "environment": { "MY_VAR": "value" }
    }
  }
}
```

## 远程服务器

```json
{
  "mcp": {
    "my-remote-mcp": {
      "type": "remote",
      "url": "https://my-mcp-server.com",
      "headers": { "Authorization": "Bearer MY_API_KEY" }
    }
  }
}
```

## OAuth

MiMo Code 自动处理 OAuth 认证。手动触发：

```bash
mimo mcp auth my-oauth-server
mimo mcp list
mimo mcp logout my-oauth-server
```

## 示例

- **Sentry**: `https://mcp.sentry.dev/mcp`（OAuth）
- **Context7**: `https://mcp.context7.com/mcp`（文档搜索）
- **Grep by Vercel**: `https://mcp.grep.app`（GitHub 代码搜索）
