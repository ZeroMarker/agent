# Brave Search API 笔记

> 官网：https://search.brave.com/　｜　Dashboard/文档：https://api-dashboard.search.brave.com
> 文档首页：`/documentation`，API Reference：`/api-reference`（如 `/api-reference/web/search/get`）
> 一句话：**独立性 + 隐私优先的搜索基础设施**——基于自建索引（不依赖 Google/Bing），一套 REST API 覆盖 Web/新闻/图片/视频/地点 搜索，并提供面向 AI Agent 的 LLM Context 与 OpenAI 兼容的 Answers 生成式接口。

## 1. 定位与核心能力

Brave Search API 使用自己的独立搜索引擎索引（与 Brave Search 浏览器同源），主打无大厂依赖、无用户追踪，官方宣称 99.9% 可用性。

| 能力 | 端点 | 适用场景 | 一句话 |
| --- | --- | --- | --- |
| **Web Search** | `GET/POST /v1/web/search` | 通用网页搜索（面向人的结果） | 核心搜索，可附带位置/富结果增强 |
| **LLM Context** | `GET/POST /v1/llm/context` | Agent/RAG/LLM grounding | 预抽取正文 + 智能分块，面向机器消费 |
| **News Search** | `GET/POST /v1/news/search` | 实时新闻、媒体监控 | 专用新闻索引 + 新鲜度过滤 |
| **Video Search** | `GET/POST /v1/videos/search` | 视频聚合/发现 | 专用视频索引，带时长/作者/缩略图 |
| **Image Search** | `GET /v1/images/search` | 图片聚合/电商/素材 | 单次最多 200 张，默认 strict 过滤，经代理缩略图 |
| **Place Search** | `GET /v1/local/place_search` | "附近" 地理发现 | 2 亿+ 地点索引，坐标/地名锚定，可 Explore 模式 |
| **Answers** | `POST /v1/chat/completions` | AI 对话/研究，OpenAI SDK 兼容 | 带引用的 AI 答案，单搜/研究多搜两种模式 |
| **Local POIs / Descriptions** | `GET /v1/local/pois`、`/v1/local/descriptions` | 地点详情（照片/评分/评论/AI 描述） | 配合 Web/Place 搜索的 id 两步取详情 |
| **Rich Search** | `GET /v1/web/rich` | 体育/天气/股票/汇率等实时垂直信息 | 先 web 搜索拿 callback_key，再取 rich 结果 |
| **Autosuggest** | `GET /v1/suggest/search` | 搜索框联想 | 实时补全，`rich=true` 带实体增强 |
| **Spellcheck** | `GET /v1/spellcheck/search` | "Did you mean" 纠错 | 独立纠错接口 |
| **Summarizer** | `/v1/summarizer/*` | — | ⚠️ **已弃用**，迁移到 Answers |

> **面向人的搜索 vs 面向 Agent**：Web Search 返回标题/URL/摘要给人类点击；要给 LLM 当工具用选 **LLM Context**（官方称其为最强大的 AI 搜索 API）；要直接得到"带引用的成品答案"用 **Answers**。

## 2. 快速开始

### 2.1 注册与拿 key（需信用卡激活套餐）

1. 到 https://api-dashboard.search.brave.com 注册邮箱账号
2. **激活套餐**：Account → Available plans 选计划并绑信用卡（没有免费档，但**每月赠送 $5 额度**，自动抵扣）
3. **创建 API Key**：API Keys 区 → Add API Key → 复制保管（视为密码，勿提交到代码库/客户端）

### 2.2 第一个请求

所有请求把 key 放在 **`X-Subscription-Token`** 请求头（不是 Bearer）：

```bash
curl "https://api.search.brave.com/res/v1/web/search?q=artificial+intelligence" \
  -H "X-Subscription-Token: YOUR_API_KEY"
```

