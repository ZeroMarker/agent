# MiniMax CLI（`mmx`）

[MiniMax-AI/cli](https://github.com/MiniMax-AI/cli) 是 MiniMax 开放平台的官方命令行工具，npm 包名为 `mmx-cli`，可执行命令为 `mmx`。它将文本、图像、视频、语音、图像理解与搜索能力放到终端中，适合脚本和 AI Agent 调用。

## 适合场景

- 通过终端批量生成图片、配音和视频素材。
- 将会议录音转为文本或字幕。
- 在 Agent 工作流中调用图像理解、搜索和多轮文本对话。
- 为已有编码 Agent 配置 MiniMax 模型。

## 安装与要求

需要 Node.js 18+；上游安装说明要求 MiniMax Token 套餐，具体能力和额度以对应区域平台为准。

```bash
npm install -g mmx-cli
mmx --help
mmx speech transcribe --help

# 更新 CLI
mmx update
```

若要让 Agent 发现官方 Skill，可另外安装：

```bash
npx skills add MiniMax-AI/cli -y -g
```

## 认证与区域

交互式登录可选择 OAuth 或粘贴 API Key：

```bash
mmx auth login

# 直接选择 OAuth 登录区域
mmx auth login --recommend --region cn
mmx auth login --recommend --region global

mmx auth status
mmx quota
```

脚本中可将宿主提供的 Key 显式传给 CLI：

```bash
mmx auth login --api-key "$MINIMAX_API_KEY"
```

这里的 `MINIMAX_API_KEY` 是示例 Shell 变量；当前源码不会自动读取它作为凭据，必须通过 `--api-key` 传入或先登录保存。API Key 登录会探测两个区域并选择可用区域。

| 区域 | 参数 | API 地址 |
|---|---|---|
| 国内版 | `--region cn` | `https://api.minimaxi.com` |
| 国际版 | `--region global` | `https://api.minimax.io` |

OAuth 和 API Key 都保存在 `~/.mmx/config.json`，两种登录方式互斥。认证状态以 `mmx auth status` 为准；刷新 OAuth 用 `mmx auth refresh`，退出用 `mmx auth logout`。凭据文件不要提交到仓库。

## 常用命令

### 文本与图像

```bash
mmx text chat --message "用中文解释这个项目的用途"
mmx text chat --system "你是技术编辑" --message "写一段发布说明" --stream
mmx text chat --message "user:你好" --message "assistant:你好！" --message "给我三个选题"
mmx text chat --messages-file messages.json --output json

mmx image "水彩风格的海边书店"
mmx image generate --prompt "极简山水插画" --n 3 --aspect-ratio 16:9 --out-dir ./images/
```

### 视频与异步任务

```bash
# 默认视频模型：等待生成并下载
mmx video generate --prompt "清晨的湖面，镜头缓慢向前" --download lake.mp4

# 提交后立即返回任务信息
mmx video generate --prompt "机器人正在画画" --async --output json
mmx video task get --task-id <任务ID>
mmx video download --file-id <文件ID> --out robot.mp4

# MiniMax-H3：显式指定模型和 API Key
mmx video generate --api-key "$MINIMAX_API_KEY" --model MiniMax-H3 --prompt "人物向前走" --image start.jpg
mmx video task get --task-id <任务ID> --model MiniMax-H3
```

异步提交成功不代表视频已经完成；保留返回的任务 ID，查询完成后再使用文件 ID 下载。H3 的任务查询也需指定对应模型。素材限制和模型参数见[上游视频说明](https://github.com/MiniMax-AI/cli/blob/main/README_CN.md#mmx-video)。

### 配音与音频转写

```bash
mmx speech voices
mmx speech synthesize --text "欢迎来到今天的节目" --out intro.mp3
mmx speech synthesize --text "Hello" --voice English_magnetic_voiced_man --speed 1.2 --out hello.mp3

mmx speech transcribe --file meeting.mp3
mmx speech transcribe --file meeting.mp3 --language zh --response-format verbose_json --output json
mmx speech transcribe --file meeting.mp3 --response-format srt --out meeting.srt
```

转写支持 wav、aiff、flac、m4a、mp3、aac、opus、ogg，上限为 50 MB / 500 秒。不指定语言时支持混合语言识别；`verbose_json` 可保留说话人与分段时间戳，字幕可选 `srt` 或 `vtt`。详见[语音命令说明](https://github.com/MiniMax-AI/cli/blob/main/README_CN.md#mmx-speech)。

### 图像理解与搜索

```bash
mmx vision photo.jpg
mmx vision describe --image https://example.com/photo.jpg --prompt "描述图片中的布局"
mmx search "MiniMax CLI"
mmx search query --q "MiniMax CLI" --output json
```

搜索接口单次最多返回 10 条结果，目前不支持分页；需要不同结果时调整查询词。

## 配置与脚本输出

```bash
mmx config show
mmx config set --key region --value cn
mmx config export-schema | jq .
mmx search query --q "AI Agent" --output json > search.json
```

当前源码在终端中默认输出文本，在管道或重定向中默认输出 JSON；脚本应显式使用 `--output json`。区域优先级为 `--region` → `MINIMAX_REGION` → 保存的区域 → `global`。可用配置键以 `config export-schema` 为准。

检查退出码判断调用是否成功：`0` 成功，`1` 通用错误，`2` 参数错误，`3` 认证错误，`4` 配额错误，`5` 超时，`6` 网络错误，`10` 内容过滤。认证或配额错误先处理登录/额度；视频超时后应先查询已提交任务状态。

## 为 Agent 配置 MiniMax

`mmx agent setup` 支持 Claude Code、Codex、Grok Build、OpenCode、Hermes 和 Pi。它会修改对应 Agent 的配置，保留其他设置，并在修改已有文件时创建备份。

```bash
# 先预览配置变更，不联网
mmx agent setup --agent codex --api-key "$MINIMAX_API_KEY" --region cn --dry-run

# 为指定 Agent 写入配置
mmx agent setup --agent codex --api-key "$MINIMAX_API_KEY" --region cn

# 交互式向导
mmx agent setup
```

交互模式还可选择安装兼容且未检测到的 Agent；非交互模式只写配置，命令不会启动 Agent。多 Agent 配置和安装细节见[上游说明](https://github.com/MiniMax-AI/cli/blob/main/README_CN.md#mmx-agent-setup)。

## 参考与验证范围

- [GitHub 仓库](https://github.com/MiniMax-AI/cli)
- [中文文档](https://github.com/MiniMax-AI/cli/blob/main/README_CN.md)
- [npm 包](https://www.npmjs.com/package/mmx-cli)
- [国内版平台](https://platform.minimaxi.com) / [国际版平台](https://platform.minimax.io)

本文基于 2026-09-30 读取的上游文档及源码（[提交 `06e47c7`](https://github.com/MiniMax-AI/cli/tree/06e47c70b76f419196678367dae62acca4c94076)）整理；未执行登录、付费生成或 Agent 配置写入。上游 `main` 可能领先 npm 发布版，实际参数以安装版本的 `mmx <命令> --help` 为准。
