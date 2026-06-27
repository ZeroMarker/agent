# 从源码构建

## 前提条件

- Rust 工具链
- `just` 命令
- `dotslash`（可选）
- `cargo-nextest`（测试）

## 构建步骤

```bash
# 克隆仓库
git clone https://github.com/openai/codex.git
cd codex/codex-rs

# 安装 Rust 工具链
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup component add rustfmt clippy

# 安装辅助工具
cargo install --locked just
cargo install --locked dotslash
cargo install --locked cargo-nextest

# 构建
cargo build

# 运行 TUI
cargo run --bin codex -- "explain this codebase to me"
```

## 开发命令

```bash
just fmt                      # 格式化
just fix -p <crate>           # 修复 linter 问题
just test -p codex-tui        # 运行特定项目测试
just test                     # 运行完整测试套件
just bench                    # 运行基准测试
just bench-smoke              # 基准测试干运行
just write-config-schema      # 更新配置 schema
just write-app-server-schema  # 更新 app-server schema
just bazel-lock-update        # 更新 Bazel 锁文件
just argument-comment-lint    # 运行参数注释 lint
```

## 项目结构

```
codex-rs/
├── core/           # 核心代理逻辑（最大 crate，避免继续膨胀）
├── tui/            # 终端 UI
├── cli/            # CLI 入口
├── app-server/     # 应用服务器
├── exec-server/    # 执行服务器
├── mcp-server/     # MCP 服务器
├── hooks/          # 生命周期钩子
├── skills/         # 技能系统
├── plugin/         # 插件系统
├── config/         # 配置管理
└── ...             # 60+ 个 crate
```