```python
import requests
url = "https://api.search.brave.com/res/v1/web/search"
resp = requests.get(url, headers={
    "Accept": "application/json",
    "Accept-Encoding": "gzip",
    "X-Subscription-Token": "YOUR_API_KEY",
}, params={"q": "artificial intelligence"})
print(resp.json()["web"]["results"][0]["title"])
```

- Base URL：`https://api.search.brave.com/res/v1`
- 认证方式仅有 header 一种：`X-Subscription-Token: <API_KEY>`
- 建议请求头：`Accept: application/json`、`Accept-Encoding: gzip`

### 2.3 Agent Skills（官方提供）

仓库 https://github.com/brave/brave-search-skills，遵守 Agent Skills 标准，每个服务文档页都有 "View skill file" 入口：

```bash
# Claude Code
/plugin marketplace add brave/brave-search-skills
/plugin install brave-search-skills@brave-search

# 或 curl 直接装到 ~/.claude/skills
mkdir -p ~/.claude/skills && curl -sL https://github.com/brave/brave-search-skills/archive/main.tar.gz | tar xz -C ~/.claude/skills --strip-components=2 brave-search-skills-main/skills
```

环境变量 `BRAVE_SEARCH_API_KEY`（Claude Code 放 `~/.claude/settings.json` 的 `env`、Cursor 用 direnv、Codex 放 `~/.codex/config.toml` 的 `shell_environment_policy`）。

## 3. Web Search（`GET/POST /v1/web/search`）

面向人类消费的核心搜索接口。GET 或 POST（POST 时查参放 JSON body）均可。

### 请求参数速查

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填，≤400 字符、≤50 词 | 搜索词，不能为空 |
| `country` | `US` | 结果来源国家，2 位代码 |
| `search_lang` | `en` | 结果内容语言（ISO 639-1 起） |
| `ui_lang` | `en-US` | 响应元数据界面语言（`<lang>-<country>`，RFC 9110） |
| `count` | 20，1~20 | 每页结果数（**只作用于 web 结果**） |
| `offset` | 0，0~9 | 跳过页数（0 起，翻页依次 +1；页间可能有重叠） |
| `safesearch` | `moderate` | `off` 不过滤 / `moderate` 滤显性内容但保留成人域名 / `strict` 全滤 |
| `spellcheck` | `true` | 自动纠错，纠错后的词在响应的 `query.altered` 中 |
| `freshness` | 空 | `pd`(24h)/`pw`(7d)/`pm`(31d)/`py`(1y)/`YYYY-MM-DDtoYYYY-MM-DD` 自定义区间 |
| `text_decorations` | `true` | 摘要等展示字符串是否带高亮标记 |
| `result_filter` | 全部 | 逗号分隔：`discussions,faq,infobox,news,query,summarizer,videos,web,locations` |
| `units` | — | `metric` / `imperial` |
| `goggles_id` | — | ⚠️ 已弃用，改用 `goggles` |
| `goggles` | 最多 3 个 | URL 或内联定义，自定义结果重排（见 §14） |
| `extra_snippets` | `false` | 每个结果额外加最多 5 条备选摘要 |
| `summary` | `false` | 生成 summary key（Summarizer 前置开关，已弃用） |
| `enable_rich_callback` | `false` | 开启富结果回调（需 Search 套餐，见 §10） |
| `include_fetch_metadata` | `false` | 附带抓取元数据 |
| `operators` | `true` | 是否应用搜索操作符（见 §13） |

### 位置请求头（Web/LLM Context/Local 均可用）

| Header | 说明 |
| --- | --- |
| `X-Loc-Lat` / `X-Loc-Long` | 经纬度（±90 / ±180），提供本地化结果 |
| `X-Loc-Timezone` | IANA 时区（如 `America/San_Francisco`） |
| `X-Loc-City` / `X-Loc-State` / `X-Loc-State-Name` | 城市 / 州代码（≤3 字符）/ 州名 |
| `X-Loc-Country` | 2 位国家代码（ISO 3166-1 alpha-2，共 246+ 选项） |
| `X-Loc-Postal-Code` | 邮编 |

