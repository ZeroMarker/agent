# Tavily 笔记

> 官网：https://www.tavily.com/
> API 文档：https://docs.tavily.com/（任何文档页 URL 后加 `.md` 可拿到 Markdown 版本；全量索引 `https://docs.tavily.com/llms.txt`、全文 `llms-full.txt`）
> 一句话：**"AI Agent 的 web 层"** —— 把实时搜索、网页正文提取、站点爬取/建图、带引用的研究报告，统一封装成 LLM 友好的干净内容（而不是原始 HTML），让 Agent 少花 token 去解析、过滤、猜相关性。

## 1. 定位与核心能力

Tavily 是面向 Agent 消费的搜索/抓取 API，与"返回标题+URL+摘要的普通 web search function-calling"不同，它直接给出**干净、排序、带相关性打分**的结果。

| 能力 | 端点 | 适用时机 | 一句话 |
| --- | --- | --- | --- |
| **Search** | `POST /search` | 不知道来源、需要最新网络上下文 | 实时 web 搜索，结果可直接喂给 LLM |
| **Extract** | `POST /extract` | 已有 URL（或从 Search 挑出来） | 把 1~20 个 URL 转成干净的 markdown/text 正文 |
| **Map** | `POST /map` | Crawl 之前先了解站点结构 | 像图一样遍历站点，生成站点地图（URL 列表） |
| **Crawl** | `POST /crawl` | 需要读一个站点的很多页面 | 图式遍历 + 内置提取，一次拿到多页内容 |
| **Research** | `POST /research` | 输出应是带引用的综合报告/对比/结论 | 多次搜索 + 源分析 + 生成带引用的研究报告 |

> **Search 还是 Research？** 需要原始来源 URL/内容自己加工 → Search；需要一份"多来源、带引用、可直接交付"的成品 → Research。

## 2. 快速开始

### 2.1 免 key（Keyless）—— 零配置试用

Search 和 Extract 可以不注册、不拿 key 直接用，响应 schema 与带 key 完全一致。只需要请求头 `X-Tavily-Access-Mode: keyless`：

```bash
# Search
curl -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -H "X-Tavily-Access-Mode: keyless" \
  -d '{"query": "latest AI news", "max_results": 3}'

# Extract
curl -X POST https://api.tavily.com/extract \
  -H "Content-Type: application/json" \
  -H "X-Tavily-Access-Mode: keyless" \
  -d '{"urls": ["https://www.tavily.com"]}'
```

- 免费但有速率限制；撞到上限时 API 会返回自然语言指引告诉你怎么继续（注册免费 key，1000 credits/月，无需信用卡）。
- Crawl / Map / Research 必须带 API key。
- 同时带 keyless 头和有效 `Authorization: Bearer` 时，API key 优先。

### 2.2 注册拿 key

到 https://app.tavily.com 注册，从 dashboard 复制 API key（`tvly-` 开头）。免费档每月 1000 credits，无需信用卡。

```bash
curl -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer tvly-YOUR_API_KEY" \
  -d '{"query": "Who is Leo Messi?"}'
```

### 2.3 SDK

```bash
pip install tavily-python      # Python
npm i @tavily/core             # JavaScript
```

```python
from tavily import TavilyClient

client = TavilyClient(api_key="tvly-YOUR_API_KEY")
resp = client.search("Who is Leo Messi?")      # search / extract / crawl / map / research
print(resp)
```

### 2.4 CLI

```bash
pip install tavily-cli
tvly login        # 浏览器认证
tvly search "latest AI news"
tvly extract "https://example.com"
tvly crawl "https://docs.example.com" --depth 2
tvly research "compare React vs Svelte for production apps"
```

安装 CLI 会同时装好给 Claude Code / Cursor / Codex 的 Agent Skills，提醒 agent 优先用 Tavily。

### 2.5 MCP

远程 MCP 服务器，无需本地安装：

```
https://mcp.tavily.com/mcp/?tavilyApiKey=<your-api-key>
```

- 支持 OAuth 2.0（可不硬编码 key）：`claude mcp add tavily-remote-mcp --transport http https://mcp.tavily.com/mcp/`
- Keyless 用法：给 MCP 加请求头 `X-Tavily-Access-Mode: keyless`（只提供 `tavily-search` / `tavily-extract` 两个工具）
- MCP 会自动填充 `X-Session-Id`（无需手动设置）；`X-Human-Id` 需要 agent/开发者自己传

## 3. Search 端点（`POST /search`）

### 请求参数速查

