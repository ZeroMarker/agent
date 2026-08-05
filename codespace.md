# GitHub Codespace 使用与配置笔记

本文档记录 GitHub Codespace（`ZeroMarker/agent`）的查看、启动、连接、pi agent 授权、项目操作（guomi 审查修复与推送）以及踩过的坑。以"快速查找、后续补充"为目标。

## 1. Codespace 基本信息

| 项目 | 值 |
| --- | --- |
| Codespace 名称 | `zany-zebra-959667wqvxqcx7qv` |
| 显示名称 | zany zebra |
| 关联仓库 | `ZeroMarker/agent`（分支 `main`） |
| 机器规格 | 2 核 / 8 GB 内存 / 32 GB 存储 |
| 闲置超时 | 30 分钟 |
| 保留周期 | 30 天（到期自动删除） |

> 注意：Codespace 本身是 GitHub 云端容器环境；本仓库（本地 /root/agent）是独立环境，通过 `gh` CLI 与之交互。

## 2. 常用命令（本地执行）

```bash
# 查看状态
gh codespace list
gh codespace view -c zany-zebra-959667wqvxqcx7qv

# 启动（Shutdown 状态时用 ssh 会自动拉起）
gh codespace ssh -c zany-zebra-959667wqvxqcx7qv -- echo ready

# 停止 / 删除
gh codespace stop -c zany-zebra-959667wqvxqcx7qv
gh codespace delete -c zany-zebra-959667wqvxqcx7qv

# 在 VS Code 中打开
gh codespace code -c zany-zebra-959667wqvxqcx7qv

# 执行远端命令（注意：引号在 ssh 传参时可能被剥离，复杂命令建议用脚本 + stdin）
cat /tmp/script.sh | gh codespace ssh -c zany-zebra-959667wqvxqcx7qv -- bash -s

# 传输文件（remote: 相对远端用户主目录解析）
gh codespace cp /local/path -c zany-zebra-959667wqvxqcx7qv remote:.pi/agent/auth.json
```

> ⚠️ 经验：`gh codespace ssh -- bash -c '复杂命令'` 的单引号可能被剥离导致行为怪异（例如 `bash -c export` 会打印全部环境变量）。可靠做法是写脚本文件，用 `gh codespace ssh -- bash -s < script.sh` 执行。

## 3. 直接 SSH 连接（OpenSSH 直连，Windows/Git Bash）

配置完成后可像普通主机一样直连，无需每次交互选择 codespace：

```bash
ssh agent                                   # 短别名（仓库名）
ssh cs.zany-zebra-959667wqvxqcx7qv.main     # gh 生成的标准主机名
scp file agent:/workspaces/agent/           # 传输文件同样可用
```

### 配置步骤

```bash
# 1. 生成 OpenSSH 配置（主机条目为 cs.<codespace名>.<分支>）
gh codespace ssh --config > ~/.ssh/codespaces

# 2. 在 ~/.ssh/config 末尾追加 Include（注意独立成行，不要拼到上一行末尾）
cat >> ~/.ssh/config <<'EOF'

Match all
Include ~/.ssh/codespaces
EOF

# 3.（可选）加短别名：Host 用仓库名，指向同一 ProxyCommand
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

> 原理：连接走 `ProxyCommand` → `gh.exe cs ssh --stdio` 隧道，认证由 gh CLI 完成，无需手动注册密钥。若报 `failed to read public key file: ...codespaces.auto.pub`，先手动生成密钥对：
> `ssh-keygen -t ed25519 -f ~/.ssh/codespaces.auto -N ""`

> ⚠️ Windows/Git Bash 坑：`gh codespace ssh --config` 生成的是反斜杠路径（`C:\Program Files\...`），MSYS `/bin/sh` 执行 ProxyCommand 时把反斜杠当转义符（报 `exec: C:Program: not found`）。必须改成正斜杠 + 引号（如上）。重建配置用脚本：`bash ~/.ssh/refresh-codespaces-ssh.sh`。

### 刷新脚本 ~/.ssh/refresh-codespaces-ssh.sh

```bash
#!/bin/bash
# Regenerate ~/.ssh/codespaces with Git Bash compatible (forward-slash) paths.
# Usage: bash ~/.ssh/refresh-codespaces-ssh.sh
set -euo pipefail

