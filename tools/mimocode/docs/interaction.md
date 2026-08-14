# 交互与输入

```bash
mimo              # 启动当前目录的 TUI
mimo /path/to/project  # 指定工作目录
```

## 输入框基本操作

- **发送**: `enter`
- **换行**: `shift+enter` / `ctrl+j` / `ctrl+return` / `alt+return`
- **退出**: `ctrl+c` / `ctrl+d` / `/exit`

## 文件引用

使用 `@` 引用文件，内容自动添加到对话：

```
How is auth handled in @packages/functions/src/api/index.ts?
```

## 图片输入

将图片**拖放到终端窗口**即可添加到提示词（需模型支持多模态）。

## 执行 Shell 命令

以 `!` 开头的消息作为 shell 命令执行：

```bash
!ls -la
```

## 模式切换与中断

- **Tab** — 在 Build 与 Plan 之间切换
- **Esc** — 中断当前回合
