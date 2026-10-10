# Agent 工具索引

这个仓库用于整理和沉淀 AI Agent 相关工具、软件、工作流与实践笔记。内容以“快速查找、后续补充”为目标，先保留轻量索引，再逐步补齐安装方式、使用场景、优缺点和案例。

## 目录结构

| 目录 | 内容 |
|---|---|
| [`notes/`](notes/) | 单篇实践笔记（工具列表、API 笔记、环境搭建） |
| [`cli-tools/`](cli-tools/) | 各类 CLI 工具的安装、认证、常用命令与 Agent 使用说明 |
| [`tools/`](tools/) | 工具/编码代理的使用指南文档 |
| [`projects/`](projects/) | 可运行的示例项目（源码与实验） |
| [`skills/`](skills/) | Agent Skills 集合 |
| `browser/` `phone/` `software/` `workflow/` | 分类主题索引 |

## 实践笔记（notes/）

- [Agent 工具](notes/agent.md)：代码、办公、协作等 Agent 工具列表。
- [Agent 语音输入落地方案](notes/agent-voice-input.md)：WorkBuddy × HOLLYLAND、Qoder × DJI Mic 案例，以及通用音频/控制架构、实施路线与验收指标。
- [AIGC 分发渠道](notes/aigc.md)：AI 内容在 App、网站、视频、音乐、模型、图片、小说、有声书等渠道的分发平台整理。
- [Codespace](notes/codespace.md)：GitHub Codespace 的查看、启动、连接、pi agent 授权与项目操作笔记。
- [Tavily](notes/tavily.md)：AI Agent 的搜索/提取/爬取/研究 API 使用笔记。
- [Jina](notes/jina.md)：Jina Reader/Search —— URL 转 Markdown 与联网搜索 API 笔记（含 Cloudflare 站绕过实战）。
- [Playwright](notes/playwright.md)：跨浏览器自动化框架 —— 安装、核心概念、API 速查、测试运行器与 Agent 集成笔记（含 vs Selenium/Puppeteer 选型）。
- [Pinry](notes/pinry.md)：自托管瀑布流图片收藏板的 Docker 启动、配置、使用入口与私密媒体访问限制。
- [Caddy](notes/caddy.md)：自动 HTTPS、反向代理、静态站点、Docker 与常见排障笔记；含本机 `20070809.xyz` 多子域部署及 `cr` Chromium/noVNC 入口。
- [Brave Search](notes/brave-search.md)：Brave 独立索引搜索 API 笔记——Web/新闻/图片/视频/地点搜索、面向 Agent 的 LLM Context 与 OpenAI 兼容 Answers 接口。
- [Computer](notes/computer.md)：Cloudflare Computer 架构与使用笔记。
- [DeepSeek Harness 文档导航](notes/dsh-文档导航.md)：deepseek-ai/deepseek-harness 仓库 docs/ 的结构化导航与阅读路径整理。
- [Codex 插件与技能清理教训](notes/codex-教训.md)：记录技能误触发、插件层级识别、CLI 卸载和清理验证方法。

## CLI 工具（cli-tools/）

- [bilibili-cli](cli-tools/bilibili-cli/index.md)：B 站终端 CLI 的安装、浏览/搜索/互动命令和 Agent 使用说明。
- [cloudflare-cli](cli-tools/cloudflare-cli/index.md)：Cloudflare 统一 CLI `cf` 的安装、认证、部署、Pages Drop/Direct Upload、命令总览和全局参数。
- [dsh 模型目录补齐](cli-tools/dsh/README.md)：dsh 内置 OpenCode Go 模型目录落后于实时接口时，用 `sync-go-models.py` 补齐并验证。
- [Harlequin / hsql](cli-tools/harlequin/index.md)：终端 SQL IDE 与面向 Agent 的无界面 SQL CLI；安装、数据库适配器、配置、查询导出与排障。
- [lark-cli](cli-tools/lark-cli/index.md)：飞书官方命令行工具的安装、认证、常用命令和 Agent 使用说明。
- [MiniMax CLI / mmx](cli-tools/minimax-cli/index.md)：MiniMax 官方多模态 CLI；安装、双区域认证、文本/图像/视频/语音生成、转写、搜索和 Agent 配置。
- [OpenCLI](cli-tools/opencli/index.md)：把任意网站变成 CLI 并让 Agent 用已登录 Chrome 操作网页的统一工具——内置 100+ 站点 adapter、browser 原语、CLI Hub 与插件。
- [pikpaktui](cli-tools/pikpaktui/index.md)：PikPak 云盘的纯 Rust 终端客户端（TUI + 28 个子命令），支持非交互登录与 `--json`，对 Agent 友好。
- [rdt-cli](cli-tools/rdt-cli/index.md)：Reddit 终端 CLI 的安装、浏览器 Cookie 认证、浏览/搜索/互动命令和 Agent 使用说明。
- [weibo-cli](cli-tools/weibo-cli/index.md)：微博开放平台官方 CLI（@weibo-ai/weibo-cli）的安装、设备码认证、微博/评论/搜索/用户命令和 Agent 使用说明。
- [xiaohongshu-cli](cli-tools/xiaohongshu-cli/index.md)：小红书终端 CLI 的安装、三种认证方式（浏览器 Cookie/扫码）、搜索/阅读/互动/发布命令和 Agent 使用说明。
- [zhihu-cli](cli-tools/zhihu-cli/index.md)：知乎开放平台官方 CLI 的安装、Access Secret 认证、搜索/热榜/直答/本人数据命令和 Agent 使用说明。

