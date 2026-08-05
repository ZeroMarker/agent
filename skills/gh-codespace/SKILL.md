---
name: gh-codespace
version: 1.0.0
description: "GitHub Codespace 操作：查看/启动/停止/连接 codespace、在 codespace 内执行命令与传输文件、安装配置 pi agent（含 API key 授权）、gh 登录态修复（token 过期）、以及 push 代码到 GitHub。当用户提到 codespace、云端开发容器、需要在云端环境跑 pi/审查项目/推送代码时使用。不负责：飞书相关操作（走 lark-*）、pi 本身的扩展/主题开发（走 pi docs）。"
metadata:
  requires:
    bins: ["gh"]
  cliHelp: "gh codespace --help"
---

# gh-codespace

操作 GitHub Codespace 的完整工作流：连接、命令执行、文件传输、pi agent 授权、gh 登录修复、代码推送。

## 环境速览

| 项 | 值 |
|---|---|
| Codespace 名称 | `zany-zebra-959667wqvxqcx7qv` |
| 关联仓库 | `ZeroMarker/agent`（workspace 在 `/workspaces/agent`） |
| 机器 | 2 核 / 8 GB / 32 GB；闲置 30 分钟超时；保留 30 天 |
| 本地 gh | 已登录 `ZeroMarker`（`/root/.config/gh/hosts.yml` 有 token） |
| codespace 内 pi | 已安装 0.83.0，已授权 `opencode-go` |
| codespace 内项目 | `/workspaces/agent`（agent 仓库）、`~/guomi`（guomi 仓库） |

## 核心命令

```bash
# 状态
gh codespace list
gh codespace view -c <codespace名>

# 启动（Shutdown 状态用 ssh 命令会自动拉起）
gh codespace ssh -c <codespace名> -- echo ready

# 停止 / 删除
gh codespace stop -c <codespace名>
gh codespace delete -c <codespace名>

# VS Code 打开
gh codespace code -c <codespace名>
```

## ⚠️ 关键坑：远端命令执行

`gh codespace ssh -c NAME -- bash -c '复杂命令'` 的**单引号常被剥离**，导致命令行为怪异（例如 `bash -c export` 会打印全部环境变量；git 报 usage 帮助）。

**正确做法**：写本地脚本，用 stdin 执行：

```bash
# /tmp/script.sh 内容即要执行的远端命令序列
gh codespace ssh -c <codespace名> -- bash -s < /tmp/script.sh
```

`cd <repo> && git status` 在远端 shell 偶发报 "not a git repository"（工作目录未切换成功）——一律用 `git -C /绝对路径 status` 或脚本 + `bash -s`。

## 文件传输

```bash
# remote: 路径相对远端用户主目录解析！remote:/tmp/xxx 会解析成 ~/tmp/xxx 而失败
gh codespace cp /root/.pi/agent/auth.json -c <codespace名> remote:.pi/agent/auth.json

# 更稳的方式：stdin 管道写入
gh codespace ssh -c <codespace名> -- bash -c 'cat > ~/.pi/agent/auth.json' < /root/.pi/agent/auth.json
```

## pi agent 安装与授权（codespace 内）

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# 配置目录 ~/.pi/agent/，三个文件：
#   auth.json        供应商 API key { "opencode-go": { "type": "api_key", "key": "sk-..." } }
#   settings.json    默认供应商/模型/思考强度
#   models-store.json 模型目录缓存
mkdir -p ~/.pi/agent
# 从本地已配置机器管道传输三个文件（见"文件传输"）
```

- 供应商 `opencode-go`，baseUrl `https://opencode.ai/zen/go/v1`
- 默认模型 `deepseek-v4-flash`（另有 `deepseek-v4-pro`、`glm-5.1/5.2`）
- 运行：`gh codespace ssh -c NAME -- bash -c 'cd ~/项目 && pi -p "审查并修复"'`

## gh 登录修复（无法 push 时）

**现象**：codespace 内 `gh auth status` 报 `You are not logged into any GitHub hosts`，push 失败。

**原因**：Codespace 创建时注入的临时 `GITHUB_TOKEN` 约 8 小时过期；长期 Shutdown 后重启不会重新注入。

**解决**（把本机 token 注入 codespace）：

```bash
# 本地导出 token（不落盘进仓库）
python3 -c "import yaml; d=yaml.safe_load(open('/root/.config/gh/hosts.yml')); print(d['github.com']['oauth_token'])" > /tmp/gh_token.txt

# 传过去
gh codespace ssh -c <codespace名> -- bash -c 'cat > /tmp/gh_token.txt' < /tmp/gh_token.txt

# codespace 内登录 + 配置 git 凭据（脚本经 bash -s 执行）
gh codespace ssh -c <codespace名> -- bash -s < /tmp/gh_login.sh
# /tmp/gh_login.sh:
#   gh auth login --with-token < /tmp/gh_token.txt && gh auth setup-git
```

**预防**：push 前先 `gh auth status` 检查；或重建 codespace；或在 codespace 内交互式 `gh auth login`。

## 代码推送流程

```bash
# 本地（gh 已登录）或 codespace（已修复登录后）均可
git add -A
git commit -m "msg"
git push origin main
# 验证：git ls-remote origin main（对比本地 HEAD）
# CI：gh run list -R <owner>/<repo> --limit 3
```

## 安全红线

- `auth.json`、`gh_token.txt` 含真实密钥，**只放 /tmp 或 ~/.pi/agent，绝不提交进仓库**
- 文档中一律用占位符（`sk-...`、`<codespace名>`）
- 推送前可 grep 敏感模式：`sk-[a-zA-Z0-9]{32,}`、`ghp_[a-zA-Z0-9]{20,}`、`BEGIN [A-Z ]*PRIVATE KEY`
