---
description: 使用 mcp_web_search 绕过 Google 反爬机制进行网页搜索。需要搜索最新信息、DuckDuckGo/Bing 结果不理想、或需要获取 Google 搜索结果时使用。
---

# Web Search Skill

使用 mcp_web_search 绕过 Google 反爬机制进行网页搜索。

## 适用场景

- 需要搜索最新信息、文档或技术资料
- DuckDuckGo/Bing 搜索结果不理想
- 需要获取 Google 搜索结果

## 工具路径

`~/agent/browser/mcp_web_search/`

## 使用方式

### CLI 模式

```bash
# 基本搜索
python3 ~/agent/browser/mcp_web_search/cli.py "搜索关键词"

# 限制结果数量
python3 ~/agent/browser/mcp_web_search/cli.py --limit 5 "搜索关键词"

# 使用 Basic View（绕过 CAPTCHA）
python3 ~/agent/browser/mcp_web_search/cli.py -b "搜索关键词"
```

### 输出格式

JSON 格式，包含 `title`、`link`、`snippet` 字段。

## 注意事项

- 搜索耗时约 5-15 秒
- 首次运行会创建浏览器状态文件 `browser-state.json`
- 频繁搜索可能触发 CAPTCHA，使用 `-b` 参数降级到 Basic View
- 需要已安装 playwright 和依赖（`pip install -r requirements.txt`）

## 依赖

- Python 3.8+
- playwright
- playwright-stealth
- beautifulsoup4