通用头：`Api-Version`（`YYYY-MM-DD` 锁定版本，默认最新）、`Cache-Control: no-cache`（尽力避免缓存）、`User-Agent`（影响移动/桌面端结果形态）。

### 响应结构

顶层字段（均可为 null）：`type`(`"search"`)、`query`、`discussions`、`faq`、`infobox`、`locations`、`mixed`（各结果类型的推荐排序）、`news`、`videos`、`web`、`summarizer`、`rich`。

`query` 对象要点：`original` / `altered`（纠错后）/ `cleaned`、`more_results_available`（**翻页判断用这个，别盲目递增 offset**）、`spellcheck_off`、`is_navigational`、`is_geolocal`、`local_decision`、`is_trending`、`is_news_breaking`、`ask_for_location`、`country`、`lat/long/postal_code/city/state`、`summary_key`、`search_operators`（`applied` / `cleaned_query` / `sites`）。

`web.results[]` 关键字段：`title`、`url`、`description`、`age`（ISO 时间）、`page_age`、`page_fetched`、`profile`、`meta_url`（scheme/netloc/hostname/favicon/path）、`extra_snippets`、`icons`、`language`、`family_friendly`、`type`。

### 新鲜度速查（Web/News/Videos/LLM Context 通用）

`pd` = 24h 内 · `pw` = 7 天内 · `pm` = 31 天内 · `py` = 365 天内 · `2022-04-01to2022-07-30` = 自定义区间。

## 4. News Search（`GET/POST /v1/news/search`）

专用新闻索引，来自全球可信新闻源。

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填 | 同 Web（≤400 字符/50 词） |
| `country` | `US`，或 `ALL` | 支持 `ALL` 全球 |
| `search_lang` / `ui_lang` | `en` / `en-US` | 语言偏好 |
| `safesearch` | **`strict`**（比 Web 严格） | off/moderate/strict |
| `count` | 20，1~**50** | 比 Web 上限高 |
| `offset` | 0，0~9 | 翻页 |
| `spellcheck` | `true` | 纠错 |
| `freshness` | 空 | pd/pw/pm/py/自定义 |
| `extra_snippets` | `false` | 最多 5 条备选摘要 |
| `goggles` | 最多 3 个 | 支持新闻源重排 |
| `operators` | `true` | 搜索操作符 |

响应：`type`(`"news"`)、`query`、`results[]`（`news_result`：`title`/`url`/`description`/`age`/`breaking`/`thumbnail`/`meta_url`/`extra_snippets`/`icons`/`profile`）。

## 5. Video Search（`GET/POST /v1/videos/search`）

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填 | 同前 |
| `country`（可 `ALL`）、`search_lang`、`ui_lang` | `US` / `en` / `en-US` | 定位与语言 |
| `safesearch` | `moderate` | off/moderate/strict |
| `count` | 20，1~50 | — |
| `offset` | 0，0~9 | — |
| `spellcheck` | `true` | — |
| `freshness` | 空 | pd/pw/pm/py/自定义 |
| `operators` | `true` | — |

响应：`type`(`"videos"`)、`query`、`results[]`（`video_result`：`video{duration,views,creator,publisher,requires_subscription,tags,author}`、`thumbnail`、`meta_url`）、`extra{might_be_offensive}`。

## 6. Image Search（`GET /v1/images/search`）

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填 | — |
| `country`（可 `ALL`）、`search_lang` | `US` / `en` | 无 `ui_lang` |
| `safesearch` | **`strict`** | **只有 `off` / `strict` 两档** |
| `count` | 50，1~**200** | 单次可拿很多；**无 offset、不支持分页**，要更多直接加大 count |
| `spellcheck` | `true` | 纠错 |

