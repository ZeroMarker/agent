# AGENTS.md 规则

`AGENTS.md` 是 Codex 的核心自定义机制，用于定义仓库级别的约定、命令、验证步骤和审查期望。

## 用途

- 项目结构说明
- 编码规范
- 测试要求
- 构建和部署命令
- 代码审查标准

## 文件位置

| 位置 | 说明 |
|------|------|
| 项目根目录 `AGENTS.md` | 项目级规则，提交到 Git |
| 子目录 `AGENTS.md` | 针对子树的规则 |
| `.codex/config.toml` | 可信仓库的 Codex 设置 |

## 优先级

嵌套的文件在其子树下优先。

## 示例

参见 [Codex 仓库的 AGENTS.md](https://github.com/openai/codex/blob/main/AGENTS.md)，包含：

- Rust 代码规范
- TUI 样式约定
- 测试编写指南
- 代码审查规则
- API 开发最佳实践

## 与其他表面的关系

- **AGENTS.md** → 持久的仓库约定
- **config.toml** → 沙箱、MCP、hooks、模型设置
- **Skills** → 可复用的任务工作流
- **Plugins** → 可安装的技能包
- **Hooks** → 工具调用和文件编辑的生命周期强制
