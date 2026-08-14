# 权限

## 操作

- `"allow"` — 无需审批直接运行
- `"ask"` — 提示审批
- `"deny"` — 阻止

## 配置

```json
{
  "permission": {
    "*": "ask",
    "bash": "allow",
    "edit": "deny"
  }
}
```

## 细粒度规则（对象语法）

```json
{
  "permission": {
    "bash": {
      "*": "ask",
      "git *": "allow",
      "rm *": "deny"
    },
    "edit": {
      "*": "deny",
      "packages/web/src/**/*.mdx": "allow"
    }
  }
}
```

**最后匹配的规则优先。**

## 可用权限

`read`、`edit`（涵盖 write/patch/multiedit）、`glob`、`grep`、`bash`、`task`、`skill`、`lsp`、`webfetch`、`websearch`、`external_directory`、`doom_loop`

## 默认值

- 大多数默认 `"allow"`
- `doom_loop` 和 `external_directory` 默认 `"ask"`
- `.env` 文件默认拒绝读取

## 外部目录

允许访问项目工作目录之外的路径：

```json
{
  "permission": {
    "external_directory": {
      "~/projects/personal/**": "allow"
    }
  }
}
```
