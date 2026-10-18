# 浏览器自动化

浏览器类 Agent 主要用于网页访问、表单填写、数据采集、自动测试和跨页面任务执行。

## 工具列表

| 名称 | 方向 | 备注 |
| --- | --- | --- |
| browser-use | 浏览器 Agent 框架 | 可用于让 Agent 操作浏览器完成网页任务。 |
| OpenCLI | 网站→CLI + 登录态浏览器自动化 | 内置 100+ 站点 adapter，Agent 可驱动已登录 Chrome，见 [cli-tools/opencli/](../cli-tools/opencli/README.md)。 |
| Playwright | 跨浏览器自动化框架 | 微软出品，三引擎同 API；安装、速查、选型与排障见 [notes/playwright.md](../notes/playwright.md)。 |
| Chromium 桌面浏览器 | Chromium + Xvfb + noVNC | 支持 Docker Compose 或 systemd；本机已通过 `cr.20070809.xyz` 部署网页桌面，并提供仅回环 CDP，见 [desktop-browser/](desktop-browser/README.md)。 |

## 常见场景

- 自动打开网页并完成点击、输入、提交等操作。
- 抓取页面结构化信息。
- 对本地 Web 应用做端到端检查。
- 辅助完成需要登录态或多步骤交互的网页任务。

## 待补充

- browser-use 的安装方式和最小示例。

Playwright 的安装、API 速查、支持的浏览器与运行模式、选型对比（vs Selenium/Puppeteer）和常见排障见 [notes/playwright.md](../notes/playwright.md)。
