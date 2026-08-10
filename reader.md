# Jina Reader 笔记

> 仓库：https://github.com/jina-ai/reader
> Jina AI 出品，Apache-2.0。本仓库是 `https://r.jina.ai` 与 `https://s.jina.ai` 背后的开源分支（OSS）：无状态 / 桶缓存模式，SaaS 的 MongoDB 存储层不在其中。
> 一句话：**"给你的 LLM 更好的输入"** —— 把任意 URL 转成 LLM 友好的 Markdown，或把搜索词变成带正文的检索结果。

## 1. 核心能力

- **Read（URL → Markdown）**：`https://r.jina.ai/https://你的.url`
- **Search（搜索 → Markdown）**：`https://s.jina.ai/你的+查询词`（需 URL 编码）

能读的内容：

| 类型 | 处理方式 |
| --- | --- |
| 网页 | headless Chrome 渲染，或 `curl-impersonate` 轻量抓取；`auto` 智能二选一 |
| PDF | 任意 `.pdf` URL，PDF.js 解析（如 NASA 长文 PDF） |
| MS Office（Word / Excel / PPT） | LibreOffice 转 PDF/HTML 后走对应管线 |
| 图片 | VLM 生成描述（caption），让纯文本 LLM 获得"刚好够用"的提示 |

