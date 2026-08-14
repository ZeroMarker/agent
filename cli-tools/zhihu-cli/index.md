# zhihu-cli

[`zhihu-cli`](https://developer.zhihu.com/profile) 是知乎开放平台面向 Agent 的统一命令行入口，由知乎官方发布。CLI 封装了知乎搜索、全网搜索、热榜、知乎直答，以及当前 Access Secret 所属账号的创作、关注与收藏等能力，适合人类用户和 AI Agent 使用。

## 适合场景

- 搜索知乎回答、文章、经验、观点和社区真实声音，获取原文链接。
- 搜索知乎之外的全网来源（新闻、官网、权威站点）做事实核查。
- 快速了解当前知乎热点议题（热榜）。
- 调用知乎直答获得检索增强的综合答案。
- 查看当前知乎账号自己的创作、关注与收藏。
- 通过官方 Skill 让 Codex、Claude Code、pi 等 AI Agent 直接调用。

## 安装

Skill 包不携带 CLI 二进制。安装 Skill 后，由 Skill 内置的 setup 脚本从官方 HTTPS manifest 下载当前平台 CLI，校验域名、文件大小、SHA-256、归档结构和二进制自报版本后安装到用户数据目录，不使用 sudo，也不修改 PATH。

```bash
# 1. 安装 Skill（pi 全局技能目录）
mkdir -p ~/.pi/agent/skills
cp -r <解压后的 zhihu 目录> ~/.pi/agent/skills/zhihu

# 2. 状态检查（无副作用）
bash ~/.pi/agent/skills/zhihu/scripts/run.sh status

# 3. 获得授权后安装 CLI
bash ~/.pi/agent/skills/zhihu/scripts/setup.sh
```

Linux 默认安装到 `${XDG_DATA_HOME:-$HOME/.local/share}/zhihu-cli`，可用绝对路径 `ZHIHU_CLI_HOME` 覆盖。Windows 使用 `scripts/run.ps1` / `scripts/setup.ps1`。

`setup` 可重复执行；本地 CLI 等于或高于 Skill 最低版本时直接复用。日常更新：

```bash
zhihu-cli upgrade --check
zhihu-cli upgrade
zhihu-cli upgrade --rollback
```

## 初始化与认证

首次使用需要申请开放平台 Access Secret：

1. 打开 <https://developer.zhihu.com/profile>，登录知乎账号。
2. 点击「申请新 Access Secret」，把生成的 Secret 交给 Agent。

通过 stdin 配置凭证（避免进入进程参数和 Shell 历史）：

```bash
printf '%s' "$ZHIHU_ACCESS_SECRET" | zhihu-cli auth set --secret-stdin
```

查看和清除凭证：

```bash
zhihu-cli auth status          # 本地查看，不联网
zhihu-cli auth status --verify # 在线验证（消耗少量接口额度）
zhihu-cli auth logout          # 只删除本机密钥链中的 Secret
```

凭证读取顺序：`ZHIHU_ACCESS_SECRET` 环境变量 → 操作系统密钥链。headless 环境（SSH/CI/容器）没有 Secret Service 会话时，由宿主 Secret Store 注入环境变量：

```bash
export ZHIHU_ACCESS_SECRET='<access-secret>'
```

Access Secret 是不透明字符串，CLI 不做格式假设。不要在回复、日志或项目文件中重复完整 Secret；泄露后在开放平台个人中心删除并重新申请。

## 常用命令

### 搜索知乎

```bash
zhihu-cli search zhihu --query "AI Agent Memory" --count 10
```

返回知乎社区原始内容及链接，适合阅读原文、研究、保留证据。`--count` 默认 10，范围 1-10。

### 搜索全网

```bash
zhihu-cli search global --query "AI Agent Memory" --count 10 --search-db all
```

`--search-db` 可选 `all` / `realtime` / `static`；高级筛选（站点、时间等）用 `--filter` 传 API filter 表达式。

### 知乎热榜

```bash
zhihu-cli hot --limit 20
```

`--limit` 默认 30，范围 1-30。热榜用于发现议题，不等于事实核查；需要解释或核实时继续搜索。

### 知乎直答

```bash
zhihu-cli answer --query "如何理解 AI Agent"
zhihu-cli answer --query "..." --model zhida-thinking-1p5
zhihu-cli answer --query "..." --stream --output text   # 终端打字机
```

模型可选 `zhida-fast-1p5`（默认）、`zhida-thinking-1p5`、`zhida-agent`。深度研究、事实核查和观点比较不要用直答替代搜索。

### 我的创作、关注与收藏

```bash
zhihu-cli me contents --type all --sort ts --order desc --offset 0 --limit 20
zhihu-cli me followees --offset 0 --limit 20
zhihu-cli me favorites recent --limit 20
zhihu-cli me favorites lists --limit 20
zhihu-cli me favorites items --url-token 123456789 --offset 0 --limit 20
```

- `--type` 可选 `all/answer/article/zvideo/pin/question`；`--limit` 范围 1-50。
- 创作接口只返回标题与摘要，`Summary` 不是完整正文。
- `recent` 只表示近期收藏，没有分页；收藏夹列表没有 Paging，CLI 只提供 `--limit`。
- 分页响应用 `Paging.IsEnd` / `Paging.NextOffset`，CLI 不自动拉取全部分页。
- 所有 `me` 命令只查询当前 Access Secret 所属账号，不接受 OAuth Token 或用户 ID。

## 输出与脚本化

stdout 只输出结果，stderr 只输出诊断。成功时 CLI 原样保留服务端原始 JSON，不裁剪字段、不修改结构：

```bash
zhihu-cli search zhihu --query "AI Agent" --count 10 --pretty
zhihu-cli search zhihu --query "AI Agent" --count 10 | jq -r '.data[].Url'
zhihu-cli hot --limit 10 | jq '[.data[] | select(.Heat > 100000)]'
```

全局参数：`--timeout <duration>`（如 `10s`、`120s`）、`--pretty`（美化 JSON）、`--verbose`（stderr 输出不含凭证的诊断）。

机器可解析的能力清单（无需 Access Secret）：

```bash
zhihu-cli capabilities
zhihu-cli search global --help   # 每级命令都有帮助
```

## 错误处理

CLI 自身错误返回稳定 JSON：`{"ok":false,"error":{"source":"cli","code":"...","message":"...","action_url":"..."}}`。

| 错误码 | 处理方式 |
|---|---|
| `AUTH_REQUIRED` | 打开 `action_url` 申请 Access Secret，再 `auth set --secret-stdin` |
| `AUTH_INVALID` | 重新检查或申请 Access Secret，不要回显旧值 |
| `KEYCHAIN_UNAVAILABLE` | 通过宿主 Secret Store 注入 `ZHIHU_ACCESS_SECRET` |
| `ENV_SHADOWS_KEYCHAIN` | 环境变量正在覆盖刚保存的密钥链凭证 |
| 服务端 `Code: 30001` | 频率限制，停止主动重试 |
| 服务端 `Code: 30002` | 配额耗尽，告知受影响能力和恢复条件 |
| `NETWORK_ERROR` / `TIMEOUT` | 仅对幂等的搜索和热榜做有限重试 |

退出码：`0` 成功；`2` 参数错误；`3` 鉴权缺失/无效/来源冲突；`4` 配额或频率限制；`5` 网络错误；`6` 服务端或未知协议错误；`7` 密钥链不可用；`8` 安装/升级/完整性校验失败。内容 GET API 可能在 HTTP 200 中返回业务错误，必须以 CLI 非零退出码判断失败，不能把 `Code: 20001` 当成空结果。

## 安全要求

- 不在回复、stdout、stderr、日志、Shell 历史或项目文件中重复完整 Access Secret。
- 不把 Access Secret 写入 Skill 内部；Skill 升级不会覆盖已安装 CLI 或凭证。
- 只调用完成任务所需的最小组合；本人数据（关注/收藏）不写入文件或长期记忆。
- Access Secret 只发送到 `https://developer.zhihu.com`，不发送到其他主机。

## 作为 AI Agent Skill 使用

zhihu-cli 官方 Skill（`zhihu-cli-skill`）遵循 [Agent Skills 标准](https://agentskills.io/specification)。pi 中安装到全局技能目录后自动发现：

```bash
mkdir -p ~/.pi/agent/skills
cp -r zhihu ~/.pi/agent/skills/zhihu
```

每次 Session 首次激活 Skill 时，先运行一次无副作用的状态检查：

```bash
bash ~/.pi/agent/skills/zhihu/scripts/run.sh status
```

根据返回 JSON 的 `installed`、`auth.configured`、`next_action` 决定下一步（安装 CLI / 引导申请 Access Secret / 直接处理任务）。本次任务所有调用都使用 status 或 setup 返回的绝对 `binary_path`，不依赖 PATH 中来源不明的 `zhihu-cli`。

## 参考链接

- [开放平台个人中心（申请 Access Secret / 用量统计）](https://developer.zhihu.com/profile)
- [CLI 使用文档](https://developer-cdn.zhihu.com/zhihu-cli/releases/stable/skill/zhihu-cli-skill.zip)（Skill 包内 `references/cli.md`）
- [Agent Skills 标准](https://agentskills.io/specification)