gh codespace ssh --config | sed \
  -e 's#C:\\Program Files\\GitHub CLI\\gh.exe#"C:/Program Files/GitHub CLI/gh.exe"#g' \
  -e 's#C:\\Users\\ttft3\\.ssh#C:/Users/ttft3/.ssh#g' \
  > ~/.ssh/codespaces

echo "Updated ~/.ssh/codespaces"
echo "Available hosts:"
grep -E '^Host ' ~/.ssh/codespaces
```

> 注意：`Host agent` 短别名硬编码了 codespace 名，codespace 删除重建后需同步更新 `~/.ssh/config` 中对应段落（或只用完整主机名）。

## 4. pi agent 安装与授权

Codespace 内已安装 pi（版本 0.83.0，与本地一致）：

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

### 配置文件（远端 ~/.pi/agent/）

| 文件 | 作用 |
| --- | --- |
| `auth.json` | 供应商 API key（JSON，`{ "opencode-go": { "type": "api_key", "key": "sk-..." } }`） |
| `settings.json` | 默认供应商/模型/思考强度 |
| `models-store.json` | 模型目录缓存（含 baseUrl、上下文窗口、价格等） |

当前配置：

- 供应商：`opencode-go`，baseUrl `https://opencode.ai/zen/go/v1`
- 默认模型：`deepseek-v4-flash`（另有 `deepseek-v4-pro`、`glm-5.1`、`glm-5.2` 等）
- 默认思考强度：high

### 授权方式

从本地（已配置好 pi 的机器）把配置文件管道传输到 codespace：

```bash
gh codespace ssh -c <codespace名> -- bash -c 'mkdir -p ~/.pi/agent'
gh codespace ssh -c <codespace名> -- bash -c 'cat > ~/.pi/agent/auth.json'       < ~/.pi/agent/auth.json
gh codespace ssh -c <codespace名> -- bash -c 'cat > ~/.pi/agent/settings.json'    < ~/.pi/agent/settings.json
gh codespace ssh -c <codespace名> -- bash -c 'cat > ~/.pi/agent/models-store.json' < ~/.pi/agent/models-store.json
```

> 🔒 安全：`auth.json` 含真实 API key，不要提交到仓库；本笔记中一律用占位符。

### 非交互运行

```bash
# print 模式：单轮执行后退出
gh codespace ssh -c <codespace名> -- bash -c 'cd ~/guomi && pi -p "请审查这个项目并修复问题"'
```

## 5. 项目操作记录

### guomi（Elixir 国密算法库）

- 仓库：`ZeroMarker/guomi`，克隆到 codespace 的 `~/guomi`
- 用途：纯 Elixir 实现 SM2/SM3/SM4（GM/T 0002/0003/0004-2012），无外部依赖

审查与修复（由 codespace 内 pi 完成，提交 `b16f533` 已推送）：

| 文件 | 修复内容 |
| --- | --- |
| `lib/sm2.ex` | 严重死循环：私钥 `d = n-1` 时 `sign/2` 无限挂起 → 校验收紧为 `[1, n-2]`（GM/T 0003-2012） |
| `lib/guomi/sm2/curve.ex` | 同修复 `generate_private_key` + `sign_with_e` 防御 `mod_inv=0` 返回 `:invalid_key`；删除死代码 `decode_public/1`、`private_key_to_int/1` |
| `mix.exs` / `mix.lock` | CI 必挂项：coverage job 用了不存在的 `mix test --coveralls` → 增加 `excoveralls` 依赖 |
| `.github/workflows/ci.yml` | 改为 `MIX_ENV=test mix coveralls.json` |
| `test/sm2_test.exs` | 新增回归测试：`n-1` 立即返回 `:invalid_key`、私钥范围断言 |
| `.gitignore` | 忽略 `.reasonix/`，删除已提交的工具产物 |

