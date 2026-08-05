---
name: gh-codespace
version: 1.0.0
description: "GitHub Codespace 操作：查看/启动/停止/连接 codespace（含 OpenSSH 直连 `ssh <host>` 配置）、在 codespace 内执行命令与传输文件、安装配置 pi agent（含 API key 授权）、gh 登录态修复（token 过期）、以及 push 代码到 GitHub。当用户提到 codespace、云端开发容器、直连 ssh、需要在云端环境跑 pi/审查项目/推送代码时使用。不负责：飞书相关操作（走 lark-*）、pi 本身的扩展/主题开发（走 pi docs）。"
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

## 直接 SSH 连接（OpenSSH 直连，Windows/Git Bash）

配置一次后即可像普通主机直连，无需交互选择：

```bash
ssh agent                                   # 短别名（仓库名）
ssh cs.zany-zebra-959667wqvxqcx7qv.main     # gh 生成的标准主机名
scp file agent:/workspaces/agent/           # scp 同样可用
```

### 一次性配置

```bash
# 1. 生成 OpenSSH 配置（主机条目为 cs.<codespace名>.<分支>）
gh codespace ssh --config > ~/.ssh/codespaces

# 2. ~/.ssh/config 末尾追加（注意独立成行，勿拼到上一行末尾）
cat >> ~/.ssh/config <<'EOF'

Match all
Include ~/.ssh/codespaces
EOF

# 3. 可选短别名：Host 用仓库名（配置见下）
```

```text
Host agent
	HostName cs.zany-zebra-959667wqvxqcx7qv.main
	User codespace
	ProxyCommand "C:/Program Files/GitHub CLI/gh.exe" cs ssh -c zany-zebra-959667wqvxqcx7qv --stdio -- -i "C:/Users/ttft3/.ssh/codespaces.auto"
	UserKnownHostsFile=/dev/null
	StrictHostKeyChecking no
	LogLevel quiet
	ControlMaster auto
	IdentityFile C:/Users/ttft3/.ssh/codespaces.auto
```

> **原理**：连接走 `ProxyCommand` → `gh.exe cs ssh --stdio` 隧道，认证交给 gh CLI，无需手动注册密钥。
> ⚠️ **Windows/Git Bash 坑**：生成配置是反斜杠路径（`C:\Program Files\...`），MSYS `/bin/sh` 执行 ProxyCommand 时把反斜杠当转义符（报 `exec: C:Program: not found`）→ 必须改成正斜杠 + 引号（如上）。
> 报 `failed to read public key file` → 先手动生成密钥：`ssh-keygen -t ed25519 -f ~/.ssh/codespaces.auto -N ""`。
> 重建配置：`bash ~/.ssh/refresh-codespaces-ssh.sh`（内含 sed 正斜杠修复）。注意 `Host agent` 别名硬编码 codespace 名，删除重建后需同步更新。

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

## 多仓库推送权限（Codespaces 原生机制）

**现象**：codespace 内 `git push` 到**非源仓库**（创建 codespace 之外的仓库）报 `Permission to <owner>/<repo>.git denied`（403）；REST API 的 `permissions` 字段显示有权限，但实际 push 仍 403（codespace token 是细粒度令牌，git 协议层只授权源仓库）。

**解决**（官方原生机制）：在**源仓库**中添加 `.devcontainer/devcontainer.json`，用 `repositories` 对象声明需要额外权限的仓库及对应权限：

```json
{
  "customizations": {
    "codespaces": {
      "repositories": {
        "<owner>/<repo>": {
          "permissions": {
            "contents": "write"
          }
        }
      }
    }
  }
}
```

步骤：
1. 在源仓库（即用来创建当前 Codespace 的那个仓库）中创建 `.devcontainer` 目录，新建 `devcontainer.json`。
2. 在 `devcontainer.json` 中使用 `repositories` 对象指定需要额外权限的仓库及对应的权限（`contents: write` 即可 push；按需加 `issues`、`pull_requests` 等）。
3. 提交并推送该文件到源仓库。
4. **重建 codespace**（token 在创建时铸造，重建后新 token 才会包含新权限；可能需授权确认，同一 owner 通常自动放行）。

> 优先级：多仓库问题优先用 devcontainer `repositories` 机制，而不是注入 ghp token（见上节）；后者仅作 token 过期临时手段。

**备用方案（当前会话即时可用）**：等不及重建 codespace 时，可用 `~/.config/gh/hosts.yml` 中已注入的 `ZeroMarker` ghp token（对 agent/guomi 均有 push 权限）。原因是 codespace 环境变量 `GITHUB_TOKEN`（ghu_，仅授权源仓库）在 gh 凭据解析中优先于 hosts.yml，导致默认拿不到 ghp token；临时清空环境 token 即可让 gh 回退到 hosts.yml：

```bash
GITHUB_TOKEN= git push origin main   # guomi 等非源仓库实测可用
```

> 临时手段：依赖 ghp token 未过期；一劳永逸仍走上面的 devcontainer 机制 + 重建 codespace。

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