- **缩略图代理**：`thumbnail.src` 是经 Brave 代理的 500px 宽图（保持宽高比），保护源站与用户隐私；原图在 `properties.url`，另有 `properties.placeholder` 占位图。
- 响应：`type`(`"images"`)、`query`、`results[]`（`title`/`url`/`source`/`thumbnail{src,width,height}`/`properties{url,placeholder,width,height}`/`meta_url`/`confidence`）、`extra{might_be_offensive}`。

## 7. Place Search + Local POIs（`GET /v1/local/place_search`、`/local/pois`、`/local/descriptions`）

Place Search 面向"地理实体"而非网页：2 亿+ 地点，支持坐标或地名锚定。

### 请求参数

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `latitude` / `longitude` | 必填成对 | 搜索中心（±90 / ±180） |
| `location` | 备选 | 地名代替坐标：美国 `城市 州 国家`（`san francisco ca united states`），其他 `城市 国家`（`tokyo japan`），大小写/逗号无关，支持多语言 |
| `q` | 可选 | 要找什么；**省略 q = Explore 模式**（给定区域快照，适合地图视图） |
| `radius` | 可选 | 搜索半径偏置（米）；**只偏置不是硬截断**；<~20km 结果最聚焦 |
| `count` | 20，1~100 | 结果数 |
| `country` / `search_lang` / `ui_lang` / `units` | `US`/`en`/`en-US`/`metric` | 区域与偏好 |
| `safesearch` | `strict` | off/moderate/strict |
| `spellcheck` | `true` | — |

### 响应结构

顶层：`type`(`"locations"`)、`query{original,altered,spellcheck_off,show_strict_warning}`、`results[]`、`cities[]`、`countries[]`、`regions[]`、`neighborhoods[]`、`addresses[]`、`streets[]`、`mixed[]`（按序取各桶元素的 SERP 排序提示：`{type, index, all}`）、`location{coordinates,name,country}`。各桶均可为 null，POI 类查询通常只填 `results`。

`LocationResult` 字段：`id`（临时 id，**约 8 小时后过期，勿存储**）、`title`、`url`、`provider_url`（如 yelp 页）、`coordinates`、`postal_address`（displayAddress/streetAddress/addressLocality/addressRegion/postalCode/country）、`opening_hours`（current_day/days）、`contact`（telephone/email）、`rating`（ratingValue/bestRating/reviewCount）、`price_range`（如 `$$`）、`distance`（value/units）、`categories`、`serves_cuisine`、`thumbnail`（src/original）、`pictures`、`profiles`、`timezone`、`zoom_level`。

### 详情端点（两步取详情，Web 与 Place 的 id 通用）

```bash
# 详细 POI（照片、评论、外部 profile、网页提及等）
curl "https://api.search.brave.com/res/v1/local/pois?ids=<id1>&ids=<id2>" -H "X-Subscription-Token: KEY"
# AI 生成的地点描述
curl "https://api.search.brave.com/res/v1/local/descriptions?ids=<id1>" -H "X-Subscription-Token: KEY"
```

- `/local/pois`：参数 `ids`（必填，最多 20 个）、`search_lang`、`ui_lang`、`units` + `X-Loc-Lat/Long` 头；响应 `type:"local_pois"`。
- `/local/descriptions`：**只接受 `ids`**（最多 20 个）；响应 `type:"local_descriptions"`，每条 `{description}`。
- id 临时性：约 8 小时过期，不要长期存储。

## 8. LLM Context（`GET/POST /v1/llm/context`）⭐ Agent 首选

Web Search 的"机器版"：预抽取网页正文 → 相关性重排 → 智能分块，一次调用拿到可直接喂 LLM 的 grounding 内容。官方定位：给 agent/chatbot 当 web 搜索工具。

