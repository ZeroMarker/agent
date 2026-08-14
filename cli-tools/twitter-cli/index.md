# twitter-cli

[`twitter-cli`](https://github.com/public-clis/twitter-cli) 是一个终端优先的 Twitter/X CLI 工具，无需 API Key 即可读取时间线、书签、用户主页，并支持发推、回复、引用转推等写操作。它内置反风控机制（TLS 指纹伪装、请求时序随机化、写操作随机延迟），适合人类用户和 AI Agent 使用。

## 适合场景

- 在终端里刷「为你推荐」或「关注」时间线，看推文详情与回复。
- 在脚本中搜索、收藏、点赞、转推，或导出推文数据做分析。
- 让 Codex、Claude Code 等 AI Agent 通过命令行读取或发布 Twitter 内容。
- 抓取 Twitter 长文（Article）并导出为 Markdown。
- 使用 `--yaml` / `--json` 结构化输出串联 `jq` 等工具。

## 安装

需要 Python 3.8+，推荐用 `uv tool` 或 `pipx` 安装：

```bash
uv tool install twitter-cli
# 或：pipx install twitter-cli
```

定期升级到最新版本，避免因上游 GraphQL queryId 轮换导致接口异常：

```bash
uv tool upgrade twitter-cli
# 或：pipx upgrade twitter-cli
```

从源码安装：

```bash
git clone git@github.com:public-clis/twitter-cli.git
cd twitter-cli
uv sync
```

## 认证

认证优先级：

1. **环境变量**：`TWITTER_AUTH_TOKEN` + `TWITTER_CT0`。
2. **浏览器 Cookie 提取**（推荐）：自动从 Arc/Chrome/Edge/Firefox/Brave 提取全部 Twitter Cookie，更接近真实浏览器流量。

> 注意：写操作（发推、回复、引用）只给 `auth_token` + `ct0` 可能触发 226 错误（被识别为自动化行为），建议用浏览器 Cookie 提取。

```bash
# 检查认证状态
twitter status --yaml
twitter whoami

# 指定 Chrome profile 或浏览器优先级
TWITTER_CHROME_PROFILE="Profile 2" twitter feed
TWITTER_BROWSER=chrome twitter feed   # 支持: arc, chrome, edge, firefox, brave
```

命令行在加载 Cookie 后会做轻量校验，认证失败（401/403）会快速报错。

## 代理支持

设置 `TWITTER_PROXY` 环境变量即可：

```bash
export TWITTER_PROXY=http://127.0.0.1:7890
# 或 SOCKS5
export TWITTER_PROXY=socks5://127.0.0.1:1080
```

使用代理可以降低 IP 维度的风控风险。

## 常用命令

### 读取

```bash
# 时间线（默认 For You，-t following 切换关注时间线）
twitter feed
twitter feed -t following --max 50
twitter feed --filter              # 启用评分排序筛选
twitter feed --full-text           # rich table 里显示完整正文

# 书签
twitter bookmarks --max 30

# 搜索（支持 Top/Latest/Photos/Videos）
twitter search "AI agent" -t Latest --max 50
twitter search "topic" -o results.json

# 推文详情与回复
twitter tweet 1234567890
twitter tweet https://x.com/user/status/1234567890

# 打开上次列表里的第 N 条推文
twitter show 2
twitter show 2 --full-text

# Twitter 长文导出
twitter article 1234567890 --markdown --output article.md

# 列表时间线
twitter list 1539453138322673664 --cursor "<next-cursor>"

# 用户
twitter user elonmusk
twitter user-posts elonmusk --max 20
twitter likes elonmusk --max 30    # ⚠️ 2024 年 6 月起点赞已私密，仅能看自己的
twitter followers elonmusk --max 50
twitter following elonmusk --max 50
```

### 写入

```bash
# 发推 / 带图 / 回复 / 引用
twitter post "Hello from twitter-cli!"
twitter post "Gallery" -i a.png -i b.jpg        # 最多 4 张图
twitter reply 1234567890 "Nice!" -i screenshot.png
twitter quote 1234567890 "Look" -i chart.png

# 删除 / 点赞 / 转推 / 书签 / 关注
twitter delete 1234567890
twitter like 1234567890
twitter retweet 1234567890
twitter bookmark 1234567890
twitter follow elonmusk --json
```

图片支持 JPEG/PNG/GIF/WebP，单张不超过 5 MB。

## 输出与脚本化

- 默认 rich table 适合终端交互阅读。
- `--full-text`：在列表视图显示完整正文（不影响结构化输出）。
- `-c` / `--compact`：每条约 140 字截断，比 `--json` 少约 80% token，适合喂给 LLM。
- `--yaml` / `--json`：结构化输出，非 TTY 时默认输出 YAML。
- `-o file`：把结果保存到文件。

```bash
twitter feed --json | jq '.data[0].text'
twitter search "AI safety" --max 20 --json | jq '[.data[] | select(.metrics.likes > 100)]'
twitter -c feed -t following --max 30    # token 高效模式
```

结构化输出的字段契约见仓库内的 [`SCHEMA.md`](https://github.com/public-clis/twitter-cli/blob/main/SCHEMA.md)。

## 配置

在工作目录创建 `config.yaml` 可调整默认行为：

```yaml
fetch:
  count: 50              # 未传 --max 时的默认条数
filter:
  mode: "topN"           # "topN" | "score" | "all"
  topN: 20
  minScore: 50
  weights:
    likes: 1.0
    retweets: 3.0
    replies: 2.0
    bookmarks: 5.0
    views_log: 0.5
rateLimit:
  requestDelay: 2.5
  maxRetries: 3
  maxCount: 200
```

默认不启用排序筛选；传入 `--filter` 后按权重评分排序，公式：

```
score = likes_w * likes
      + retweets_w * retweets
      + replies_w * replies
      + bookmarks_w * bookmarks
      + views_log_w * log10(max(views, 1))
```

## 使用建议（防封号）

- 使用代理（`TWITTER_PROXY`），避免裸 IP 直连。
- 控制请求量，用 `--max 20` 而不是 `--max 500`。
- 避免频繁启动，每次启动都会访问 x.com 初始化反检测请求头。
- 优先使用浏览器 Cookie 提取，提供完整 Cookie 指纹。
- 避免数据中心 IP，住宅代理更安全。

## 常见问题

| 报错 | 原因 | 解决 |
| --- | --- | --- |
| `No Twitter cookies found` | 未认证 | 在浏览器登录 x.com，或手动设置环境变量；`-v` 查看提取诊断 |
| HTTP 226 | 被识别为自动化 | 改用浏览器 Cookie 提取，而不是仅环境变量 |
| HTTP 401/403 | Cookie 过期 | 重新登录 x.com 后重试 |
| HTTP 404 | queryId 轮换 | 重试，客户端会自动回退 queryId |
| HTTP 429 | 被限流 | 等待 15+ 分钟再试 |
| Error 187 | 重复推文 | 修改正文内容 |
| Error 186 | 推文超长 | 控制在 280 字符内 |

macOS Keychain 报 `Unable to get key for cookie decryption` 时：SSH 会话先执行 `security unlock-keychain ~/Library/Keychains/login.keychain-db`；本地终端在钥匙串访问中给 Terminal 添加访问权限。

## 限制

- 不支持视频/GIF 动画上传、私信、通知、投票。
- 单一账号：同一时间只使用一套凭证。
- 点赞已私密：`twitter likes` 只能查看自己的点赞。

## 作为 AI Agent Skill 使用

twitter-cli 内置 [`SKILL.md`](https://github.com/public-clis/twitter-cli/blob/main/SKILL.md)，可让 AI Agent 稳定调用。通过 [Skills CLI](https://github.com/vercel-labs/skills) 安装：

```bash
npx skills add public-clis/twitter-cli -y -g
```

或手动安装：

```bash
mkdir -p .agents/skills
git clone git@github.com:public-clis/twitter-cli.git .agents/skills/twitter-cli
```

## 参考链接

- [GitHub 仓库](https://github.com/public-clis/twitter-cli)
- [SKILL.md](https://github.com/public-clis/twitter-cli/blob/main/SKILL.md)
- [SCHEMA.md（结构化输出契约）](https://github.com/public-clis/twitter-cli/blob/main/SCHEMA.md)
- [PyPI 包](https://pypi.org/project/twitter-cli/)
