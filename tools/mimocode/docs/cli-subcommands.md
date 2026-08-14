# 子命令

## auth

```bash
mimo auth login     # 配置提供商 API 密钥
mimo auth list      # 列出已认证提供商
mimo auth logout    # 清除提供商信息
```

## mcp

```bash
mimo mcp add        # 添加 MCP 服务器
mimo mcp list       # 列出 MCP 服务器
mimo mcp auth [name]  # OAuth 认证
mimo mcp logout [name]  # 移除凭据
mimo mcp debug <name>   # 调试连接
```

## session

```bash
mimo session list [--max-count N] [--format table|json]
```

## 其他

```bash
mimo models [--refresh] [--verbose]  # 列出模型
mimo stats [--days N]                # 统计信息
mimo upgrade [target]                # 升级
mimo uninstall [--keep-data]         # 卸载
```