### 参数（查询参数，POST 时放 JSON body）

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填 | ≤400 字符/50 词 |
| `country`（`US`）/ `search_lang`（`en`）/ `spellcheck`（`true`） | — | 基础控制 |
| `count` | 20，1~50 | 参与上下文选择的搜索结果数 |
| `safesearch` | 未设=不过滤 | off/moderate/strict；**local recall 时恒为 strict** |
| `maximum_number_of_urls` | 20，1~50 | 响应中最多 URL 数 |
| `maximum_number_of_tokens` | 8192，1024~32768 | 上下文近似 token 上限（**绑定限制**） |
| `maximum_number_of_snippets` | 50，1~256 | 全部 URL 的片段总数上限 |
| `maximum_number_of_tokens_per_url` | 4096，512~8192 | 单 URL token 上限 |
| `maximum_number_of_snippets_per_url` | 50，1~100 | 单 URL 片段数上限 |
| `context_threshold_mode` | 未设=自校准 | `strict`(少而精) / `balanced` / `lenient`(多而杂) / `disabled`(不过滤) |
| `goggles` | 最多 3 个 | 限定/提升可信来源 |
| `freshness` | 空 | pd/pw/pm/py/自定义 |
| `enable_local` | `null` 自动 | `null`=有位置头才开 local；`true` 强制；`false` 强制标准 |
| `enable_source_metadata` | `false` | 给 `sources[url]` 附带 site_name/favicon/thumbnail/description |

位置头同 Web（§3）。

### 响应格式

```json
{
  "grounding": {
    "generic": [{"url": "...", "title": "...", "snippets": ["分块文本..."]}],
    "poi": null,
    "map": []
  },
  "sources": {
    "https://example.com/page": {
      "title": "...", "hostname": "example.com",
      "age": ["Monday, January 15, 2024", "2024-01-15", "380 days ago", "2024-01-15T13:45:02Z"]
    }
  }
}
```

- `sources.age` 固定 4 个位置：完整日期 / YYYY-MM-DD / 相对时间 / ISO 8601 时间戳（第 4 个是最新版新增，唯一保留一天内时刻）。无日期则为空数组。
- snippets 可能是纯文本**或 JSON 序列化的结构化数据**（表格/代码/JSON schema），后处理时两种都要兼容。
- 开启 local recall 时 `grounding.poi`（对象）与 `grounding.map`（数组）可能非空。

### 预算参考（官方建议）

| 任务类型 | count | max tokens |
| --- | --- | --- |
| 简单事实问答（"Python 哪年诞生"） | 5 | 2048 |
| 常规问答（React hooks 最佳实践） | 20 | 8192（默认） |
| 深度研究（对比生产级 AI 框架） | 50 | 16384 |

超时建议设 30s；`grounding.generic` 为空表示无相关内容，属正常需处理。

## 9. Answers（`POST /v1/chat/completions`）— OpenAI 兼容 AI 答案

直接生成"被网络事实支撑 + 可验证引用"的成品答案（Brave 自身 Ask Brave 同款技术，SimpleQA 基准 SOTA）。**需 Answers 套餐**，限流 2 req/s（不足可邮件 searchapi-support@brave.com 协商）。

### 用法（OpenAI SDK，base_url 指向 `/res/v1`）

```python
from openai import OpenAI
client = OpenAI(api_key="YOUR_BRAVE_KEY", base_url="https://api.search.brave.com/res/v1")
resp = client.chat.completions.create(
    messages=[{"role": "user", "content": "What are the best things to do in Paris with kids?"}],
    model="brave", stream=False,
)
print(resp.choices[0].message.content)
```

