# rdt-cli（Reddit CLI）

[`rdt-cli`](https://github.com/public-clis/rdt-cli) 是一个 Reddit 命令行工具，基于反向工程 API 实现浏览 Feed、阅读帖子与评论树、搜索、点赞/收藏/订阅/评论等互动（Apache-2.0 协议，Python 3.10+，命令名 `rdt`）。与 xiaohongshu-cli、bilibili-cli、twitter-cli 同作者系列工具。

## 适合场景

- 在终端浏览首页 Feed、Popular、/r/all 或纯订阅 Feed（`--subs-only`，无算法推荐）。
- 浏览任意 subreddit（排序/时间过滤）、查看子版块信息。
- 阅读帖子与评论树（语法高亮），`--expand-more` 展开更多评论。
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

定期升级，避免因版本过旧导致的 API 调用异常：

```bash
uv tool upgrade rdt-cli
# 或：pipx upgrade rdt-cli
```

从源码安装：

```bash
git clone git@github.com:jackwener/rdt-cli.git
cd rdt-cli
uv sync
```

## 认证

浏览器 Cookie 提取（Reddit 无扫码登录）：

1. **已保存 Cookie** — 从 `~/.config/rdt-cli/credential.json` 加载
2. **浏览器 Cookie** — 自动检测已安装浏览器并提取（支持 Chrome、Firefox、Edge、Brave）

```bash
rdt login          # 自动尝试所有浏览器，取第一个有有效 Cookie 的
rdt status         # 检查登录状态
rdt whoami         # 用户资料（karma、账号年龄）
rdt logout         # 清除缓存 Cookie
```

Cookie 有效期默认 **7 天**，过期后自动尝试从浏览器刷新；浏览器提取失败则带警告沿用旧 Cookie。阅读类命令无需登录，互动与首页 Feed 需要登录。

## 常用命令

### 浏览

```bash
rdt feed                              # 首页 Feed（需要登录）
rdt feed --subs-only                  # 纯订阅 Feed（无算法推荐）
rdt feed --subs-only -n 5 --max-subs 10   # 每 sub 限 5 条、最多 10 个 sub
rdt popular                           # Popular 热门帖子
rdt popular --full-text               # 显示完整标题
rdt all                               # /r/all
rdt sub python                        # 浏览子版块
rdt sub programming -s top -t week    # 排序 + 时间过滤
rdt sub-info python                   # 子版块信息（订阅数等）
rdt user spez                         # 用户资料
rdt user-posts spez                   # 用户发帖
rdt user-comments spez                # 用户评论
rdt saved                             # 我的收藏
rdt upvoted                           # 我的点赞
```

### 阅读

```bash
rdt read 1abc123                      # 按帖子 ID 阅读
rdt read 1abc123 --expand-more        # 展开顶层 "more comments"
rdt show 3 -s top                     # 阅读最近一次列表里的第 3 条（评论按 top 排序）
rdt open 3                            # 在浏览器打开
```

### 搜索与导出

```bash
rdt search "python async"             # 全局搜索
rdt search "rust vs go" -r programming  # 限定子版块
rdt search "ML" -s top -t year        # 排序 top、时间最近一年
rdt search "AI" -o results.json       # 结果存文件
rdt export "python tips" -n 100 -o tips.csv   # 导出 CSV
rdt export "rust" --format json -o results.json
```

### 互动（需要登录）

```bash
rdt upvote 3                          # 点赞列表第 3 条
rdt upvote 3 --down                   # 点踩
rdt upvote 3 --undo                   # 取消投票
rdt save 3 --undo                     # 收藏 / 取消收藏
rdt subscribe python --undo           # 订阅 / 退订 r/python
rdt comment 3 "Great post!"           # 评论（内置 1.5–4s 限速延迟）
```

### 短索引导航（Short-Index）

`feed` / `popular` / `all` / `sub` / `search` 等列表命令后，最新列表缓存在 `~/.config/rdt-cli/index_cache.json`，可用序号直接操作：

```bash
rdt sub python
rdt show 1        # 阅读第 1 条
rdt open 1        # 浏览器打开
rdt upvote 1      # 点赞
rdt save 1        # 收藏
rdt comment 1 "..."
```

空列表会清空缓存，避免误用旧结果。

## 输出与脚本化

所有 `--json` / `--yaml` 输出使用统一 envelope（`ok/schema_version/data/error`，见 [SCHEMA.md](https://github.com/public-clis/rdt-cli/blob/main/SCHEMA.md)）：

```yaml
ok: true
schema_version: "1"
data: { ... }
```

- **Agent 优先用 `--yaml` + `--compact`**：更省 token。stdout 不是 TTY 时默认自动输出 YAML，可用 `OUTPUT=yaml|json|rich|auto` 覆盖。
- Rich 可读输出走 **stderr**，不污染 stdout 的结构化数据。
- `-o FILE` 可在任意列表命令上把结果存为文件；`--full-text` 显示完整标题（默认截断）。

```bash
rdt status --json | jq '.data'
rdt search "rust" --compact --json | jq '.data.items[].title'
rdt export "python tips" -n 100 -o tips.csv
```

## AI Agent 使用建议

- 执行前先确认已认证（阅读类命令除外）：

  ```bash
  rdt status --yaml >/dev/null && echo "AUTH_OK" || echo "AUTH_NEEDED"
  ```

  未认证时引导用户：浏览器登录 reddit.com → `rdt login`。
- **不要并行请求**。内置高斯抖动延迟（均值 ~1s，σ=0.3）是有意的账号保护；评论等写操作还有 1.5–4s 限速延迟。批量任务在 CLI 调用间加 `time.sleep()`。
- 429/5xx 与网络错误自动指数退避重试（最多 3 次），无需手动处理。
- 反风控实现：session 内一致的 Chrome 133 指纹（UA / sec-ch-ua 对齐），Reddit 响应的 `Set-Cookie` 自动合并回会话。
- 内置 [`SKILL.md`](https://github.com/public-clis/rdt-cli/blob/main/SKILL.md)，可通过 [Skills CLI](https://github.com/vercel-labs/skills) 安装：

  ```bash
  npx skills add jackwener/rdt-cli -g
  ```

  或手动安装：

  ```bash
  mkdir -p .agents/skills
  git clone git@github.com:jackwener/rdt-cli.git .agents/skills/rdt-cli
  ```

  > ClawHub 安装方式已弃用，不再支持。

## 常见问题

| 报错 | 原因 | 解决 |
| --- | --- | --- |
| `No Reddit cookies found` | 没有可用的浏览器登录态 | 先在浏览器打开 reddit.com 并登录，再 `rdt login` |
| `database is locked` | 浏览器 Cookie 数据库被锁 | 关闭浏览器后重试 `rdt login` |
| `Session expired` | Cookie 过期 | `rdt logout && rdt login` 刷新 |
| `Rate limited` | 触发限速 | 等待重试，内置指数退避会自动处理 |
| 请求较慢 | 内置高斯抖动延迟（~1s） | 正常现象，模拟人类浏览避免触发限速，勿绕过 |

## 参考链接

- [GitHub 仓库](https://github.com/public-clis/rdt-cli)
- [SCHEMA.md（输出契约）](https://github.com/public-clis/rdt-cli/blob/main/SCHEMA.md)
- [SKILL.md（Agent Skill）](https://github.com/public-clis/rdt-cli/blob/main/SKILL.md)
- [PyPI 包](https://pypi.org/project/rdt-cli/)
- 同系列工具：xiaohongshu-cli、bilibili-cli、twitter-cli、discord-cli、tg-cli
