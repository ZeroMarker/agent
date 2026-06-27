# 格式化工具

文件写入或编辑后自动格式化。

## 内置格式化工具

| 格式化工具 | 扩展名 | 要求 |
|-----------|--------|------|
| prettier | .js/.ts/.jsx/.tsx/.html/.css/.md/.json/.yaml | package.json 中有依赖 |
| biome | .js/.jsx/.ts/.tsx 等 | biome.json(c) 配置 |
| rustfmt | .rs | rustfmt 命令 |
| gofmt | ..go | gofmt 命令 |
| ruff | .py/.pyi | ruff 命令 |
| shfmt | .sh/.bash | shfmt 命令 |
| clang-format | .c/.cpp/.h | .clang-format 配置 |
| dart | .dart | dart 命令 |
| zig | .zig/.zon | zig 命令 |

## 禁用

全局禁用：`"formatter": false`

特定禁用：

```json
{
  "formatter": {
    "prettier": { "disabled": true }
  }
}
```

## 自定义

```json
{
  "formatter": {
    "custom-prettier": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "environment": { "NODE_ENV": "development" },
      "extensions": [".js", ".ts", ".jsx", ".tsx"]
    }
  }
}
```