### 参数

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `model` | `brave-pro` | `brave` / `brave-pro` |
| `messages` | 必填 | 只支持 **恰好一条 user 消息** |
| `stream` | `true` | 流式输出 |
| `max_completion_tokens` / `metadata` / `seed` | — | SDK 兼容字段（后两者被忽略） |
| `web_search_options.country` | `us` | 搜索结果国家 |
| `web_search_options.language` | `en` | 回答语言 |
| `web_search_options.safesearch` | `moderate` | off/moderate/strict |
| `enable_citations` | `false` | 内联引用标记；**需 stream=true**，research 模式不支持 |
| `enable_entities` | `false` | 内联实体标记；需 stream=true，research 不支持 |
| `enable_research` | `false` | 迭代式深度研究（多搜）；需 stream=true |
| `research_allow_thinking` | `true` | research 是否允许输出思考 |
| `research_maximum_number_of_tokens_per_query` | 8192（1024~16384） | 每轮研究的 token 预算 |
| `research_maximum_number_of_queries` | 20（1~50） | 总查询次数上限 |
| `research_maximum_number_of_iterations` | 4（1~5） | 迭代轮数上限 |
| `research_maximum_number_of_seconds` | 180（1~300） | 时间预算 |
| `research_maximum_number_of_results_per_query` | 30（1~60） | 每轮考虑的结果数 |

### 单搜 vs 研究模式

| | 单搜（默认） | 研究模式 |
| --- | --- | --- |
| 速度 | 平均 <4.5s 出流 | 可达数分钟（SimpleQA p99 约 300s / 53 次查询 / 1000 页） |
| 成本 | 低 | 高（多次搜索 + 大上下文） |
| 适用 | 实时交互、大部分问题 | 后台任务、重研究 |

### 流式应答的特殊标记（必须处理）

- 普通文本：正常内容。
- `<citation>{"start_index":0,"end_index":10,"number":1,"url":"...","favicon":"...","snippet":"..."}</citation>`：内联引用。
- `<usage>{"X-Request-Requests":1,"X-Request-Queries":2,"X-Request-Tokens-In":1234,"X-Request-Tokens-Out":300,"X-Request-Total-Cost":0.01567}</usage>`：用量元数据，流式的最后一条；同步请求时这些键在响应头里。

### 计费公式

```
cost = (searches × $4/1000) + (input_tokens × $5/1000000) + (output_tokens × $5/1000000)
```

例：2 searches + 1234 in + 300 out = $0.008 + $0.00617 + $0.0015 = **$0.01567**。可在账号里设月度额度上限；额度在"开答前"检查，开始后超限也会答完，最多只按额度扣费。

## 10. Rich Search（`GET /v1/web/rich`）— 实时垂直数据

**两步流程**（需 Search 套餐）：

```bash
# 1) Web 搜索加 enable_rich_callback=1，若命中返回 rich.hint
curl "https://api.search.brave.com/res/v1/web/search?q=weather+in+munich&enable_rich_callback=1" -H "X-Subscription-Token: KEY"
# 响应里的 callback_key（示例）
# "rich": {"type":"rich","hint":{"vertical":"weather","callback_key":"86d06abffc884e9..."}}
# 2) 用 callback_key 取富结果
curl "https://api.search.brave.com/res/v1/web/rich?callback_key=86d06abffc884e9..." -H "X-Subscription-Token: KEY"
```

垂直类型（`subtype` 区分，均来自第三方数据源，部分需署名）：

| 类别 | 数据源 |
| --- | --- |
| Calculator / 单位换算 / Unix 时间戳 / 包裹追踪 | — |
| 词典定义 | Wordnik |
| 股票 | FMP |
| 汇率 | Fixer |
| 加密货币 | CoinGecko |
| 天气 | OpenWeatherMap |
| 美式足球 NFL/CFB、板球 IPL/PSL、足球（MLS/英超/西甲/意甲/欧冠/世界杯…大量联赛） | Stats Perform |
| 棒球 MLB、篮球 NBA/欧洲各联赛、冰球 NHL/Liiga、F1 | API Sports |

## 11. Autosuggest 与 Spellcheck

### Autosuggest（`GET /v1/suggest/search`）

即时联想补全，对错字有韧性：

