# 浏览器自动化

浏览器类 Agent 主要用于网页访问、表单填写、数据采集、自动测试和跨页面任务执行。

## 工具列表

| 名称 | 方向 | 备注 |
| --- | --- | --- |
| browser-use | 浏览器 Agent 框架 | 可用于让 Agent 操作浏览器完成网页任务。 |
| mcp_web_search | Google 搜索绕过反爬 | 基于 Playwright + stealth，可作为 CLI 或 MCP 服务。 |

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
- 与 Playwright、Selenium 的差异。
- 支持的浏览器和运行模式。
- 常见失败原因与调试方法。
