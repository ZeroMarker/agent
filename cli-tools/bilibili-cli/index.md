# bilibili-cli

[`bilibili-cli`](https://github.com/public-clis/bilibili-cli) 是一个 B 站（Bilibili）命令行工具，可在终端浏览视频、UP 主、搜索、热门/排行榜、关注动态，并支持点赞、投币、一键三连等互动操作（Apache-2.0 协议，Python 实现）。与 twitter-cli 同属 public-clis 系列工具。

## 适合场景

- 在终端刷热门视频、全站排行榜、关注动态时间线。
- 查看视频详情、字幕（可导出 SRT）、AI 总结、评论、相关推荐。
- 按关键词搜索用户或视频，查 UP 主资料与视频列表。
- 浏览收藏夹、稍后再看、观看历史。
- 提取视频音频并切分为 ASR 可用的 WAV 片段。
- 点赞 / 投币 / 一键三连 / 发布动态等互动操作。
- 让 Codex、Claude Code、pi 等 AI Agent 通过命令行读取或操作 B 站内容。
- 用 `--yaml` / `--json` 结构化输出串联 `jq` 等工具做脚本化分析。

## 安装

需要 Python 3.8+，推荐用 `uv tool` 或 `pipx` 安装：

```bash
uv tool install bilibili-cli
# 或：pipx install bilibili-cli

# 如果需要音频提取功能
uv tool install "bilibili-cli[audio]"
```

定期升级，避免因版本过旧导致的 API 调用异常：

```bash
uv tool upgrade bilibili-cli
# 或：pipx upgrade bilibili-cli
```

从源码安装：

```bash
git clone git@github.com:public-clis/bilibili-cli.git
cd bilibili-cli
uv sync
```

## 认证

三级认证策略（按优先级）：

1. **已保存凭证** — 从 `~/.bilibili-cli/credential.json` 加载
2. **浏览器 Cookie** — 自动从 Chrome、Firefox、Edge、Brave 提取
3. **扫码登录** — `bili login` 在终端显示二维码

```bash
bili status          # 检查登录状态（认证成功退出码 0，否则 1）
bili status --yaml   # 结构化认证状态
bili login           # 扫码登录（可写凭证需含 bili_jct）
bili whoami          # 个人信息（等级、硬币、粉丝数）
```

> 大部分命令无需登录。字幕、收藏夹/关注/稍后再看/历史/动态/互动需要登录。写操作（like/coin/triple/unfollow/dynamic-post/dynamic-delete）需要可写凭证（`bili_jct`）。过期 Cookie 自动清除，临时网络异常不会误清本地凭证。

## 常用命令

### 视频

```bash
bili video BV1ABcsztEcY                                # 视频详情
bili video BV1ABcsztEcY --subtitle                     # 字幕（纯文本）
bili video BV1ABcsztEcY --subtitle-timeline            # 带时间线字幕
bili video BV1ABcsztEcY -st --subtitle-format srt      # 导出 SRT
bili video BV1ABcsztEcY --ai                           # AI 总结
bili video BV1ABcsztEcY --comments                     # 热门评论
bili video BV1ABcsztEcY --related                      # 相关推荐
bili video BV1ABcsztEcY --json                         # 规范化 JSON envelope
```

### 用户

```bash
bili user 946974              # UP 主资料（按 UID）
bili user "影视飓风"           # 按用户名搜索
bili user-videos 946974 --max 20   # 视频列表
```

### 发现

```bash
bili hot                                # 热门视频（第1页）
bili hot --page 2 --max 10              # 第2页，前10条
bili rank                               # 全站排行榜（3日）
bili rank --day 7 --max 30              # 7日榜，前30条
bili search "关键词"                     # 搜索用户
bili search "关键词" --type video --max 5 # 搜索视频（前5条）
bili search "关键词" --page 2            # 第2页结果
```

### 动态

```bash
bili feed                               # 关注动态时间线
bili feed --offset 1234567890           # 使用上一页游标翻页
bili my-dynamics                        # 我发布的动态
bili dynamic-post "抽个奖，明天开奖"      # 发布文字动态
bili dynamic-delete 123456789012345678  # 删除单条动态
```

### 收藏

```bash
bili favorites           # 收藏夹列表
bili favorites <ID> --page 2   # 收藏夹内视频
bili following           # 关注列表
bili watch-later         # 稍后再看
bili history             # 观看历史
```

### 音频提取（需安装 `[audio]` 附加组）

```bash
bili audio BV1ABcsztEcY               # 下载并切分为 25 秒 WAV 片段
bili audio BV1ABcsztEcY --segment 60  # 每段 60 秒
bili audio BV1ABcsztEcY --no-split    # 完整 m4a，不切分
bili audio BV1ABcsztEcY -o ~/data/    # 自定义输出目录
```

### 互动（写操作）

```bash
bili like BV1ABcsztEcY       # 点赞
bili coin BV1ABcsztEcY       # 投币
bili triple BV1ABcsztEcY     # 一键三连 🎉
bili unfollow 946974         # 取消关注（按 UID）
bili like BV1ABcsztEcY --json   # 结构化写操作结果
```

## 输出与脚本化

所有 `--json` / `--yaml` 输出使用统一 envelope（`ok/schema_version/data/error`，见 [SCHEMA.md](https://github.com/public-clis/bilibili-cli/blob/main/SCHEMA.md)），且是命令层规范化后的 payload，不泄漏原始上游 SDK 响应：

- `bili video` → `data.video` / `data.subtitle` / `data.ai_summary` / `data.comments` / `data.related` / `data.warnings`
- `bili hot` / `bili rank` → `data.items`
- `bili search` → 规范化的用户/视频列表
- 写操作 → 标准化的写操作结果

**Agent 优先用 `--yaml`**：通常比 JSON 更省 token，且易于解析；配合 `jq` 或下游需要严格 JSON 时再用 `--json`。stdout 不是 TTY 时默认自动输出 YAML，可用 `OUTPUT=yaml|json|rich|auto` 覆盖。

```bash
bili status --yaml
bili hot --max 5 --yaml | jq '.data.items[].title'
bili video BV1ABcsztEcY --json | jq '.data.video.stat'
```

结构化错误码：`not_authenticated`、`permission_denied`、`invalid_input`、`network_error`、`upstream_error`、`not_found`、`rate_limited`、`internal_error`。

## AI Agent 使用建议

- 需要总结视频时，**先取字幕**（`--subtitle`）——字幕通常包含视频核心内容，是总结的最佳主来源；字幕不可用或不足时才退而求其次用 AI 总结、评论或音频提取。
- 用较窄的查询（`--max`、`--page`、`--offset`）避免在超大 payload 上浪费上下文。
- 内置 [`SKILL.md`](https://github.com/public-clis/bilibili-cli/blob/main/SKILL.md)，可通过 [Skills CLI](https://github.com/vercel-labs/skills) 安装：

```bash
npx skills add jackwener/bilibili-cli -g
```

或手动安装：

```bash
mkdir -p .agents/skills
git clone git@github.com:public-clis/bilibili-cli.git .agents/skills/bilibili-cli
```

## 常见问题

| 报错 | 原因 | 解决 |
| --- | --- | --- |
| `需要登录` / `not_authenticated` | 未认证 | 执行 `bili login` 扫码，或确保浏览器已登录 bilibili.com |
| `HTTP 412` / `RateLimitError` | 触发 B 站反爬 | 稍等重试，或减小 `--max` |
| `无法提取 BV 号` / `InvalidBvidError` | BV 号格式错误 | 必须是 `BV` + 10 位字母数字 |
| `NetworkError` | 网络问题 | 检查网络；使用代理时确保支持目标域名 |
| `当前登录凭证不支持写操作` | Cookie 缺少 `bili_jct` | 重新 `bili login` 获取完整写权限 |

## 参考链接

- [GitHub 仓库](https://github.com/public-clis/bilibili-cli)
- [SCHEMA.md（输出契约）](https://github.com/public-clis/bilibili-cli/blob/main/SCHEMA.md)
- [SKILL.md（Agent Skill）](https://github.com/public-clis/bilibili-cli/blob/main/SKILL.md)
- [PyPI 包](https://pypi.org/project/bilibili-cli/)
- 同系列工具：xiaohongshu-cli（小红书）、twitter-cli、discord-cli、tg-cli