| 参数 | 默认/范围 | 说明 |
| --- | --- | --- |
| `q` | 必填 | ≤400 字符/50 词 |
| `lang` / `country` | `en` / `US` | 仅作计算提示 |
| `count` | 5，1~20 | 建议条数 |
| `rich` | `false` | 富联想（标题/描述/图片/实体识别），**需付费 Autosuggest 套餐** |

响应：`type:"suggest"`、`query{original}`、`results[]{query, is_entity, title, description, img}`（`type`/`is_entity`/`title` 等富字段仅在 rich 时有）。

### Spellcheck（`GET /v1/spellcheck/search`）

独立纠错：`q` 必填 + `lang`/`country` 提示。响应 `type:"spellcheck"`、`query{original}`、`results[]{query}`——拼对时 `results` 为空数组，拼错给出修正（支持多词）。适合做 "Did you mean"。

## 12. Summarizer（⚠️ 已弃用 → 用 Answers）

传统两步流：`/v1/web/search?summary=1` → 响应 `summarizer.key`（不透明字符串，别解析）→ `GET /v1/summarizer/search?key=<URLENCODED>&entity_info=1`。另有 `/summarizer/summary`、`summary_streaming`、`title`、`enrichments`、`followups`、`entity_info` 专用端点，`inline_references=true` 可加内联引用。**Summarizer 调用不扣费，只有前置 web 搜索计费**。官方已标注 Deprecated，新项目一律用 Answers（§9）。

## 13. 搜索操作符（在 `q` 内使用，非独立参数）

| 操作符 | 说明 | 示例 |
| --- | --- | --- |
| `"..."` | 精确短语 | `harry potter "order of the phoenix"` |
| `-` | 排除词 | `office -microsoft` |
| `+` | 强制包含 | `gpu +freesync` |
| `site:` | 限域名（含子域） | `goggles site:brave.com` |
| `filetype:` / `ext:` | 指定文件类型 | `Honda GX120 manual filetype:pdf` |
| `intitle:` | 标题含词 | `seo conference intitle:2023` |
| `inbody:` | 正文含词 | `nvidia 1080 ti inbody:"founders edition"` |
| `inpage:` | 标题或正文含词 | `oscars 2024 inpage:"best costume design"` |
| `lang:` / `language:` | 限定语言（ISO 639-1） | `visas lang:es` |
| `loc:` / `location:` | 限定国家/地区（ISO 3166-1 alpha-2） | `niagara falls loc:ca` |
| `AND` / `OR` / `NOT` | 逻辑组合（**必须大写**） | `visa loc:gb AND lang:en` |

Web/News/Video 默认启用（`operators=true`）。组合示例：`climate change filetype:pdf site:edu intitle:2024`。

## 14. Goggles（自定义重排 DSL）

Web Search / News Search / LLM Context 都支持 `goggles` 参数：1）托管 URL（需先在 https://search.brave.com/goggles/create 注册提交）2）内联定义（`$boost=3,site=dev.to`；多条规则用 `\n` 分隔，即编码 `%0A`）3）混合，**每次最多 3 个**。

| 语法 | 作用 | 示例 |
| --- | --- | --- |
| `$boost` / `$boost=N` | 提升排名（N=1~10 强度） | `$boost=3,site=dev.to` |
| `$downrank` / `$downrank=N` | 降低排名 | `$downrank=5,site=w3schools.com` |
| `$discard` | 完全移除 | `$discard,site=facebook.com` |
| `site=` | 匹配域名 | `$boost,site=dev.to` |
| 路径模式 | 匹配 URL 路径 | `/blog/$boost` |
| 通配符 `*` | 任意字符 | `*/api/*$boost` |

冲突时优先级：`$discard` > `$boost` > `$downrank`；同级强度高的赢。文件头可用 `! name / ! description / ! public / ! author` 元信息。

## 15. 认证与版本

