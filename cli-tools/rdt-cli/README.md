# rdt-cli（Reddit CLI）

[`rdt-cli`](https://github.com/public-clis/rdt-cli) 是一个 Reddit 命令行工具，基于反向工程 API（`.json` 后缀公开接口 + 少量 OAuth 写接口）实现浏览 Feed、阅读帖子与评论树、搜索、点赞/收藏/订阅/评论等互动（Apache-2.0 协议，Python 3.10+，命令名 `rdt`）。与 xiaohongshu-cli、bilibili-cli、twitter-cli 同作者系列工具。

- 版本：仓库 main 为 **0.4.2**，PyPI 最新发布为 **0.4.1**（仓库领先于 PyPI，见下方「注意事项」）
- 仓库地址注意：README 内的链接仍指向 `jackwener/rdt-cli`，实际仓库为 `public-clis/rdt-cli`

## 适合场景

- 在终端浏览首页 Feed、Popular、/r/all 或纯订阅 Feed（`--subs-only`，无算法推荐）。
- 浏览任意 subreddit（排序/时间过滤）、查看子版块信息。
- 阅读帖子与评论树，`--expand-more` 展开更多评论。
- 全文搜索（支持限定子版块、排序、时间过滤），结果导出 CSV / JSON。
- 查看用户资料、发帖/评论历史、自己的收藏与点赞列表。
- 点赞/踩、收藏、订阅/退订、评论等互动操作。
- 让 Codex、Claude Code、pi 等 AI Agent 通过命令行读取或操作 Reddit。
- 用 `--yaml` / `--json` / `--compact` 结构化输出串联 `jq` 或直接喂给 LLM。

## 安装

需要 Python 3.10+，推荐用 `uv tool` 或 `pipx`：

```bash
uv tool install rdt-cli
# 或：pipx install rdt-cli
```

升级到最新版：

```bash
uv tool upgrade rdt-cli
# 或：pipx upgrade rdt-cli
```

从源码安装（可拿到 0.4.2，比 PyPI 新）：

```bash
git clone https://github.com/public-clis/rdt-cli.git
cd rdt-cli
uv sync
```

## 认证

浏览器 Cookie 提取（Reddit 无扫码登录）：

1. **已保存 Cookie** — 从 `~/.config/rdt-cli/credential.json` 加载
2. **浏览器 Cookie** — 自动检测已安装浏览器并提取（基于 browser_cookie3，支持 Chrome、Firefox、Edge、Brave、Arc、Chromium、Opera、Vivaldi、Safari、LibreWolf 等）

```bash
rdt login          # 自动尝试所有浏览器，取第一个有有效 Cookie 的
rdt status         # 检查登录状态与能力
rdt whoami         # 用户资料（karma、账号年龄）
rdt logout         # 清除缓存 Cookie
```

Cookie 默认 **7 天**有效，过期后自动尝试从浏览器刷新；浏览器提取失败则带警告沿用旧 Cookie。

**认证要求分级**（重要）：

| 级别 | 命令 |
| --- | --- |
| 需要登录（`require_auth`，未登录直接退出码 1） | `feed`、`saved`、`upvoted`、`whoami`、`upvote`、`save`、`subscribe`、`comment` |
| 可选登录（`optional_auth`，公开接口即可用） | `popular`、`all`、`sub`、`sub-info`、`user`、`user-posts`、`user-comments`、`read`、`show`、`search`、`export` |

也就是说，**读类命令大多无需登录**即可使用。

## 常用命令

### 浏览

```bash
rdt feed                                   # 首页 Feed（需要登录）
rdt feed --subs-only                       # 纯订阅 Feed（无算法，按时间排序）
rdt feed --subs-only -n 5 --max-subs 10    # 每个 sub 取 5 条、最多 10 个 sub
rdt popular                                # /r/popular
rdt all                                    # /r/all
rdt sub python                             # 浏览子版块（默认 hot）
rdt sub programming -s top -t week         # 排序 + 时间过滤
rdt sub-info python                        # 子版块信息（订阅数、在线数、简介）
rdt user spez                              # 用户资料（post/comment karma、账号年龄）
rdt user-posts spez -n 10                  # 用户发帖
rdt user-comments spez -n 10               # 用户评论
rdt saved -n 20                            # 我的收藏（需要登录）
rdt upvoted -n 20                          # 我的点赞（需要登录）
```

> `feed --subs-only` 与 `--after` 互斥：同时传入时会打印警告并忽略 `--after`。

### 阅读

```bash
rdt read 1abc123                       # 按帖子 ID 阅读
rdt read 1abc123 --expand-more         # 展开顶层 "more comments"
rdt read 1abc123 -s top -n 50          # 评论排序 + 条数
rdt show 3                             # 读最近一次列表里的第 3 条
rdt show 3 -s new --expand-more        # 展开缓存帖子里的更多评论
rdt open 3                             # 在浏览器打开（也接受帖子 ID 或 URL）
```

- `read` / `show` 的评论排序 `-s` 取值：`best`（默认）、`top`、`new`、`controversial`、`old`、`qa`。
- `--expand-more` 会额外请求 `/api/morechildren` 并把展开的评论按父节点挂回评论树，同时更新剩余未展开计数。
- `show` 的短索引来自缓存，缓存为空或越界时会提示先运行 `rdt feed` / `rdt sub` / `rdt search`。

### 搜索与导出

```bash
rdt search "python async"                 # 全局搜索
rdt search "rust vs go" -r programming    # 限定子版块
rdt search "ML" -s top -t year            # 排序 top、时间最近一年
rdt search "AI" -n 50 -o results.json     # 结果存文件
rdt search "rust" --compact --json        # 紧凑 Agent 输出

rdt export "python tips" -n 100 -o tips.csv        # 导出 CSV（默认格式）
rdt export "rust" --format json -o results.json    # 导出 JSON
```

`export` 会自动翻页直到凑够 `-n/--count`（默认 50，每页 25 条），CSV 字段为 `title, subreddit, author, score, num_comments, url, permalink`，且以 `utf-8-sig` 写出（Excel 友好）。未指定 `-o` 时直接输出到 stdout。

### 互动（需要登录）

```bash
rdt upvote 3                           # 点赞列表第 3 条（也接受帖子 ID）
rdt upvote 3 --down                    # 点踩
rdt upvote 3 --undo                    # 取消投票
rdt save 3                             # 收藏
rdt save 3 --undo                      # 取消收藏
rdt subscribe python                   # 订阅 r/python
rdt subscribe python --undo            # 退订
rdt comment 3 "Great post!"            # 评论
rdt comment 1abc123 "Thanks"           # 按 ID 评论
```

互动命令**不支持** `--json` / `--yaml`，只输出 Rich 结果（走 stderr）。

### 短索引导航（Short-Index）

`feed` / `popular` / `all` / `sub` / `user-posts` / `user-comments` / `saved` / `upvoted` / `search` 等列表命令后，最新列表按序号缓存在 `~/.config/rdt-cli/index_cache.json`：

```bash
rdt sub python
rdt show 1        # 阅读第 1 条
rdt open 1        # 浏览器打开
rdt upvote 1      # 点赞
rdt save 1        # 收藏
rdt comment 1 "好帖"
```

缓存同时保存每条帖子的 `id`、`name`（`t3_xxx`）与 `permalink`，因此 `show` / `open` / 互动命令都能按序号工作。空列表会清空缓存，避免误用旧结果。

## 参数速查

### 列表命令公共参数

`feed`、`popular`、`all`、`sub`、`user-posts`、`user-comments`、`saved`、`upvoted`、`search` 支持：

| 参数 | 说明 |
| --- | --- |
| `-n, --limit N` | 条数（默认 25；Reddit 接口实际单页最多约 100，代码里 `MAX_LIMIT = 100` 只是常量、未强制校验） |
| `--after CURSOR` | 翻页游标，Rich 输出底部会提示下一条命令 |
| `--json` / `--yaml` | 结构化输出（带 envelope） |
| `-o, --output FILE` | 把结构化结果写入文件（**文件内容同样带 envelope**，按扩展名决定 JSON 或 YAML），不打印到 stdout |
| `-c, --compact` | 精简输出：列表命令去掉 Reddit 原始 listing 包装（`kind`/`data.children`/`after`），`data` 变成帖子对象数组；`read`/`show` 换成精简帖子字段并把评论树拍平成带 `depth` 的数组。未同时指定 `--json/--yaml` 时自动按 YAML 输出 |
| `--full-text` | 标题不截断（默认截断到 50 字符，`--full-text` 允许到 200） |

### 取值速查

| 类别 | 取值 |
| --- | --- |
| 列表排序 `-s`（`sub` 等） | `hot`（默认）、`new`、`top`、`rising`、`controversial`、`best` |
| 搜索排序 `-s` | `relevance`（默认）、`hot`、`top`、`new`、`comments` |
| 时间过滤 `-t` | `hour`、`day`、`week`、`month`、`year`、`all`（搜索默认 `all`） |
| 评论排序 `-s`（`read`/`show`） | `best`（默认）、`top`、`new`、`controversial`、`old`、`qa` |
| `export --format` | `csv`（默认）、`json` |

### 全局参数

| 参数 | 说明 |
| --- | --- |
| `-v, --verbose` | 输出请求 URL 与耗时等 INFO 日志 |
| `--version` | 显示版本 |

## 输出与脚本化

所有 `--json` / `--yaml` 输出使用统一 envelope（`ok/schema_version/data/error`，见 [SCHEMA.md](https://github.com/public-clis/rdt-cli/blob/main/SCHEMA.md)）：

```yaml
ok: true
schema_version: "1"
data: { ... }
```

要点：

- **Rich 人类可读输出走 stderr**，stdout 只承载结构化数据，因此 `rdt search X --json | jq .data` 不会被表格污染。
- **Agent 优先用 `--yaml --compact`**：更省 token。stdout 不是 TTY 时默认自动输出 YAML，可用 `OUTPUT=yaml|json|rich|auto` 覆盖。
- `--compact` 仍是同一套 envelope，只是换了 `data` 的形状，访问路径要写成 `.data[...]`：
  - 列表命令：`data` 为帖子对象数组（字段不裁剪，省的是原始 listing 的包装与重复嵌套），**同时会丢掉翻页游标**，需要 `--after` 时不要用 `--compact`；
  - `read` / `show`：`data` 为精简帖子字段 + 拍平的评论数组（每条带 `depth`，`[more]` 占位评论会被跳过）。
- `-o FILE` 写出的文件同样带 envelope，用 `jq` 读时同样要取 `.data`；只有 `export` 是例外——它写出裸 CSV／JSON 数组，没有 envelope。
- 结构化 payload 位置：
  - 列表类命令 → `data` 为 Reddit 原始 listing
  - `status` → `data.authenticated`、`data.cookie_count`、`data.source`、`data.username`、`data.capabilities`、`data.modhash_present`、`data.error` 等
  - `whoami` → `data` 直接是用户资料（`name`、`link_karma`、`comment_karma`、`total_karma`、`created_utc`、`is_gold`、`is_mod`），并额外带 `data._session.{capabilities, modhash_present}`
    （注意：仓库 SCHEMA.md 写的是 `data.user`，与实际实现不符，以实际输出为准）
- 结构化错误码（`error.code`）：

  | 错误码 | 含义 |
  | --- | --- |
  | `not_authenticated` | Cookie 缺失或会话过期 |
  | `rate_limited` | 触发 Reddit 限速 |
  | `not_found` | 子版块/用户/帖子不存在 |
  | `forbidden` | 私有子版块或被拉黑 |
  | `api_error` | 上游 Reddit 接口报错 |
  | `unknown_error` | 其他未归类错误 |

```bash
rdt status --json | jq '.data | {authenticated, cookie_count, username}'
rdt search "rust" --compact --json | jq '.data[].title'
rdt sub python -n 5 --json | jq '.data.children[].data | {title, score}'
rdt export "python tips" -n 100 -o tips.csv
```

## AI Agent 使用建议

- 执行需认证命令前先确认已认证（读类命令可跳过）。注意 `rdt status` 无论是否登录**都以退出码 0 结束**，必须读 `data.authenticated` 判断：

  ```bash
  rdt status --json 2>/dev/null | jq -r '.data.authenticated' | grep -q true \
    && echo "AUTH_OK" || echo "AUTH_NEEDED"
  ```

  未认证时引导用户：浏览器登录 reddit.com → `rdt login`。
- **不要并行请求**。内置限速是账号保护：读请求间隔默认 1.0s + 高斯抖动（`gauss(0.3, 0.15)`），约 5% 请求额外等待 2–5s；写请求基础间隔提高到 2.5s，且每次写操作后再随机 sleep 1.5–4s。批量任务请在 CLI 调用之间自行加 `time.sleep()`。
- 429/5xx 与网络错误自动指数退避重试（最多 3 次），无需手动处理。
- 反风控实现：session 内一致的 macOS Chrome 133 指纹（UA / `sec-ch-ua` / `sec-ch-ua-mobile` / `sec-ch-ua-platform` 对齐，并带 `Sec-Fetch-*` 头），Reddit 响应的 `Set-Cookie` 会自动合并回会话。
- 互动命令（`upvote`/`save`/`subscribe`/`comment`）没有结构化输出，Agent 只能靠退出码与 stderr 文本判断成功与否。
- **Cookie 是敏感信息**：优先本地浏览器提取，不要要求用户在聊天里贴原始 Cookie。
- 内置 [`SKILL.md`](https://github.com/public-clis/rdt-cli/blob/main/SKILL.md)，可通过 [Skills CLI](https://github.com/vercel-labs/skills) 安装：

  ```bash
  npx skills add jackwener/rdt-cli -g
  ```

  或手动安装：

  ```bash
  mkdir -p .agents/skills
  git clone https://github.com/public-clis/rdt-cli.git .agents/skills/rdt-cli
  ```

  > ClawHub 安装方式已弃用，不再支持。

## 常见问题

| 报错 / 现象 | 原因 | 解决 |
| --- | --- | --- |
| `No Reddit cookies found` | 没有可用的浏览器登录态 | 先在浏览器打开 reddit.com 并登录，再 `rdt login` |
| `database is locked` | 浏览器 Cookie 数据库被锁 | 关闭浏览器后重试 `rdt login` |
| `Session expired` | Cookie 过期 | `rdt logout && rdt login` 刷新 |
| `Rate limited` | 触发限速 | 等待重试，内置指数退避会自动处理 |
| `⚠️ Not logged in`（退出码 1） | 对需要登录的命令未认证 | `rdt login`，或改用公开的读类命令 |
| `rdt status` 退出码为 0 但未登录 | `status` 设计上不报错退出 | 解析 `data.authenticated`（见上方 Agent 建议），不要只看退出码 |
| `403 / forbidden` | 私有子版块或被拉黑 | 换子版块；已登录账号也需有访问权限 |
| `Index 3 out of range` | 短索引缓存为空或越界 | 先运行 `rdt feed` / `rdt sub` / `rdt search` 生成缓存 |
| 请求较慢 | 内置限速（~1s + 高斯抖动） | 正常现象，模拟人类浏览避免触发限速，勿绕过 |

## 注意事项

- **PyPI 落后于仓库**：`uv tool install rdt-cli` 装到的是 0.4.1，仓库 main 已是 0.4.2；`SKILL.md` 里标注的版本仍是 0.4.0。需要最新修复时从源码安装。
- 仓库 README 与 `SKILL.md` 中的 clone / `npx skills add` 地址仍写作 `jackwener/rdt-cli`，实际仓库在 `public-clis/rdt-cli`。
- 使用 `.json` 后缀公开接口（非官方 API Key/OAuth 应用），接口变动或风控策略调整可能导致失效，需跟随版本升级。

## 限制

- **无私信**、**无直播/流媒体**功能。
- **无媒体下载**能力（图片/视频）。
- **单账号**：同一时间只有一套 Cookie。
- 写操作限于点赞/踩、收藏、订阅、发评论，**不支持发帖、编辑或删除**。
- 互动与收藏/点赞列表命令无结构化输出。
- 限速：内置抖动延迟保护账号，勿绕过。

## 参考链接

- [GitHub 仓库](https://github.com/public-clis/rdt-cli)
- [SCHEMA.md（输出契约）](https://github.com/public-clis/rdt-cli/blob/main/SCHEMA.md)
- [SKILL.md（Agent Skill）](https://github.com/public-clis/rdt-cli/blob/main/SKILL.md)
- [PyPI 包](https://pypi.org/project/rdt-cli/)
- 同系列工具：xiaohongshu-cli、bilibili-cli、twitter-cli、discord-cli、tg-cli