| 参数 | 取值/默认 | 说明 |
| --- | --- | --- |
| `query` | 必填 | 搜索查询词 |
| `search_depth` | `basic`(默认) / `advanced` / `fast` / `ultra-fast` | 延迟 vs 相关性权衡；`advanced` 2 credits，其余 1 credit；`ultra-fast` 每个 URL 只返回一条 NLP 摘要 |
| `chunks_per_source` | 默认 3，范围 1~3 | 每个来源返回的相关片段数（每片段 ≤500 字符），内容以 `<chunk 1> [...] <chunk 2>` 拼接；`advanced`/`basic`/`fast` 可用 |
| `max_results` | 默认 5，范围 0~20 | 返回结果条数 |
| `topic` | `general`(默认) / `news` / `finance` | 类别；`news` 适合实时政治/体育/大事 |
| `time_range` | `day` / `week` / `month` / `year`（或 `d`/`w`/`m`/`y`） | 按发布时间过滤 |
| `start_date` / `end_date` | `YYYY-MM-DD` | 按日期区间过滤 |
| `include_answer` | `false` / `true`(basic) / `advanced` | 是否返回 LLM 生成的答案 |
| `include_raw_content` | `false` / `markdown` / `text` | 附带每个结果的清洗后正文（`text` 更慢） |
| `include_images` | `false` | 返回顶层图片列表 + 每个结果的图片 |
| `include_image_descriptions` | `false` | 配合 `include_images` 给图片加描述 |
| `include_favicon` | `false` | 每个结果带 favicon URL |
| `include_domains` | 最多 300 个 | 只搜这些域名 |
| `exclude_domains` | 最多 150 个 | 排除这些域名 |
| `country` | 国家枚举 | 仅 `topic=general` 时可用，加权该国内容 |
| `auto_parameters` | `false` | 按查询意图自动配置参数（可能自动升到 advanced=2 credits，可显式设 `basic` 压成本）；`include_answer`/`include_raw_content`/`max_results` 仍需手动 |
| `exact_match` | `false` | 只返回包含查询中精确引号短语的结果（查询里用 `"..."` 圈词） |
| `include_usage` | `false` | 返回本次 credit 消耗 |
| `safe_search` | `false` | 🔒 Enterprise only，过滤成人内容；不支持 `fast`/`ultra-fast` |

### 响应结构

`query`、`results[]`（`title`/`url`/`content`/`score`/`raw_content`/`favicon`/`images`/`id`）、`images`、`answer`、`auto_parameters`、`response_time`、`usage`、`request_id`。

### Agent 推荐默认值（官方 best practices）

```python
client.search(
    "your query",
    search_depth="advanced",   # 高质量优先；快速查询用 basic
    chunks_per_source=3,       # 每个来源更多证据
    max_results=5,             # 聚焦答案用 5，广泛调研用 10
)
```

- 来源可信度重要时用 `include_domains` / `exclude_domains`
- 需要落地答案建议 **Search → Extract** 组合：先搜来源，再 Extract 全文
- 除非只要一个快速答案种子，否则少用 `include_answer`（并仍要对照来源核实）

## 4. Extract 端点（`POST /extract`）

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `urls` | 必填，单个 URL 或数组，最多 20 个 | 要提取的页面 |
| `query` | 可选 | 用户意图，提供后按相关性对内容片段重排 |
| `chunks_per_source` | 3，范围 1~5 | 仅 `query` 提供时可用 |
| `extract_depth` | `basic` / `advanced` | `advanced` 提取更多数据（含表格、嵌入内容）、成功率更高但更慢 |
| `include_images` / `include_favicon` | `false` | 附带图片/图标 |
| `format` | `markdown`(默认) / `text` | 输出格式 |
| `timeout` | 1~60 秒 | 不设则 basic 10s / advanced 30s |
| `include_usage` | `false` | 返回 credit 消耗 |

响应含 `results[]`（`url` / `raw_content` / `images` / `favicon`）和 `failed_results[]`（失败 URL + 错误原因）。**提取失败的 URL 不扣费。**

## 5. Map 端点（`POST /map`）

图式遍历站点，返回发现的 URL 列表（`base_url` + `results[]`）：

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `url` | 必填 | 起始根 URL（可省略协议，如 `docs.tavily.com`） |
| `instructions` | 可选 | 自然语言指令（如"找所有 Python SDK 相关页面"），指定后每 10 页 2 credits 而非 1 |
| `max_depth` | 1，范围 1~5 | 从根 URL 出发的探索深度 |
| `max_breadth` | 20，范围 1~500 | 每层最多跟随的链接数 |
| `limit` | 50 | 总共处理的链接数上限 |
| `select_paths` / `select_domains` | 正则数组 | 只保留匹配的路径/域名（如 `/docs/.*`、`^docs\.example\.com$`） |
| `exclude_paths` / `exclude_domains` | 正则数组 | 排除匹配的路径/域名 |
| `allow_external` | `true` | 最终结果是否包含站外链接 |
| `timeout` | 10~150 秒 | 超时上限 |

## 6. Crawl 端点（`POST /crawl`）

Map 的参数全部适用，额外支持：

| 参数 | 说明 |
| --- | --- |
| `instructions` | 提供后可用 `chunks_per_source`（1~5）控制每页返回的相关片段 |
| `extract_depth` | `basic` / `advanced`（同 Extract） |
| `format` | `markdown` / `text` |
| `include_images` / `include_favicon` | 附带图片/图标 |

