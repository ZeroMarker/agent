# xiaohongshu-cli（小红书 CLI）

[`xiaohongshu-cli`](https://github.com/jackwener/xiaohongshu-cli) 是一个小红书命令行工具，基于反向工程 API 实现笔记搜索、阅读、评论、互动（点赞/收藏/评论/回复）、关注与图文发布（Apache-2.0 协议，Python 3.10+，命令名 `xhs`）。与 bilibili-cli、twitter-cli、discord-cli、tg-cli 同作者系列工具。

- 当前版本：**0.6.4**（PyPI 与仓库 main 一致）
- 代码规模：约 30 个源文件，含独立的签名、Cookie、二维码登录、格式化模块

## 适合场景

- 在终端按关键词搜索笔记（支持排序/类型过滤）、搜索用户与话题。
- 阅读笔记详情、评论（支持自动翻页拉全量）、子评论与用户主页。
- 浏览推荐 Feed 与分类热门榜单（美食、时尚、旅行等 10 类）。
- 点赞、收藏、评论、回复、关注/取关等互动操作。
- 发布图文笔记、管理自己的笔记（列表/删除）。
- 查看未读数与通知（@、赞藏、新增关注）。
- 让 Codex、Claude Code、pi 等 AI Agent 通过命令行读取或操作小红书内容。
- 用 `--yaml` / `--json` 结构化输出串联 `jq` 做脚本化分析。

## 安装

需要 Python 3.10+，推荐用 `uv tool` 或 `pipx`：

```bash
uv tool install xiaohongshu-cli
# 或：pipx install xiaohongshu-cli
```

定期升级，避免因版本过旧导致的 API 调用异常（小红书接口变动频繁，签名逻辑需跟随更新）：

```bash
uv tool upgrade xiaohongshu-cli
# 或：pipx upgrade xiaohongshu-cli
```

从源码安装：

```bash
git clone git@github.com:jackwener/xiaohongshu-cli.git
cd xiaohongshu-cli
uv sync
```

## 认证

三种认证方式（按优先级）：

1. **已保存 Cookie** — 从 `~/.xiaohongshu-cli/cookies.json` 加载
2. **浏览器 Cookie** — 自动检测已安装浏览器并提取（基于 browser_cookie3，支持 Chrome、Arc、Edge、Firefox、Safari、Brave、Chromium、Opera、Opera GX、Vivaldi、LibreWolf、Lynx、w3m 等）
3. **二维码扫码登录** — `xhs login --qrcode`：浏览器辅助登录，终端用 Unicode 半块渲染二维码，小红书 App 扫码

```bash
xhs login                          # 自动尝试所有浏览器，取第一个有有效 Cookie 的
xhs login --cookie-source arc      # 显式指定浏览器
xhs login --qrcode                 # 二维码扫码登录
xhs status                         # 检查登录状态
xhs whoami                         # 用户资料（粉丝、点赞、小红书号、IP 属地）
xhs logout                         # 清除缓存 Cookie
```

`xhs login` 会逐个验证浏览器 Cookie 并用 `get_self_info()` 确认会话有效；若返回 `guest` 或资料不完整，会等待 2.5s 重试一次，仍失败则提示改用 `--qrcode`。其他需认证命令在会话过期时会自动用浏览器新 Cookie 重试一次。

### Cookie 有效期

Cookie 默认 **7 天**有效（`COOKIE_TTL_DAYS = 7`）。超过 7 天后客户端自动尝试从浏览器刷新；刷新失败则带警告沿用旧 Cookie。

### 配置目录

| 文件 | 作用 |
| --- | --- |
| `~/.xiaohongshu-cli/cookies.json` | 保存的 Cookie（含写入时间戳，权限受限） |
| `~/.xiaohongshu-cli/token_cache.json` | `xsec_token` 缓存，**TTL 24 小时** |
| `~/.xiaohongshu-cli/index_cache.json` | 短索引导航的最近列表缓存 |

## 常用命令

### 账号

```bash
xhs login [--cookie-source BROWSER] [--qrcode]   # 登录
xhs status                                        # 登录状态
xhs whoami                                        # 详细资料
xhs logout                                        # 退出并清 Cookie
```

### 搜索与阅读

```bash
xhs search "美食"                      # 搜索笔记（--sort general|popular|latest，默认 general）
xhs search "旅行" --sort popular       # 按热度排序
xhs search "穿搭" --type video         # 类型：all（默认）/ video / image
xhs search "AI" --page 2              # 翻页（--page 默认 1）
xhs search-user "用户名"               # 搜索用户
xhs topics "美食"                      # 搜索话题/标签

xhs read <note_id>                     # 阅读笔记（仅走 API）
xhs read 1                             # 读最近一次列表的第 1 条
xhs read "https://www.xiaohongshu.com/explore/xxx?xsec_token=yyy"  # 粘贴 URL 阅读（用 URL token）
xhs read <note_id> --xsec-token T      # 显式指定 token

xhs comments 1                         # 第 1 条的评论
xhs comments "<url>"                   # 粘贴 URL 会缓存/复用 xsec_token
xhs comments "<url>" --all             # 拉取全部评论（自动翻页）
xhs comments <note_id> --xsec-token T  # note_id + 显式 token（--cursor 翻页）
xhs sub-comments <note_id> <cmt_id>    # 某评论的回复（--cursor 翻页）

xhs user <user_id>                     # 用户主页
xhs user-posts <user_id> --cursor X    # 用户发布的笔记（cursor 翻页）
```

> `xsec_token` 是小红书分享链接里的临时访问令牌。搜索/Feed/Hot 结果中每条笔记自带的 token 会被自动缓存（按来源区分 `pc_search` / `pc_feed`），24 小时内 `xhs read <note_id>` 会自动复用；无 token 时只能访问公开笔记。
>
> `comments --all` 最多自动翻 **20 页**（`max_pages=20`）后停止，返回体形如 `{comments, total_fetched, pages_fetched, has_more, cursor}`。注意 `--all` 的返回里 `has_more` 恒为 `false`，即使是因为到达 20 页上限而中断也一样——需要判断是否真的拉全时，应以 `pages_fetched` 是否达到 20 为参考。

### 发现

```bash
xhs feed                              # 推荐 Feed
xhs hot                               # 热门笔记（默认 -c food）
xhs hot -c travel                     # 按分类
```

`-c/--category` 取值：`fashion`、`food`、`cosmetics`、`movie`、`career`、`love`、`home`、`gaming`、`travel`、`fitness`。

### 互动（写操作）

```bash
xhs like <id_or_url_or_index>          # 点赞
xhs like <id_or_url_or_index> --undo   # 取消点赞
xhs favorite <id_or_url_or_index>      # 收藏
xhs unfavorite <id_or_url_or_index>    # 取消收藏
xhs comment <id_or_url_or_index> -c "好赞！"                    # 发评论
xhs reply <id_or_url_or_index> --comment-id X -c "回复"          # 回复评论
xhs delete-comment <note_id> <cmt_id> [-y]                      # 删除自己的评论
```

### 社交

```bash
xhs follow <user_id>                   # 关注
xhs unfollow <user_id>                 # 取关
xhs favorites [user_id] [--cursor C]   # 收藏夹（省略 user_id 为当前用户）
xhs likes [user_id] [--cursor C]       # 点赞列表（省略 user_id 为当前用户）
```

### 创作者

```bash
xhs my-notes [--page N]                # 我的笔记列表（v2 创作者接口，--page 从 0 开始）
xhs post --title "标题" --body "正文" --images img.jpg         # 发布图文笔记
xhs post --title T --body B --images a.jpg --images b.jpg      # 多图（--images 可重复）
xhs post --title T --body B --images a.jpg --topic 旅行 --topic 美食   # 显式指定话题（可重复）
xhs post --title T --body B --images a.jpg --private           # 发布为私密笔记
xhs delete <note_id> [-y]              # 删除笔记（-y 跳过确认）
```

小节：

- `--topic` 可重复传入，正文中的 `#话题` 也会被自动提取（不匹配 URL 片段），两者合并并按顺序去重。
- 话题数量上限 **10 个**，超出时只取前 10 个并打印提示。
- `post` 会先为每张图申请上传许可并上传，再逐话题调用话题搜索解析出真实话题 ID。

### 通知

```bash
xhs unread                                        # 未读数（评论和@、赞和收藏、新增关注）
xhs notifications                                 # 评论和 @ 通知（默认 --type mentions）
xhs notifications --type likes                    # 赞和收藏
xhs notifications --type connections               # 新增关注
xhs notifications --type mentions --num 50        # 每页条数（默认 20）
xhs notifications --cursor C                      # 翻页
```

### 短索引导航（Short-Index）

`search` / `feed` / `hot` / `user-posts` / `favorites` / `likes` / `my-notes` 等列表命令后，最新列表按序号缓存在 `~/.xiaohongshu-cli/index_cache.json`，可用数字序号直接操作：

```bash
xhs search "黑丝"
xhs read 1              # 阅读第 1 条
xhs comments 1          # 第 1 条评论
xhs like 1              # 点赞
xhs favorite 1          # 收藏
xhs comment 1 -c "收藏了"
xhs reply 1 --comment-id X -c "谢谢"
```

空列表会清空缓存，避免误用旧结果。

## 参数速查

全局参数（写在 `xhs` 之后、子命令之前）：

| 参数 | 说明 |
| --- | --- |
| `-v, --verbose` | 开启 debug 日志 |
| `--cookie-source BROWSER` | 指定读取 Cookie 的浏览器（默认 `auto`，即遍历所有已装浏览器） |
| `--version` | 显示版本 |

各命令共有的结构化输出参数：`--json`、`--yaml`。**所有子命令都支持**这两个参数（含 `login`/`status`/`logout`/`whoami` 与全部写操作）。

翻页参数因命令而异：`--page`（`search`、`my-notes`）、`--cursor`（`comments`、`sub-comments`、`user-posts`、`favorites`、`likes`、`notifications`）。`xhs` 没有通用的 `--limit`/`-o` 参数。

## 输出与脚本化

所有 `--json` / `--yaml` 输出使用统一 envelope（`ok/schema_version/data/error`，见 [SCHEMA.md](https://github.com/jackwener/xiaohongshu-cli/blob/main/SCHEMA.md)）：

```yaml
ok: true
schema_version: "1"
data: { ... }
```

出错时：

```yaml
ok: false
schema_version: "1"
error:
  code: not_authenticated
  message: need login
```

要点：

- 读取/搜索命令的 payload 在 `data` 下；`status` 返回 `data.authenticated` + `data.user`；`whoami` 返回 `data.user`；`logout` 返回 `data.logged_out`。
- **Rich 人类可读输出走 stderr**，stdout 只承载结构化数据，因此 `xhs search X --json | jq .data` 不会被表格污染。
- **Agent 优先用 `--yaml`**：通常比 JSON 更省 token。stdout 不是 TTY 时默认自动输出 YAML，可用 `OUTPUT=yaml|json|rich|auto` 覆盖（`OUTPUT=rich` 强制人类可读输出）。
- 结构化错误码（`error.code`）：

  | 错误码 | 含义 |
  | --- | --- |
  | `not_authenticated` | Cookie 缺失或会话过期 |
  | `verification_required` | 触发验证码 |
  | `ip_blocked` | IP 被风控 |
  | `signature_error` | 请求签名失败 |
  | `unsupported_operation` | 该操作不可用 |
  | `api_error` | 上游接口报错 |
  | `unknown_error` | 其他未归类错误 |

```bash
xhs status --yaml
xhs hot -c food --json | jq '.data.items[:5] | .[].note_card | {title, likes: .interact_info.liked_count}'
xhs search "美食" --json | jq -r '.data.items[0].id'
xhs comments "<url>" --all --json | jq '.data.comments | length'
```

## AI Agent 使用建议

- **执行任何 xhs 命令前先确认已认证**，不要假设 Cookie 已配置：

  ```bash
  xhs status --yaml >/dev/null && echo "AUTH_OK" || echo "AUTH_NEEDED"
  ```

  未认证时引导用户：浏览器登录 xiaohongshu.com → `xhs login`；浏览器 Cookie 不可用但能启动浏览器时用 `xhs login --qrcode`。
- **不要并行请求**。内置限速是账号保护：请求间隔默认 1.0s，再叠加高斯抖动（`gauss(0.3, 0.15)`），且约 5% 的请求额外随机等待 2–5s 模拟阅读行为。批量任务（如连续读大量笔记）请在 CLI 调用之间加 `time.sleep()`。
- **验证码恢复**：触发 `NeedVerifyError`（HTTP 461/471）时客户端自动冷却，延迟按 5s → 10s → 20s → 30s 递增，并把后续请求基础间隔**永久翻倍**。应先让用户在浏览器完成验证再重试。
- 反风控实现：所有请求携带 `x-s` / `x-s-common` / `x-t` 签名（逆向自 Web 客户端），创作者接口另用 AES-128-CBC 签名；采用固定的 macOS Chrome 145 指纹（UA / `sec-ch-ua` / GPU / 分辨率 / CPU 核数在 session 内保持一致，重启 CLI 才会重新生成）；429/5xx 与网络错误指数退避重试（最多 3 次）。
- **Cookie 是敏感信息**：优先本地浏览器提取，不要要求用户在聊天里贴原始 Cookie，也不要回显到 stdout。
- 内置 [`SKILL.md`](https://github.com/jackwener/xiaohongshu-cli/blob/main/SKILL.md)，可通过 [Skills CLI](https://github.com/vercel-labs/skills) 安装：

  ```bash
  npx skills add jackwener/xiaohongshu-cli -g
  ```

  或手动安装：

  ```bash
  mkdir -p .agents/skills
  git clone git@github.com:jackwener/xiaohongshu-cli.git .agents/skills/xiaohongshu-cli
  ```

  > ClawHub 安装方式已弃用，不再支持。

## 常见问题

| 报错 / 现象 | 原因 | 解决 |
| --- | --- | --- |
| `NoCookieError: No 'a1' cookie found` | 没有可用的浏览器登录态 | 先在浏览器打开 xiaohongshu.com 并登录，再 `xhs login`（或 `--cookie-source <browser>`） |
| `登录成功但 profile 是 guest` | 浏览器 Cookie 未完全生效 | 用 `xhs login --qrcode` 扫码登录 |
| `NeedVerifyError: Captcha required` | 触发验证码 | 浏览器完成验证后重试；客户端会自动冷却 5→30s |
| `IpBlockedError: IP blocked` | IP 被风控限制 | 切换网络（手机热点或 VPN） |
| `SessionExpiredError` | Cookie 过期 | `xhs login` 刷新 |
| `SignatureError` | 签名生成失败（多为版本过旧） | `uv tool upgrade xiaohongshu-cli` |
| 请求较慢 | 内置限速（1s + 高斯抖动，偶发 +2–5s） | 正常现象；激进请求会触发验证码或 IP 封锁，勿绕过 |

## 限制

- **无视频/图片下载**能力。
- **无私信**、**无直播**功能。
- **无关注/粉丝列表**（小红书 Web API 不暴露该端点）。
- **单账号**：同一时间只有一套 Cookie。
- `xhs delete`（删除笔记）走的是公开 Web 端点，官方文档标注为 experimental，可能不稳定。
- 限速：内置抖动延迟保护账号，勿绕过。

## 参考链接

- [GitHub 仓库](https://github.com/jackwener/xiaohongshu-cli)
- [SCHEMA.md（输出契约）](https://github.com/jackwener/xiaohongshu-cli/blob/main/SCHEMA.md)
- [SKILL.md（Agent Skill）](https://github.com/jackwener/xiaohongshu-cli/blob/main/SKILL.md)
- [PyPI 包](https://pypi.org/project/xiaohongshu-cli/)
- 同系列工具：bilibili-cli、twitter-cli、discord-cli、tg-cli