验证：`mix test` 114 个全过、编译 0 警告、format/credo 通过、OpenSSL 交叉验证一致。

## 6. 多仓库权限（Codespaces 原生机制）

Codespace 创建时注入的 `GITHUB_TOKEN` 是细粒度令牌，**git 协议层只授权源仓库**（即创建该 codespace 的仓库）。推送到其他仓库会报 `Permission to <owner>/<repo>.git denied`（403），即使 REST API 的 `permissions` 字段显示有 push 权限——该字段对 codespace token 有误导性，以实际 `git push` 结果为准。

### 在源仓库中添加 devcontainer.json 文件

首先，在你的**源仓库**（即用来创建当前 Codespace 的那个仓库）中，创建一个 `.devcontainer` 目录，并在该目录下新建一个 `devcontainer.json` 文件。

编辑 `devcontainer.json` 文件：在 `devcontainer.json` 文件中，使用 `repositories` 对象来指定需要额外权限的仓库及对应的权限：

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

- `contents: write` 即可支持 `git push`；按需可追加 `issues`、`pull_requests` 等细粒度权限。
- 提交并推送该文件到源仓库。

### 生效条件与注意

- 权限变更在 **Codespace 重建**（重新创建 codespace）时生效——token 在创建时铸造，当前会话的 token 不包含新权限；重建后 `git push` 目标仓库**原生可用**，无需任何额外凭据配置。
- 打开新 codespace 时 GitHub 可能弹出额外仓库授权确认（同一 owner 通常自动放行）。
- 与 7.1 的 token 注入方案对比：devcontainer `repositories` 是**官方原生机制**，无需维护 ghp token；7.1 仅作为 token 过期时的临时手段。

## 7. 踩坑记录

### 7.1 Codespace 内 gh 未登录，无法 push

- 现象：`gh auth status` 显示 `You are not logged into any GitHub hosts`，`git push` 失败。
- 原因：Codespace 创建时注入的临时 `GITHUB_TOKEN` 有时效（约 8 小时）。该 codespace 创建后长期 Shutdown，token 已过期；重启后引导程序不会重新注入，导致 `gh` 无凭据。
- 解决：把本地已登录的 `ZeroMarker` token 注入 codespace：

```bash
# 本地导出 token（不要提交到仓库）
python3 -c "import yaml; d=yaml.safe_load(open('/root/.config/gh/hosts.yml')); print(d['github.com']['oauth_token'])" > /tmp/gh_token.txt
gh codespace ssh -c <codespace名> -- bash -c 'cat > /tmp/gh_token.txt' < /tmp/gh_token.txt
# codespace 内登录并配置 git 凭据
gh codespace ssh -c <codespace名> -- bash -s < /tmp/gh_login.sh   # 内容: gh auth login --with-token < /tmp/gh_token.txt && gh auth setup-git
```

- 预防：push 前先 `gh auth status`；或直接重建 codespace 让引导程序注入新 token；或在 codespace 内交互式 `gh auth login`。

### 7.2 ssh 传参引号被剥离

`gh codespace ssh -- bash -c '...'` 中单引号可能丢失（表现为命令行为怪异、报 usage 帮助等）。规避：写脚本 + `bash -s < script.sh`，或避免复杂引号。

### 7.3 git 仓库报 "not a git repository"

codespace 默认 shell 环境下直接 `cd <repo> && git status` 偶发失败（工作目录未切换成功）。规避：用绝对路径 + `git -C <path>`，或 `GIT_DIR=/abs/.git GIT_WORK_TREE=/abs`。

## 8. 待办 / 后续

- [ ] 定期 `gh auth status` 检查 codespace 登录态
- [ ] 观察 guomi 推送后 CI 结果（run `30995116577`）
- [ ] agent 项目（/workspaces/agent）已落后远端 1 个提交（`63d1334..9b64b60`），需 pull 同步
