# LSP 服务器

与语言服务器协议集成，提供诊断信息给 LLM。

## 内置支持

typescript、eslint、pyright、gopls、rust、clangd、dart、jdtls、vue、svelte、bash、terraform 等 30+ 服务器。

检测到对应文件扩展名且满足要求时自动启用。

## 配置

```json
{
  "lsp": {
    "typescript": {
      "command": ["typescript-language-server", "--stdio"],
      "initialization": {
        "preferences": { "importModuleSpecifierPreference": "relative" }
      }
    }
  }
}
```

禁用全部：`"lsp": false`

禁用特定：`{ "typescript": { "disabled": true } }`
