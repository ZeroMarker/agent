# xiaohongshu-cli（小红书 CLI）

[`xiaohongshu-cli`](https://github.com/jackwener/xiaohongshu-cli) 是一个小红书命令行工具，基于反向工程 API 实现笔记搜索、阅读、评论、互动（点赞/收藏/评论/回复）、关注与图文发布（Apache-2.0 协议，Python 3.10+）。与 bilibili-cli、twitter-cli 同作者系列工具。

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

定期升级，避免因版本过旧导致的 API 调用异常：

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
2. **浏览器 Cookie** — 自动检测已安装浏览器并提取（基于 browser_cookie3，支持 Chrome、Arc、Edge、Firefox、Safari、Brave、Chromium、Opera、Vivaldi、LibreWolf 等）
3. **二维码扫码登录** — `xhs login --qrcode`：浏览器辅助登录，终端用 Unicode 半块渲染二维码，小红书 App 扫码

```bash
xhs login                          # 自动尝试所有浏览器，取第一个有有效 Cookie 的
xhs login --cookie-source arc      # 显式指定浏览器
xhs login --qrcode                 # 二维码扫码登录
xhs status                         # 检查登录状态
xhs whoami                         # 用户资料（粉丝、点赞等）
xhs logout                         # 清除缓存 Cookie
```

Cookie 有效期默认 **7 天**，过期后需认证命令自动尝试从浏览器刷新一次；浏览器提取失败则带警告沿用旧 Cookie。

## 常用命令

### 搜索与阅读

```bash
xhs search "美食"                      # 搜索笔记
xhs search "旅行" --sort popular       # 排序：general / popular / latest
xhs search "穿搭" --type video         # 类型：all / video / image
xhs search "AI" --page 2              # 翻页
xhs search-user "用户名"               # 搜索用户
xhs topics "美食"                      # 搜索话题/标签
xhs read <note_id>                     # 阅读笔记（仅走 API）
xhs read "https://www.xiaohongshu.com/explore/xxx?xsec_token=yyy"  # 粘贴 URL 阅读（用 URL token）
xhs comments "<url>"                   # 查看评论——粘贴 URL 会缓存/复用 xsec_token
xhs comments "<url>" --all             # 拉取全部评论（自动翻页）
xhs comments <note_id> --xsec-token T  # note_id + 显式 xsec_token
xhs sub-comments <note_id> <cmt_id>    # 查看某评论的回复
xhs user <user_id>                     # 用户主页
xhs user-posts <user_id> --cursor X    # 用户发布的笔记（cursor 翻页）
```

> `xsec_token` 是小红书分享链接里的临时访问令牌，粘贴 URL 后会自动缓存复用；无 token 的 `note_id` 只能访问公开笔记。

### 发现

```bash
xhs feed                              # 推荐 Feed
xhs hot                               # 热门笔记（默认 food）
xhs hot -c travel                     # 分类：fashion, food, cosmetics, movie,
                                      #   career, love, home, gaming, travel, fitness
```

### 互动（写操作）

```bash
xhs like <note_id> --undo             # 点赞 / 取消点赞
xhs favorite <note_id>                # 收藏
xhs unfavorite <note_id>              # 取消收藏
xhs comment <note_id> -c "好赞！"      # 发评论
xhs reply <note_id> --comment-id X -c "回复"   # 回复评论
xhs delete-comment <note_id> <cmt_id> # 删除自己的评论
xhs follow <user_id> / xhs unfollow <user_id>  # 关注 / 取关
xhs favorites [user_id]               # 收藏夹（省略为当前用户）
xhs likes [user_id]                   # 点赞列表（省略为当前用户）
```

### 创作者

```bash
xhs my-notes --page 1                 # 我的笔记列表（v2 创作者接口）
xhs post --title "标题" --body "正文" --images img.jpg  # 发布图文笔记
xhs delete <note_id> -y               # 删除笔记（-y 跳过确认）
```

### 通知

```bash
xhs unread                            # 未读数（赞藏、@、关注）
xhs notifications                     # 评论和 @ 通知
xhs notifications --type likes        # 赞和收藏通知
xhs notifications --type connections  # 新增关注通知
```

### 短索引导航（Short-Index）

`search` / `feed` / `hot` / `user-posts` / `favorites` / `my-notes` 等列表命令后，最新列表缓存在 `~/.xiaohongshu-cli/index_cache.json`，可用序号直接操作：

```bash
xhs search "黑丝"
xhs read 1          # 打开第 1 条
xhs comments 1      # 第 1 条评论
xhs like 1          # 点赞
xhs favorite 1      # 收藏
xhs comment 1 -c "收藏了"
```

空列表会清空缓存，避免误用旧结果。

## 输出与脚本化

所有 `--json` / `--yaml` 输出使用统一 envelope（`ok/schema_version/data/error`，见 [SCHEMA.md](https://github.com/jackwener/xiaohongshu-cli/blob/main/SCHEMA.md)）：

```yaml
ok: true
schema_version: "1"
data: { ... }
```

- 读取/搜索命令的 payload 在 `data` 下；`status` 返回 `data.authenticated` + `data.user`；`whoami` 返回 `data.user`。
- **Agent 优先用 `--yaml`**：通常比 JSON 更省 token。stdout 不是 TTY 时默认自动输出 YAML，可用 `OUTPUT=yaml|json|rich|auto` 覆盖。
- 结构化错误码：`not_authenticated`、`verification_required`、`ip_blocked`、`signature_error`、`api_error`、`unsupported_operation`。

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

  未认证时引导用户：浏览器登录 xiaohongshu.com → `xhs login`；浏览器不可用且可启动浏览器时用 `xhs login --qrcode`。
- **不要并行请求**。内置高斯抖动延迟（约 1–1.5s/请求）是有意的账号保护；批量任务（如读大量笔记）在 CLI 调用间加 `time.sleep()`。
- 触发验证码后客户端自动冷却（5s→10s→20s→30s 递增），先让用户在浏览器完成验证再重试。
- 反风控实现：所有请求带 `x-s` / `x-s-common` / `x-t` 签名（逆向自 Web 客户端）；session 级一致的 macOS Chrome 指纹（UA/sec-ch-ua/GPU/分辨率/CPU 核数，session 内不复用新值）；429/5xx 指数退避重试（最多 3 次）。
- Cookie 是敏感信息：优先本地浏览器提取，不要要求用户在聊天里贴原始 Cookie，也不要回显到 stdout。
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

| 报错 | 原因 | 解决 |
| --- | --- | --- |
| `NoCookieError: No 'a1' cookie found` | 没有可用的浏览器登录态 | 先在浏览器打开 xiaohongshu.com 并登录，再 `xhs login`（或 `--cookie-source <browser>`） |
| `NeedVerifyError: Captcha required` | 触发验证码 | 浏览器完成验证后重试 |
| `IpBlockedError: IP blocked` | IP 被风控限制 | 切换网络（手机热点或 VPN） |
| `SessionExpiredError` | Cookie 过期 | `xhs login` 刷新 |
| 请求较慢 | 内置高斯抖动延迟（约 1–1.5s） | 正常现象；激进请求模式会触发验证码或 IP 封锁，勿绕过 |

## 限制

- **无视频/图片下载**能力。
- **无私信**、**无直播**功能。
- **无关注/粉丝列表**（小红书 Web API 不暴露该端点）。
- **单账号**：同一时间只有一套 Cookie。
- 限速：内置抖动延迟保护账号，勿绕过。

## 参考链接

- [GitHub 仓库](https://github.com/jackwener/xiaohongshu-cli)
- [SCHEMA.md（输出契约）](https://github.com/jackwener/xiaohongshu-cli/blob/main/SCHEMA.md)
- [SKILL.md（Agent Skill）](https://github.com/jackwener/xiaohongshu-cli/blob/main/SKILL.md)
- [PyPI 包](https://pypi.org/project/xiaohongshu-cli/)
- 同系列工具：bilibili-cli、twitter-cli、discord-cli、tg-cli
