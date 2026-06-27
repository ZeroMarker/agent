# 第一次运行

## 初始化

```bash
cd /path/to/project
mimo
/init
```

MiMo Code 会分析项目并在根目录创建 `AGENTS.md` 文件。**建议将该文件提交到 Git。**

## 使用

### 提问

使用 `@` 键模糊搜索项目中的文件：

```
How is authentication handled in @packages/functions/src/api/index.ts
```

### 添加功能

1. **制定计划** — 按 **Tab** 切换到 Plan 模式，描述需求
2. **迭代计划** — 提供反馈或补充细节（可拖放图片到终端）
3. **构建功能** — 按 **Tab** 回到 Build 模式，让 MiMo Code 实施

### 直接修改

对于简单修改，直接描述即可：

```
We need to add authentication to the /settings route. 
Take a look at @packages/functions/src/notes.ts and implement the same logic.
```

### 撤销修改

- `/undo` — 撤销最后一条消息及其文件更改
- `/redo` — 重做修改

> 需要项目是 Git 仓库。