响应是 `results[]`，每项含 `url` + 提取出的内容。**成本 = Map 成本 + Extract 成本**：
- 爬 10 页 + basic 提取 = 1（mapping）+ 2（10 次成功提取 ÷5）= 3 credits
- 爬 10 页 + advanced 提取 = 1 + 4 = 5 credits

## 7. Research 端点（`POST /research`）

异步任务：先 `POST /research` 拿到 `request_id`（status 通常 `pending`），再轮询 `GET /research/{request_id}` 获取状态与结果；`stream=true` 时改为 SSE 流式返回。

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `input` | 必填 | 研究任务/问题 |
| `model` | `auto`(默认) / `mini` / `pro` | `mini` 适合范围窄、聚焦的问题；`pro` 适合跨子主题的复杂课题 |
| `stream` | `false` | SSE 流式返回研究进度与结果 |
| `output_schema` | JSON Schema | 让报告输出符合指定结构（须含 `properties`，可含 `required`） |
| `citation_format` | `numbered`(默认) / `mla` / `apa` / `chicago` | 引用格式 |
| `include_domains` | 最多 20 个 | 软偏好来源域名（主机级匹配，含子域名） |
| `exclude_domains` | 最多 20 个 | 硬屏蔽域名（向下匹配：屏蔽 `medium.com` 同时屏蔽 `blog.medium.com`，反之不行） |
| `output_length` | `standard`(默认) / `short` / `long` | 输出体量（目标是范围而非硬上限） |
| `files` | 最多 5 个 | 附带本地文件（`.txt` / `.md` / `.json`，base64），agent 会结合文件内容作答并引用；单文件 ≤8 万词、合计 ≤8 万词 |

### Research 成本（动态计费）

| | `model=pro` | `model=mini` |
| --- | --- | --- |
| 单次最低 | 15 credits | 4 credits |
| 单次最高 | 250 credits | 110 credits |

## 8. 计费（Credits）

- 免费：每月 **1,000 credits**（无需信用卡）
- 按量付费：$0.008 / credit；月付计划：$0.0075 ~ $0.005 / credit（Project $30/4k、Bootstrap $100/15k、Startup $220/38k、Growth $500/100k）
- Enterprise：定制价格与用量

各端点扣费规则：

| 操作 | 扣费 |
| --- | --- |
| Search `basic` / `fast` / `ultra-fast` | 1 credit / 次 |
| Search `advanced` | 2 credits / 次 |
| Extract `basic` | 1 credit / 每 5 个成功 URL（失败不扣） |
| Extract `advanced` | 2 credits / 每 5 个成功 URL（失败不扣） |
| Map（普通） | 1 credit / 每 10 页 |
| Map（带 `instructions`） | 2 credits / 每 10 页 |
| Crawl | Map 成本 + Extract 成本 |
| Research | 见上表动态范围 |

## 9. 速率限制

| 端点/环境 | Development | Production |
| --- | --- | --- |
| 默认（search/extract/map） | 100 RPM | 1,000 RPM |
| `/crawl` | 100 RPM | 100 RPM |
| `/research`（创建任务） | 20 RPM | 20 RPM（轮询状态走默认限流） |
| `/usage` | 10 次 / 10 分钟 | 10 次 / 10 分钟 |

- 超限返回 `429`，带 `retry-after` 响应头指明等待秒数，建议按该值做重试。
- Production key 需要付费套餐或开启 PAYGO。
- 错误码速记：400 请求无效、401 key 缺失/错误、429 限流、432 超出套餐/单 key 限额、433 超出 PAYGO 上限、500 服务端错误。所有错误响应均为 `{"detail": {"error": "..."}}`。

## 10. 进阶配置

### 项目追踪 / 会话追踪（请求头）

- `X-Project-ID`：一个 API key 多个项目共用时，按项目归集用量（`/logs` 与用量面板可按项目筛选）；SDK 用 `project_id` 参数或 `TAVILY_PROJECT` 环境变量。
- `X-Session-Id`：一次多步交互/对话的会话标识，便于归因分析。
- `X-Human-Id`：最终端用户标识（Tavily 存储前会哈希，保护隐私）。

### 可用性

- 环境变量（SDK）：`TAVILY_API_KEY`、`TAVILY_PROJECT`
- 状态页：https://status.tavily.com
- 认证方式：`Authorization: Bearer tvly-xxx`（或 keyless 头）

## 11. 相关链接

- 官方文档（llms.txt 索引）：https://docs.tavily.com/llms.txt
- Agent 接入指南（官方推荐 Agent 先读这篇）：https://docs.tavily.com/agents.md
- 文档全文（一次性抓取）：https://docs.tavily.com/llms-full.txt
- MCP 仓库：https://github.com/tavily-ai/tavily-mcp（npm：`@tavily/mcp`）
- Python SDK：`pip install tavily-python`（文档 https://docs.tavily.com/sdk/python/reference.md）
- JS SDK：`npm i @tavily/core`
- CLI：`pip install tavily-cli`
- 免费 key：https://app.tavily.com
