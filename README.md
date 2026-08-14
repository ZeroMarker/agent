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
- [AIGC 分发渠道](notes/aigc.md)：AI 内容在 App、网站、视频、音乐、模型、图片、小说、有声书等渠道的分发平台整理。
- [Codespace](notes/codespace.md)：GitHub Codespace 的查看、启动、连接、pi agent 授权与项目操作笔记。
- [Tavily](notes/tavily.md)：AI Agent 的搜索/提取/爬取/研究 API 使用笔记。
- [Jina](notes/jina.md)：Jina Reader/Search —— URL 转 Markdown 与联网搜索 API 笔记（含 Cloudflare 站绕过实战）。
- [Caddy](notes/caddy.md)：自动 HTTPS、反向代理、静态站点、Docker 与常见排障笔记。
- [Computer](notes/computer.md)：Cloudflare Computer 架构与使用笔记。

## CLI 工具（cli-tools/）

- [lark-cli](cli-tools/lark-cli/index.md)：飞书官方命令行工具的安装、认证、常用命令和 Agent 使用说明。
- [twitter-cli](cli-tools/twitter-cli/index.md)：Twitter/X 终端 CLI 的安装、认证、常用命令和 Agent 使用说明。
- [zhihu-cli](cli-tools/zhihu-cli/index.md)：知乎开放平台官方 CLI 的安装、Access Secret 认证、搜索/热榜/直答/本人数据命令和 Agent 使用说明。
- [weibo-cli](cli-tools/weibo-cli/index.md)：微博开放平台官方 CLI（@weibo-ai/weibo-cli）的安装、设备码认证、微博/评论/搜索/用户命令和 Agent 使用说明。

## 工具使用指南（tools/）

- [Codex CLI](tools/codex/)：OpenAI 轻量级编码代理，终端本地运行。
- [MiMo Code](tools/mimocode/)：面向开发者的 AI 编码代理文档。
- [Nanobot](tools/nanobot/)：超轻量级个人 AI 助手，支持 QQ/Telegram/Discord/WeChat/Slack 多频道。
- [ZeroClaw](tools/zeroclaw/)：基于 Rust 的快速 AI 助手，多频道、多模型、自主运行。
- [WeClaw](tools/weclaw/)：使用说明文档。
- [Agent Mail](tools/agent-mail/)：腾讯 Agent Mail —— 专为 AI Agent 设计的邮箱服务 CLI。

## 示例项目（projects/）

- [Agent Swarm](projects/swarm/)：LangGraph + DeepSeek Supervisor 多 Agent 最小实践（Research / Coding / Review，确定性调度 + `max_steps` 防循环）。

## 分类主题索引

- [浏览器自动化](browser/index.md)：浏览器控制、网页任务执行和测试相关工具。
- [手机 Agent](phone/index.md)：移动端自动化与手机操作 Agent 项目。
- [软件工具](software/blender.md)：具体软件的 Agent 化、自动化或创作流程笔记。
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