- **认证**：唯一方式 `X-Subscription-Token: <API_KEY>` 请求头（key 从 dashboard 创建）。
- **URL 主版本**：`/res/v1/...` 中的 `v1`，仅重大重构才变。
- **日期版本**：向后不兼容变更用日期标注（`YYYY-MM-DD`），通过 `Api-Version` 请求头锁定，**不传默认最新版**（例：LLM Context 新内容管线 `2026-07-31` 上线，想保留旧管线可钉 `Api-Version: 2026-02-06`）。
- 兼容性规则：新增可选参数/响应字段 = 兼容；删除/重命名/改类型 = 不兼容，需升级。

## 16. 限流（1 秒滑动窗口）

所有套餐按 **1 秒滑动窗口**计数（请求到达即计数，与处理时长无关），超限返回 **429**。**只有成功（非错误）请求才计入配额和计费**。

响应头（每个响应都带，用它们实现限流逻辑）：

| Header | 示例 | 含义 |
| --- | --- | --- |
| `X-RateLimit-Limit` | `1, 15000` | 每秒 / 每月上限（0=不限） |
| `X-RateLimit-Policy` | `1;w=1, 15000;w=2592000` | 对应窗口（秒） |
| `X-RateLimit-Remaining` | `0, 14523` | 各窗口剩余 |
| `X-RateLimit-Reset` | `1, 1234567` | 距重置的秒数 |

收到 429 时按 `X-RateLimit-Reset` 等待 + 指数退避重试；请求分散开避免吃每秒上限。

## 17. 错误码

| 状态码 | 含义 |
| --- | --- |
| 400 | 请求无效（如 Local POIs 缺 ids） |
| 402 | Payment Required（Answers 额度/付费问题） |
| 403 | Forbidden |
| 404 | 资源不存在 |
| 422 | 参数校验失败（Unprocessable Entity） |
| 429 | 限流 / 超出配额 |

错误体统一为：`{"type":"ErrorResponse","error":{"id","status","detail","meta","code"},"time":0}`。

## 18. 计费（套餐，全部 Postpaid 后付费 + 每月送 $5 额度）

| 套餐 | 价格 | 容量 | 包含 |
| --- | --- | --- | --- |
| **Search** | **$5 / 1,000 请求** | 50 req/s | Web Search、LLM Context、News、Videos、Images、Place Search、Rich |
| **Answers** | **$4 / 1,000 查询 + $5 / 1M 输入 token + $5 / 1M 输出 token** | 2 req/s | AI 生成答案（单搜/研究模式） |
| **Spellcheck** | $5 / 10,000 请求 | 100 req/s | Spellcheck + Autosuggest + 富联想 |
| **Autosuggest** | $5 / 10,000 请求 | 100 req/s | Spellcheck + Autosuggest + 富联想 |
| **Enterprise** | 定制 | 定制 | 合同/NDA/ZDR（零数据保留）、开票、企业支持 |

- 激活套餐需信用卡（无免费档），每月自动赠送 $5 抵扣。
- 已停售 Pro AI 套餐（Summarizer 老用户可用到弃用过渡结束）。
- "每月 $5 + 50 万次用量"等推广活动以 dashboard 实际显示为准。

## 19. 相关链接

- 文档首页：https://api-dashboard.search.brave.com/documentation（每页有 "Copy page as Markdown for LLMs" 按钮，方便抓取）
- API Reference：https://api-dashboard.search.brave.com/api-reference（Web/Local/Place/News/Videos/Images/Answers/Suggest/Spellcheck 全端点）
- Playground：`/documentation/playground`　·　定价：`/documentation/pricing`
- 状态更新：`/documentation/resources/status-updates`
- Goggles 创建：https://search.brave.com/goggles/create　·　示例库：https://github.com/brave/goggles-quickstart
- 搜索操作符文档：`/documentation/resources/search-operators`
- Agent Skills 仓库：https://github.com/brave/brave-search-skills
- 注册/Dashboard：https://api-dashboard.search.brave.com（web 端点示例 `/res/v1/web/search` 等均免登录可先看文档试玩）