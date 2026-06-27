# 项目结构

Codex 主要用 Rust 编写（96.5%），采用 Cargo workspace 组织。

## 主要目录

| 目录 | 说明 |
|------|------|
| `codex-rs/` | Rust 主代码库 |
| `codex-cli/` | 旧版 Node.js CLI（已弃用） |
| `docs/` | 文档 |
| `sdk/` | SDK |
| `tools/` | 工具 |
| `scripts/` | 脚本 |

## 核心 Crate

| Crate | 说明 |
|-------|------|
| `codex-core` | 核心代理逻辑（最大，避免继续膨胀） |
| `codex-tui` | 终端 UI（ratatui） |
| `codex-cli` | CLI 入口 |
| `codex-app-server` | 应用服务器 |
| `codex-exec-server` | 执行服务器 |
| `codex-mcp` | MCP 集成 |
| `codex-hooks` | 生命周期钩子 |
| `codex-skills` | 技能系统 |
| `codex-plugin` | 插件系统 |
| `codex-config` | 配置管理 |
| `codex-sandboxing` | 沙箱执行 |
| `codex-protocol` | 协议定义 |

## Crate 命名

Crate 名称以 `codex-` 为前缀。例如 `core/` 目录的 crate 名为 `codex-core`。
