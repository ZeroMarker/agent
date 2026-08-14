# 配置覆盖

## 优先级

**命令行选项 > 配置文件**

- 多数 CLI flag 仅作为本次运行参数，不写回配置文件
- 网络相关 flag 只在显式传入时覆盖配置
- 没有 `--config` flag，通过 `MIMOCODE_CONFIG` 或 `MIMOCODE_CONFIG_CONTENT` 指定

## 配置文件位置

- 全局：`$MIMOCODE_HOME/config/` 或 `$XDG_CONFIG_HOME/mimocode/`
- 项目：`mimocode.json(c)` 从当前目录向上查找到 worktree 根
- `.mimocode/` 与 `MIMOCODE_CONFIG_DIR`

## 合并规则

- 通用 **deep merge**，对象逐 key 递归
- 数组整段替换（`instructions` 例外，去重拼接）
- `plugin`/`mcp` 同名条目后写者覆盖

## 典型场景

```bash
# 切换 profile 根目录
MIMOCODE_HOME=/tmp/mimo-test mimo

# CI 内联注入配置与凭证
MIMOCODE_CONFIG_CONTENT='{"model":"mimo/mimo-v2.5-pro","share":"disabled"}' \
MIMOCODE_AUTH_CONTENT='{"anthropic":{"apiKey":"sk-..."}}' \
  mimo run "Generate release notes"

# 本次跳过权限提示
mimo run --dangerously-skip-permissions "Format all TypeScript files"
```
