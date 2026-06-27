# 工具

MiMo Code 自带一组内置工具，也可通过自定义工具或 MCP 服务器扩展。

## 内置工具

| 工具 | 说明 |
|------|------|
| `bash` | 执行 shell 命令 |
| `edit` | 通过精确字符串替换修改文件 |
| `write` | 创建新文件或覆盖现有文件 |
| `read` | 读取文件内容 |
| `grep` | 正则表达式搜索文件内容 |
| `glob` | 模式匹配查找文件 |
| `lsp` | LSP 代码智能（实验性） |
| `patch` | 应用补丁 |
| `skill` | 加载技能 |
| `todowrite` | 管理待办事项 |
| `webfetch` | 获取网页内容 |
| `websearch` | 网络搜索（需 Exa 或 MiMo 提供商） |
| `question` | 执行过程中向用户提问 |

## 权限配置

```json
{
  "permission": {
    "edit": "deny",
    "bash": "ask",
    "webfetch": "allow"
  }
}
```

## 忽略模式

项目根目录创建 `.ignore` 文件可包含通常被忽略的文件：

```
!node_modules/
!dist/
```
