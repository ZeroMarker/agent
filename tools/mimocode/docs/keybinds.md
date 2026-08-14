# 快捷键

通过 `tui.json` 的 `keybinds` 自定义。默认前导键：`ctrl+x`。

## 常用操作

| 操作 | 默认键 |
|------|--------|
| 退出 | `ctrl+c` / `ctrl+d` |
| 新会话 | `<leader>n` |
| 会话列表 | `<leader>l` |
| 压缩 | `<leader>c` |
| 模型列表 | `<leader>m` |
| 变体切换 | `ctrl+t` |
| 代理切换 | `tab` |
| 导出 | `<leader>x` |
| 撤销 | `<leader>u` |
| 重做 | `<leader>r` |
| 中断 | `escape` |

## 输入框

| 操作 | 键 |
|------|-----|
| 行首 | `ctrl+a` |
| 行尾 | `ctrl+e` |
| 前一单词 | `ctrl+w` / `alt+b` |
| 删到行尾 | `ctrl+k` |
| 删到行首 | `ctrl+u` |
| 换行 | `shift+return` / `ctrl+j` |

## 禁用快捷键

```json
{ "keybinds": { "session_compact": "none" } }
```