## 工具使用指南（tools/）

- [AionUi](tools/aionui/README.md)：独立 WebUI，使用 systemd + Caddy 部署于 `aion.20070809.xyz`，含登录、构建与认证行为说明。
- [CLI-Anything](tools/cli-anything/)：HKUDS 出品的「让所有软件 Agent 原生」框架——为任意有源码的软件自动生成 CLI harness，配套 CLI-Hub 注册表。
- [Codex CLI](tools/codex/)：OpenAI 轻量级编码代理，终端本地运行。
- [Paseo](tools/paseo/README.md)：远程管理编码代理；[本机 Web UI](tools/paseo/web-ui.md) 使用 systemd + Caddy 部署于 `cli.20070809.xyz`，含安装配对、模型列表与 Codex YOLO / Full Access 排障。
- [MiMo Code](tools/mimocode/)：面向开发者的 AI 编码代理文档。
- [Nanobot](tools/nanobot/)：超轻量级个人 AI 助手，支持 QQ/Telegram/Discord/WeChat/Slack 多频道；本机已部署 v0.3.0（QQ 机器人已接入，ChatGPT 账号 OAuth Codex，systemd 网关 `:18791`）。
- [ZeroClaw](tools/zeroclaw/)：基于 Rust 的快速 AI 助手，多频道、多模型、自主运行。
- [WeClaw](tools/weclaw/)：使用说明文档。
- [Agent Mail](tools/agent-mail/)：腾讯 Agent Mail —— 专为 AI Agent 设计的邮箱服务 CLI。

## 示例项目（projects/）

- [Agent Swarm](projects/swarm/)：LangGraph + DeepSeek Supervisor 多 Agent 最小实践（Research / Coding / Review，确定性调度 + `max_steps` 防循环）。

## Agent Skills（skills/）

- [disk-cleanup](skills/disk-cleanup/SKILL.md)：清理系统日志、临时文件、包管理器缓存和旧 snap 版本以释放磁盘空间。
- [gh-codespace](skills/gh-codespace/SKILL.md)：GitHub Codespace 的查看/启动/连接、SSH 直连、命令执行与文件传输、pi agent 配置和 gh 登录修复。
- [mdbook](skills/mdbook/SKILL.md)：mdbook 项目初始化、`list.yaml` 条目与标签管理、GitHub Actions 部署。
- [open-websearch](skills/open-websearch/SKILL.md)：open-websearch 的安装配置与实时检索，优先本地 CLI/daemon，兼容 MCP 工具。
- [web-search](skills/web-search/SKILL.md)：通过 mcp_web_search 绕过 Google 反爬获取搜索结果。
- [x-id-research](skills/x-id-research/SKILL.md)：根据 X (Twitter) ID 抓取资料、联网补充并整理成结构化创作者档案。

## 分类主题索引

- [浏览器自动化](browser/index.md)：浏览器控制、网页任务执行和测试相关工具。
- [Chromium 桌面浏览器](browser/desktop-browser/README.md)：Xvfb + Fluxbox + Chromium + noVNC 的远程桌面浏览器，开放 CDP 端口供 Playwright 等 Agent 接入；支持 Docker Compose 与 systemd 部署。
- [手机 Agent](phone/index.md)：移动端自动化与手机操作 Agent 项目。
- [软件工具](software/blender.md)：具体软件的 Agent 化、自动化或创作流程笔记。
- [ArtCraft](software/artcraft.md)：AI 图像与视频创作工作台；2D/3D 构图、安装入口、生成流程、模型接入、费用与许可证说明。
- [storytold / ArtCraft 项目导航](software/storytold.md)：41 个公开仓库的分类索引；Craft 创作与办公应用、服务端、Agent/MCP 入口、实验项目与第三方 fork。
- [FilmCraft 网页版](software/filmcraft.md)：官方 WebAssembly 发布包的 Caddy 部署、访问入口、验证结果与更新方式。
- [rclone](rclone/README.md)：云存储命令行管理、PikPak 挂载（systemd 服务）与常用操作。
- [工作流编排](workflow/index.md)：低代码、自动化编排和 Agent workflow 平台。

## 整理规范

每个工具条目建议包含：

- 名称与链接
- 主要用途
- 适合场景
- 安装或启动方式
- 备注、限制或待验证事项

## 后续计划

- 为每个分类补充代表项目链接。
- 增加实际使用案例和截图。
- 按“本地可用、云端服务、开源项目、商业产品”继续细分。