在线试用：`r.jina.ai` 示例 `https://r.jina.ai/https://github.com/jina-ai/reader`；`s.jina.ai` 示例 `https://s.jina.ai/Who%20will%20win%202024%20US%20presidential%20election%3F`。免费、稳定、可生产使用（有速率限制，见 [jina.ai/reader#pricing](https://jina.ai/reader#pricing)）。

## 2. 基本用法

### Read：单 URL

```bash
curl 'https://r.jina.ai/https://en.wikipedia.org/wiki/Artificial_intelligence'
```

### Search：联网搜索

```bash
# 查询词要做 URL 编码（空格 %20、问号 %3F）
curl 'https://s.jina.ai/When%20was%20Jina%20AI%20founded%3F'

# 站内搜索：site 参数可多次
curl 'https://s.jina.ai/When%20was%20Jina%20AI%20founded%3F?site=jina.ai&site=github.com'
```

Search 与常见"web search function-calling"的区别：它不只是返回标题/URL/描述，而是**自动抓取搜索结果前 5 条的正文**（复用 r.jina.ai 的技术栈），不需要你处理浏览器渲染、反爬、JS/CSS 问题。

### SPA（单页应用）

- hash 路由：`#` 后的内容不会发给服务器，改用 POST：

```bash
curl -X POST 'https://r.jina.ai/' -d 'url=https://example.com/#/route'
```

- 预加载内容页：用 `x-timeout` 等网络空闲，或 `x-wait-for-selector` 等特定元素：

```bash
curl 'https://r.jina.ai/https://example.com/' -H 'x-timeout: 10'
curl 'https://r.jina.ai/https://example.com/' -H 'x-wait-for-selector: #content'
# 两者结合 = 等到超时为止（元素不存在时）
```

### JSON 模式

```bash
curl -H "Accept: application/json" https://r.jina.ai/https://en.m.wikipedia.org/wiki/Main_Page
```

## 3. 请求头速查（x-* 全表）

完整默认值与校验规则见线上 [r.jina.ai/docs](https://r.jina.ai/docs) 或源码 `src/dto/crawler-options.ts`。

### 输出格式

| 头 | 取值 | 说明 |
| --- | --- | --- |
| `x-respond-with` | `markdown` / `html` / `text` / `screenshot` / `pageshot` / `frontmatter` / `markdown+frontmatter` | `markdown` 不走 readability；`html` 返回 outerHTML；`text` 返回 innerText；`screenshot`/`pageshot` 返回截图 URL（后者整页）；`frontmatter` 用 YAML front matter 替代默认 `Title:`/`URL Source:` 头 |
| `x-engine` | `browser` / `curl` / `auto` | 强制抓取引擎；默认 auto = curl + browser 智能组合 |
| `x-proxy-url` | URL | 走你的指定代理（http/https/socks4/socks5，带认证 `https://user:pass@host:port`） |
| `x-cache-tolerance` | 秒（整数） | 缓存页面多旧可接受 |
| `x-no-cache: true` | — | 绕过缓存（缓存寿命 3600s），等价 `x-cache-tolerance: 0` |
| `x-target-selector` | CSS 选择器 | 只返回匹配元素内容；同时充当 wait-for-selector（元素出现才返回） |
| `x-wait-for-selector` | CSS 选择器 | 等到元素渲染完再返回；设了 target-selector 可省略 |
| `x-timeout` | 秒（最大 180） | 不提前返回，等网络空闲或到超时 |
| `x-max-tokens` | 整数 ≥500 | 截断响应到指定 token 数（护栏式，截断而非拒绝） |
| `x-token-budget` | 整数 | 超预算直接拒绝请求（成本控制；search 端点忽略） |
| `x-respond-timing` | `html` / `visible-content` / `mutation-idle` / `resource-idle` / `media-idle` / `network-idle` | 控制何时返回（延迟 vs 完整度的权衡）；省略时按 respond-with/timeout/iframe 推断 |

### 内容保留策略

| 头 | 取值 | 说明 |
| --- | --- | --- |
| `x-with-generated-alt: true` | — | 用 VLM 给缺 alt 的图片生成描述 |
| `x-retain-images` | `all`（默认）/ `none` / `alt` | 图片：保留 `![alt](url)` / 全丢 / 只留 alt 文本（省 token） |
| `x-retain-links` | `all` / `none` / `text` / `gpt-oss` | 链接：全保留 / 全丢 / 只留锚文本 / gpt-oss 引用格式 `【{id}†...】` + 编号 URL 页脚（自动开 links-summary） |
| `x-retain-media` | `link`（默认）/ `none` / `text` / `image` / `html` | 视频/音频/嵌入 iframe：链接 / 丢弃 / 纯标签 / 图片语法 / 原 HTML（去装饰属性） |
| `x-with-links-summary` / `x-with-images-summary` | `true` / `all` | 末尾追加去重后的链接/图片清单（`all` 不去重）；配合 `text`/`alt` 可"行内无 URL、文末一份清单" |
| `x-markdown-chunking` | `true` / `h1`–`h5` / `structured` / `s1`–`s5` | 语义分块返回 JSON 数组（或 `\x1d` 分隔文本）：按标题层级切，或按块级结构化切（s1 最粗，s5 最细） |
| `x-preset` | `reader` / `index` / `research` / `agent` / `spider` | 一键方案包，只对未显式设置的选项生效（可单字段覆盖） |
| `x-detach-invisibles` | — | 快照前分离最终 `display:none` 元素（隐含 browser 引擎、禁用缓存） |
| `x-set-cookie` | cookie 串 | 转发 Cookie（带 cookie 的请求不缓存） |
| `x-md-*` | — | Markdown 输出微调（标题样式、列表符号、链接样式等），见 `src/dto/turndown-tweakable-options.ts` |

### Presets 一览

| Preset | 适用 | 关键配置 |
| --- | --- | --- |
| `reader` | 给人看 | frontmatter + retainMedia:html + detachInvisibles + removeOverlay |
| `index` | 向量化/嵌入 | retainLinks:text + retainImages:alt + retainMedia:none + chunking:s3 |
| `research` | 研究 agent | markdown+frontmatter + chunking:h3 + 全量链接/图片/媒体 |
| `agent` | 日常浏览 agent | frontmatter + chunking:h3 + retainImages:alt |
| `spider` | 递归站点爬取 | markdown+frontmatter + chunking:h3 + linksSummary:all |

## 4. Cookbook 精选配方

### 语义索引（URL 是噪音，丢掉）

```bash
curl https://r.jina.ai/https://example.com/article \
  -H 'Accept: application/json' \
  -H 'x-retain-links: text' \
  -H 'x-retain-images: alt' \
  -H 'x-markdown-chunking: h3'     # 或 x-preset: index
```

保留有语义的锚文本/alt 文本，丢 URL；h3 分块≈每个小节一块，契合 embedding 窗口。标题稀疏时改用结构化 `s2`–`s5`。

### 深度研究（URL 只出现一次）

```bash
curl https://r.jina.ai/https://example.com/article \
  -H 'x-retain-links: text' \
  -H 'x-with-links-summary: true' \
  -H 'x-retain-images: alt'        # 或 x-preset: research
```

行内干净锚文本，文末一份去重 URL 清单供引用。gpt-oss 引用令牌用 `x-retain-links: gpt-oss`。

### 可视化快照（多模态推理）

```bash
curl https://r.jina.ai/https://example.com/article \
  -H 'x-respond-with: pageshot' \
  -H 'x-remove-overlay: true' \
  -H 'x-timeout: 30'
```

`pageshot` 整页截图（`screenshot` 仅视口）；自动选 media-idle 时序保证图片/字体画完；`x-remove-overlay` 去掉 cookie 横幅/弹窗。

### 已知模板页（只抓正文）

```bash
curl https://r.jina.ai/https://example.com/blog/post-slug \
  -H 'x-target-selector: article.post-body' \
  -H 'x-remove-selector: nav, .related-posts, .comments, footer'
```

### 注入页面脚本（点击展开内容）

YouTube 字幕是经典场景：等转录按钮出现并点击，Reader 的页面稳定逻辑（MutationObserver 200ms 无变化 → mutationIdle）随后自动接管：

```bash
curl -F 'url=https://www.youtube.com/watch?v=dQw4w9WgXcQ' \
     -F "injectPageScript=waitForSelector('ytd-video-description-transcript-section-renderer button').then((el) => el.click())" \
     -H 'Accept: application/json' \
     https://r.jina.ai/
```

注意：`injectPageScript` 可重复传（按序逐个 `frame.evaluate`）；注入会禁用提前返回优化，需设 `x-timeout`；iframe 内交互用 `injectFrameScript`。

### iframe 与 shadow DOM

默认只序列化主文档。要拉取嵌入内容（CodeSandbox、Notion/Airtable、web components 站点）：

```bash
curl 'https://r.jina.ai/https://example.com/docs-page' \
  -H 'x-with-iframe: true' \
  -H 'x-with-shadow-dom: true'    # quoted 值 = 用 blockquote 包裹 iframe 内容
```

两者都强制 network-idle 时序（慢、长），配合 `x-timeout`（最大 180s）兜底；仅需交互用 `injectFrameScript`。

### 地域/语言敏感抓取（需 premium key）

```bash
curl https://r.jina.ai/https://shop.example.com/product/123 \
  -H 'x-proxy: de' \                       # 从德国住宅 IP 出口，也可固定国家
  -H 'x-locale: de-DE' \                   # navigator.language + Accept-Language
  -H 'x-set-cookie: country=DE; Path=/'    # 注意：带 cookie 不缓存
```

### 直接上传（PDF / Office / 原始 HTML）

PDF/Office 用 `file` 字段（自动嗅探 MIME，`.pdf`/`.docx`/`.xlsx`/`.pptx` 通吃；multipart 流式、无 base64 开销；按字节 sha256 缓存）：

```bash
curl -X POST 'https://r.jina.ai/' \
  -F 'file=@./report.pdf' \
  -H 'Accept: application/json' \
  -H 'x-markdown-chunking: s3'

# 只要第 7 页（页码 1-indexed，后续翻页复用缓存解析）
curl -X POST 'https://r.jina.ai/' -F 'file=@./long-report.pdf' -F 'page=7' \
  -H 'Accept: application/json'
```

原始 HTML 用 `html` 字段（跳过抓取，直接走转换管线；`url` 可选但建议传，用于解析相对链接）：

```bash
curl -X POST 'https://r.jina.ai/' -H 'Content-Type: application/json' \
  -d '{"html": "<html>...</html>", "url": "https://example.com/source"}'
```

## 5. 自托管（Docker）

```bash
docker pull ghcr.io/jina-ai/reader:oss
```

镜像内含 headless Chrome、LibreOffice、CJK 字体。两个端口：

- `8080` — **h2c**（HTTP/2 明文，生产级，Cloud Run 用的；curl 需 `--http2-prior-knowledge`）
- `8081` — **HTTP/1.1** 兜底（浏览器/普通 curl 用）

```bash
# 无状态快速试用
docker run --rm -p 3000:8081 ghcr.io/jina-ai/reader:oss
curl http://localhost:3000/https://example.com

# 桶缓存模式（S3 兼容，缓存抓取页面）
docker run --rm -p 3000:8081 \
  -e GCP_STORAGE_ENDPOINT=https://s3.example.com \
  -e GCP_STORAGE_BUCKET=reader-cache \
  -e GCP_STORAGE_ACCESS_KEY=... \
  -e GCP_STORAGE_SECRET_KEY=... \
  ghcr.io/jina-ai/reader:oss
```

默认完全无状态：每次请求直连真实 URL，无缓存、无限流——适合试用/CI/一次性环境。完整环境变量表见 `CONTRIBUTING.md`。

## 6. 本地开发

```bash
git clone git@github.com:jina-ai/reader.git && cd reader
nvm use && npm install
docker compose up -d        # 可选：本地 MinIO 桶缓存（:9000 API / :9001 控制台）
npm run dev                 # 或 VSCode F5
```

- 要求 Node ≥ 22.15；LibreOffice 可选（测 Office 文档时用）。
- 三个独立入口：`build/stand-alone/crawl.js`（r.jina.ai 面）、`search.js`（s.jina.ai 面；启动时清掉 `'crawl'` 注册项，二者互斥）、`serp.js`（纯 SERP）。
- 测试用 **Node 内置 test runner**（禁 Jest/Vitest）：`npm run test:unit`（无 Docker）、`npm run test:e2e`（需 Docker + `.secret.local`）、`npm test` 全跑；覆盖率用 c8。
- **受许可资源**：`licensed/` 下 MaxMind GeoLite2 数据库、思源黑体、用户代理列表不随仓库分发，需 `npm run assets:download` 拉取（幂等脚本，`FORCE_DOWNLOAD_EXTERNAL=1` 强制覆盖，`SKIP_DOWNLOAD_EXTERNAL=1` 跳过）。构建的 `integrity-check.cjs` 强制要求 GeoLite2 存在，裸 `tsc` 会跳过该检查。
- `SECRETS_COMBINED`：base64 编码的 JSON，一个变量打包多个配置。

## 7. 架构要点

- 多线程 Node.js 应用；Koa HTTP 服务 + civkit 依赖注入。
- **抓取引擎**：Browser（puppeteer headless Chrome，最准）/ CURL（curl-impersonate 轻量，不执行 JS，带模拟 cookie 层）/ CF-Browser-Rendering（Cloudflare Browser Rendering REST API，限流严，测试与兜底用）/ Auto（默认组合）。
- **HTML→Markdown 多套方案**：`@mozilla/readability` 清洗 → 规则引擎（turndown 启发式自研）→ ReaderLM v2（专用小模型，实验性）→ ReaderLM v3 / JinaOCR（VLM 直接截图转 markdown，WIP）。
- **渐进式存储分级**：Stage 0 纯无状态 → Stage 1 S3 桶缓存（OSS 分支到此）→ Stage 2 MongoDB + S3（SaaS，含限流，不在本分支）。
- **滥用缓解（SaaS）**：可疑地址请求过滤、每页并发限流、匿名高流量站点临时屏蔽、HTML 节点过多/过深时降级为 text。
- **第三方能力**：代理（内置 proxy provider，住宅/数据中心 IP 池）、SERP（外部搜索提供方，如 serper.dev / Thordata / BrightData / Jina SERP）、VLM（图片描述，当前 `gemini-2.5-flash-lite`，可换）。
- **部署拓扑（SaaS）**：GCP Cloud Run Docker 镜像 + MongoDB Atlas + GCS 缓存；私有 VPC 直连计费、jina-vlm、readerlm-v2；**US / EU 两个独立集群**（US 3 区域 + EU 1 区域）；因 Chrome/LibreOffice 资源需求高，最适合 serverless 自动扩缩平台。

## 8. 反爬排障阶梯（"有些网站抓不动"）

按"被惹恼程度"递增：

1. **用 API key**：匿名流量限流最狠、信任池最低；认证后有更高配额和内部代理等能力（[jina.ai/reader](https://jina.ai/reader#pricing)）。
2. **绕过缓存**：`-H 'x-no-cache: true'`（缓存了被屏蔽/过期响应时强制新抓）。
3. **强制浏览器引擎**：`-H 'x-engine: browser'`（auto 倾向轻量 curl，有些站只给 JS 浏览器真内容）。
4. **走 SaaS 代理池**：`-H 'x-proxy: auto'`（需 key；自动轮换住宅/数据中心 IP 并处理常见反爬；可钉国家如 `x-proxy: us`）。
5. **自带代理**：`-H 'x-proxy-url: <url>'`（BrightData / Thordata / Oxylabs 等住宅/ISP 代理，支持 http/https/socks4/socks5）。

都不行就提 issue，附 URL + 用过的请求头。

## 9. 时间线与版本要点

- 2024-04 发布，r.jina.ai 上线（Jina AI 第一个 SaaS API）。
- 2024-05 s.jina.ai 上线（搜索→markdown）；当月支持 PDF。
- 2025-03 大重构：不再是 Firebase 应用，SaaS 迁到 Cloud Run + MongoDB Atlas。
- 2025-12 存储层解耦；支持 `file` 字段直接上传 PDF / Office / 原始 HTML。
- 2026-04 OSS 分支与 SaaS 代码重新对齐；默认无状态开箱即用，可选 MinIO/S3 桶缓存。

## 10. 相关链接

- 在线代码片段生成器（探索参数组合）：https://jina.ai/reader#apiform
- 线上 API 文档：https://r.jina.ai/docs
- 全站抓取 Colab：https://colab.research.google.com/drive/1uoBy6_7BhxqpFQ45vuhgDDDGwstaCt4P
- 深度问答：DeepWiki — https://deepwiki.com/jina-ai/reader
- 官方文档源：`README.md`（请求头全表）、`cookbooks.md`（配方）、`architecture.md`（架构）、`CONTRIBUTING.md`（环境变量/测试）、`CLAUDE.md`（给编码 agent 的指引）
