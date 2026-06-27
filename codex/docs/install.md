# 安装与启动

## 系统要求

| 要求 | 详情 |
|------|------|
| 操作系统 | macOS 12+、Ubuntu 20.04+/Debian 10+、Windows 11 (WSL2) |
| Git | 2.23+（可选，推荐） |
| 内存 | 4GB 最低（8GB 推荐） |

## 安装方式

### Mac/Linux

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

### Windows

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

### npm

```bash
npm install -g @openai/codex
```

### Homebrew

```bash
brew install --cask codex
```

### GitHub Release

前往 [最新 Release](https://github.com/openai/codex/releases/latest) 下载对应平台二进制：

- macOS Apple Silicon: `codex-aarch64-apple-darwin.tar.gz`
- macOS x86_64: `codex-x86_64-apple-darwin.tar.gz`
- Linux x86_64: `codex-x86_64-unknown-linux-musl.tar.gz`
- Linux arm64: `codex-aarch64-unknown-linux-musl.tar.gz`

## 启动

```bash
codex
```

## 日志

Codex 使用 `RUST_LOG` 环境变量配置日志：

```bash
codex -c log_dir=./.codex-log
tail -F ./.codex-log/codex-tui.log
```
