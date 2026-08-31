# 浏览器自动化

浏览器类 Agent 主要用于网页访问、表单填写、数据采集、自动测试和跨页面任务执行。

## 工具列表

| 名称 | 方向 | 备注 |
| --- | --- | --- |
| browser-use | 浏览器 Agent 框架 | 可用于让 Agent 操作浏览器完成网页任务。 |
| OpenCLI | 网站→CLI + 登录态浏览器自动化 | 内置 100+ 站点 adapter，Agent 可驱动已登录 Chrome，见 [cli-tools/opencli/](../cli-tools/opencli/index.md)。 |
| Playwright | 跨浏览器自动化框架 | 微软出品，三引擎同 API；安装、速查、选型与排障见 [notes/playwright.md](../notes/playwright.md)。 |
| mcp_web_search | Google 搜索绕过反爬 | 基于 Playwright + stealth，可作为 CLI 或 MCP 服务。 |
| Chromium 桌面浏览器 | Chromium + Xvfb + noVNC | Docker Compose 一键启动，支持网页远程桌面和 CDP 自动化，见 [desktop-browser/](desktop-browser/README.md)。 |

## mcp_web_search

基于 Playwright 的 Google 搜索工具，能绕过反爬机制获取搜索结果。

### 核心特性

- 浏览器指纹随机化 + 持久化状态
- playwright-stealth 反检测补丁
- 支持 CLI 和 MCP Server 两种模式
- 自动 CAPTCHA 检测与 Basic View 降级

### 安装

```bash
cd browser/mcp_web_search
pip install -r requirements.txt
playwright install chromium
```

### 使用

```bash
# CLI 搜索
python3 cli.py "搜索关键词"

# 限制结果数量
python3 cli.py --limit 5 "搜索关键词"

# 获取原始 HTML
python3 cli.py --get-html "搜索关键词"

# MCP Server 模式
python3 -m mcp_integration.server
```

### MCP 集成配置

```json
{
  "mcpServers": {
    "google-search": {
      "command": "python3",
      "args": ["-m", "mcp_integration.server"],
      "cwd": "/root/agent/browser/mcp_web_search"
    }
  }
}
```

## 常见场景

- 自动打开网页并完成点击、输入、提交等操作。
- 抓取页面结构化信息。
- 对本地 Web 应用做端到端检查。
- 辅助完成需要登录态或多步骤交互的网页任务。
- 绕过反爬机制获取 Google 搜索结果（mcp_web_search）。

## 待补充

- browser-use 的安装方式和最小示例。

Playwright 的安装、API 速查、支持的浏览器与运行模式、选型对比（vs Selenium/Puppeteer）和常见排障见 [notes/playwright.md](../notes/playwright.md)。
