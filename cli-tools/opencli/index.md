# OpenCLI

[`OpenCLI`](https://github.com/jackwener/opencli) 是一个把「任意网站变成 CLI」并让 AI Agent 通过你**已登录的 Chrome** 操作网页的统一工具（JavaScript，Apache-2.0，Node.js >= 20，npm 包 `@jackwener/opencli`，28k+ stars）。三种用法一张皮：内置 100+ 站点 adapter、`opencli browser` 浏览器原语供 Agent 驱动作业、adapter 编写/修复流程。

> 与系列单站 CLI 的关系：OpenCLI 是上层中枢，内置 bilibili / xiaohongshu / zhihu / twitter 等站点 adapter；本仓库 `cli-tools/` 下的 bilibili-cli、xiaohongshu-cli 等是同一作者的独立单站 CLI，二者不冲突。

## 适合场景

- 用已登录的浏览器态跑单站命令：`opencli bilibili hot`、`opencli twitter trending` 等（复用登录态，不重复登录）。
- 让 AI Agent 操作任意网页：导航、点击、填表、提取、拦截网络响应——装 `opencli-browser` skill 后全由 Agent 内部完成。
- 给未覆盖的站点编写可复用 adapter，或修复失效的内置命令（`opencli-autofix`）。
- 作为 CLI Hub 统一入口：`opencli gh ...`、`opencli docker ...`、`opencli lark-cli ...` 等，可注册自己的本地工具。
- 自动化桌面 Electron 应用（Cursor、Codex、ChatGPT、Doubao 等，经 CDP 连接）。
- 跨平台下载：小红书/B 站/推特图片视频、知乎/微信文章等。

## 安装

需要 Node.js >= 20（npm 方式）。

```bash
node --version
npm install -g @jackwener/opencli
```

macOS / Windows 桌面用户推荐 **OpenCLIApp**（<https://opencli.info/download>）：内置运行时、管理 `opencli` 命令安装、托盘 UI 做诊断/更新/浏览器登录保活/Web→Markdown。

### Browser Bridge 扩展（必需）

OpenCLI 通过 Chrome 扩展 + 本地 daemon（自动启动，端口 19825）连接浏览器：

- 推荐：Chrome Web Store 安装 [OpenCLI](https://chromewebstore.google.com/detail/opencli/ildkmabpimmkaediidaifkhjpohdnifk)。
- 手动：GitHub Releases 下载 `opencli-extension-v{version}.zip` → `chrome://extensions` 开开发者模式 → Load unpacked。

### 验证与多 Profile

```bash
opencli doctor                # 诊断浏览器连通性
opencli profile list          # 列出已连接 Chrome profile
opencli profile rename <contextId> work
opencli profile use work      # 多 profile 时指定默认
opencli --profile work browser main state
```

单 profile 自动使用；多 profile 无默认时会询问选择。

## 快速开始

```bash
opencli list                          # 全部已注册命令
opencli hackernews top --limit 5
opencli bilibili hot --limit 5
```

## 常用命令

### 内置站点 adapter（节选，共 100+）

| 站点 | 代表命令 |
| --- | --- |
| xiaohongshu | `search` `note` `comments` `feed` `user` `download` `publish` `follow` `notifications` `creator-stats` |
| bilibili | `hot` `search` `ranking` `feed` `download` `comments` `dynamic` `favorite` `following` `subtitle` `summary` `video` |
| zhihu | `hot` `search` `question` `download` `follow` `like` `comment` `answer` |
| twitter | `trending` `search` `timeline` `bookmarks` `post` `download` `like` `reply` `thread` `follow` `block` |
| reddit | `hot` `frontpage` `search` `subreddit` `read` `upvote` `save` `comment` `subscribe` |
| hackernews | `top` `new` `best` `ask` `show` `jobs` `search` `user` |
| linkedin | `connect` `inbox` `jobs-preferences` `posts` `profile-read` `search` `timeline` `salesnav-*` |
| amazon | `bestsellers` `search` `product` `offer` `new-releases` `rankings` |
| claude / gemini / notebooklm | 与 AI 产品交互：`ask` `send` `new` `deep-research` `source-list` 等 |
| midjourney | `login` `whoami` `quota` `generate` `describe` `download` |
| hltv / geogebra / upwork / slock / huodongxing / 1688 | 垂直站点命令 |

完整清单见官方 [`docs/adapters/index.md`](https://github.com/jackwener/opencli/blob/main/docs/adapters/index.md)（douyin / weibo / spotify / quark / google-scholar / hupu / xianyu / weread / xiaoyuzhou / Chess.com 等）。

### 输出格式

所有内置命令支持 `--format` / `-f`：`table`（默认）、`json`、`yaml`、`md`、`csv`。

```bash
opencli bilibili hot -f json     # 管道给 jq 或 LLM
opencli bilibili hot -f csv
opencli bilibili hot -v          # verbose：展示 pipeline 调试步骤
```

### 下载

| 平台 | 内容 | 备注 |
| --- | --- | --- |
| xiaohongshu / rednote | 图片、视频 | 整条笔记全部媒体；支持 xhslink 短链 |
| bilibili | 视频 | 需先装 `yt-dlp`（`brew install yt-dlp`） |
| twitter | 图片、视频 | 用户媒体页或单条 tweet |
| pixiv / douban / 1688 | 图片（/视频） | 原图多页 / 海报剧照 / 页面可见媒体 |
| xiaoyuzhou | 音频、文稿 | 需 `~/.opencli/xiaoyuzhou.json` 本地凭证 |
| zhihu / weixin | 文章（Markdown） | 可选带图导出 |

```bash
opencli xiaohongshu download "https://www.xiaohongshu.com/search_result/<id>?xsec_token=..." --output ./xhs
opencli bilibili download BV1xxx --output ./bilibili
opencli twitter download elonmusk --limit 20 --output ./twitter
```

### CLI Hub（统一入口）

`opencli <tool> ...` 直通现有 CLI：`gh` `docker` `vercel` `wrangler` `obsidian` `longbridge` `lark-cli` `ntn(Notion)` `dws(钉钉工作台)` `wecom-cli(企业微信)` `tg(tg-cli)` `discord(discord-cli)` `wx(wx-cli)`。

```bash
opencli external register mycli    # 注册自己的本地工具
opencli external list
```

**桌面应用 adapter**（Electron，经 CDP）：Cursor / Trae CN / Codex / Antigravity / ChatGPT App / ChatWise / Qoder / Discord / Doubao / Trae SOLO。

### 插件

```bash
opencli plugin install github:user/opencli-plugin-my-tool
opencli plugin list
opencli plugin update --all
opencli plugin uninstall my-tool
```

示例：`opencli-plugin-github-trending`（GitHub Trending）、`opencli-plugin-hot-digest`（多平台热榜聚合）、`opencli-plugin-juejin`（掘金热文）等。

## AI Agent 使用

安装 skills（会刷新已装版本）：

```bash
npx skills add jackwener/opencli
# 或按需安装
npx skills add jackwener/opencli --skill opencli-browser
npx skills add jackwener/opencli --skill opencli-adapter-author
npx skills add jackwener/opencli --skill opencli-autofix
```

| Skill | 何时用 | 示例指令 |
| --- | --- | --- |
| `opencli-browser` | 临时驱动真实 Chrome：导航/填表/点击/提取 | "帮我查小红书通知" |
| `opencli-adapter-author` | 为新站点写可复用 adapter | "给抖音热榜写个 adapter" |
| `opencli-autofix` | 内置命令失效时修复 | "`opencli zhihu hot` 返回空，修一下" |
| `opencli-browser-sitemap` | 带站点 sitemap 上下文驱动作业 | "用 sitemap 导航，别盲点" |
| `opencli-sitemap-author` | 沉淀站点稳定工作流知识 | "把刚发现的流程记下来" |
| `opencli-usage` | 命令与站点速查 | "OpenCLI 对 twitter 有哪些命令？" |

**browser 原语**：`open` `state` `click` `type` `fill` `select` `keys` `wait` `get` `find` `extract` `frames` `screenshot` `scroll` `back` `eval` `network` `tab list|new|select|close` `init` `verify` `close`。

- `opencli browser` 后必须跟 `<session>` 位置参数：`opencli browser work open <url>`。
- `tab new` 创建新 tab 但不改默认目标；`tab select <targetId>` 才把该 tab 提升为后续无定向命令的默认目标；定向命令用 `--tab <targetId>`。
- 会话 tab 租约持续到 `opencli browser <session> close` 或空闲清理；adapter 默认用后台窗口一次性 tab。

## 编写新 adapter

1. **Recon**：分析站点并选模式（SPA / SSR / JSONP / Token / Streaming）。
2. **找端点**：网络检查、初始状态、bundle 搜索、token 追踪、拦截器兜底。
3. **选认证**：`PUBLIC` / `COOKIE` / `INTERCEPT` / `UI` / `LOCAL`。
4. **解码字段**并设计输出列。
5. 写代码并验证：

```bash
opencli browser recon analyze <url>
opencli browser recon init <site>/<name>
opencli browser recon verify <site>/<name>
```

站点知识沉淀在 `~/.opencli/sites/<site>/`，同站下一个 adapter 直接复用上下文。

扩展方式速查：个人命令放自己的 Git 仓库 → `opencli plugin create` + `opencli plugin install file://...`；快速草稿私有 adapter → `opencli browser init <site>/<command>`（在 `~/.opencli/clis/`）；改官方 adapter → `opencli adapter eject <site>` / `opencli adapter reset <site>`。

## 配置环境变量

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `OPENCLI_PROFILE` | — | 多 Chrome profile 时指定使用的 profile 别名/contextId |
| `OPENCLI_WINDOW` | 命令默认 | `foreground` / `background` 覆盖浏览器窗口放置 |
| `OPENCLI_BROWSER_CONNECT_TIMEOUT` | `45` | 等待浏览器连接秒数 |
| `OPENCLI_BROWSER_COMMAND_TIMEOUT` | `60` | 单条 browser 命令超时秒数 |
| `OPENCLI_CDP_ENDPOINT` | — | 远程浏览器/Electron 应用的 CDP 端点 |
| `OPENCLI_CDP_TARGET` | — | 按 URL 子串过滤 CDP target（如 `detail.1688.com`） |
| `OPENCLI_VERBOSE` | `false` | 详细日志（`-v` 同样生效） |

## 退出码（sysexits.h）

`0` 成功 · `66` 空结果 · `69` Browser Bridge 未连接 · `75` 超时 · `77` 需要认证 · `78` 配置错误 · `130` Ctrl-C。CI/脚本可按退出码分支处理。

## 常见问题

| 报错/现象 | 原因 | 解决 |
| --- | --- | --- |
| `Extension not connected` | Browser Bridge 扩展未装或未启用 | Chrome Web Store 安装并在 `chrome://extensions` 启用 |
| `attach failed: Cannot access a chrome-extension:// URL` | 其他扩展干扰 | 临时禁用其他扩展重试 |
| 空数据 / `Unauthorized` | Chrome 登录态过期 | 到目标站点重新登录 |
| 启动崩溃 / 缺 `fetch` / Node API 报错 | Node < 20 | 升级 Node 后重试 |
| daemon 异常 | 本地 daemon 故障 | `curl localhost:19825/status` 查状态、`curl localhost:19825/logs` 查日志 |

## 参考链接

- [GitHub 仓库](https://github.com/jackwener/opencli)
- [中文 README](https://github.com/jackwener/opencli/blob/main/README.zh-CN.md)
- [npm 包 `@jackwener/opencli`](https://www.npmjs.com/package/@jackwener/opencli)
- [适配器全清单 docs/adapters/index.md](https://github.com/jackwener/opencli/blob/main/docs/adapters/index.md)
- [Chrome Web Store 扩展](https://chromewebstore.google.com/detail/opencli/ildkmabpimmkaediidaifkhjpohdnifk)
- 相关：本仓库 `cli-tools/bilibili-cli`、`cli-tools/xiaohongshu-cli`（同作者单站 CLI）
