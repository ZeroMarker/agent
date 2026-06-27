# 主题

## 内置主题

`system`、`tokyonight`、`everforest`、`ayu`、`catppuccin`、`catppuccin-macchiato`、`gruvbox`、`kanagawa`、`nord`、`matrix`、`one-dark`

## 使用

```
/theme
```

或在 `tui.json` 中指定：

```json
{ "theme": "tokyonight" }
```

## 自定义主题

### 加载优先级

1. 内置主题（二进制）
2. `~/.config/mimocode/themes/*.json`
3. `<project-root>/.mimocode/themes/*.json`
4. `./.mimocode/themes/*.json`

### JSON 格式

- 十六进制颜色：`"#ffffff"`
- ANSI 颜色：`3`
- 颜色引用：`"primary"`
- 深色/浅色变体：`{"dark": "#000", "light": "#fff"}`
- 无颜色：`"none"` — 使用终端默认

> 需要终端支持**真彩色**（24 位色）。检查：`echo $COLORTERM` 应输出 `truecolor` 或 `24bit`。
