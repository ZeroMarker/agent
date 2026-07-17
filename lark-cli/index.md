# lark-cli

[`lark-cli`](https://github.com/larksuite/cli) 是飞书官方开源命令行工具，由 LarkSuite 团队维护。它面向人类用户和 AI Agent，可在终端中操作消息、文档、多维表格、电子表格、日历、邮箱、任务、会议等飞书能力。

## 适合场景

- 在脚本或 CI 中自动化飞书操作。
- 让 Codex、Claude Code、Cursor 等 AI Agent 通过 Skills 操作飞书。
- 使用 JSON、NDJSON 或 CSV 输出串联 `jq` 等命令行工具。
- 在编写开放平台集成前，通过 Schema 自省和通用 API 调用快速验证接口。

## 安装

需要 Node.js，以及可用的 `npm` 和 `npx`。推荐使用官方安装器，它会安装 CLI 及配套 Skills：

```bash
npx @larksuite/cli@latest install
```

安装后检查命令是否可用：

```bash
lark-cli help
lark-cli doctor
```

也可以从源码安装；此方式还需要 Go 1.23+ 和 Python 3：

```bash
git clone https://github.com/larksuite/cli.git
cd cli
make install
npx skills add larksuite/cli -y -g
```

## 配置和登录

首次使用需要配置飞书应用并完成 OAuth 授权：

```bash
# 交互式配置应用凭证
lark-cli config init

# 使用推荐的常用权限登录
lark-cli auth login --recommend

# 查看登录身份和已授权权限
lark-cli auth status
```

按业务域或具体 scope 控制权限：

```bash
lark-cli auth login --domain calendar,task
lark-cli auth login --scope "calendar:calendar:read"
```

命令可通过 `--as user` 或 `--as bot` 选择用户或机器人身份。应遵循最小权限原则，不要把 App Secret、访问令牌或设备码写入仓库。

## 常用命令

```bash
# 查看当天议程
lark-cli calendar +agenda

# 查看自己的任务
lark-cli task +get-my-tasks

# 向群聊发送消息
lark-cli im +messages-send \
  --chat-id "oc_xxx" \
  --text "Hello from lark-cli"

# 查看命令总览和业务域帮助
lark-cli help
lark-cli calendar --help
```

可能产生修改或发送行为的快捷命令，先用 `--dry-run` 预览：

```bash
lark-cli im +messages-send \
  --chat-id "oc_xxx" \
  --text "hello" \
  --dry-run
```

## 三种调用方式

1. **快捷命令**：以 `+` 开头，提供智能默认值，适合日常使用和 Agent 调用，例如 `calendar +agenda`。
2. **API 命令**：与精选的飞书开放平台端点对应，例如 `calendar calendars list`。
3. **通用 API 调用**：直接请求开放平台端点，用于尚未封装的能力。

```bash
lark-cli calendar calendars list
lark-cli api GET /open-apis/calendar/v4/calendars
```

可用 Schema 自省查询参数、请求体、响应结构、身份类型和所需 scopes：

```bash
lark-cli schema
lark-cli schema calendar.events.instance_view
lark-cli schema im.messages.delete
```

## 输出和脚本化

CLI 默认输出 JSON，也支持可读文本、表格、NDJSON 和 CSV：

```bash
lark-cli calendar +agenda --format pretty
lark-cli calendar +agenda --format table
lark-cli calendar +agenda --format json
```

JSON 模式下，应根据进程退出码或顶层 `ok` 字段判断成功，不要依赖开放平台原始响应中的 `code == 0`：

```json
{ "ok": true, "identity": "user", "data": {}, "meta": {} }
```

列表接口可使用 `--page-all` 自动翻页，并通过 `--page-limit` 限制最大页数。

## 安全注意事项

AI Agent 获得授权后，会以相应的用户或机器人身份执行操作。消息发送、文档修改、审批等操作可能造成不可逆影响：

- 仅授予任务所需的最小权限，并定期检查 `lark-cli auth status`。
- 对写入、发送、删除类命令优先使用 `--dry-run`。
- 不要让不可信内容直接决定命令参数，警惕提示词注入和数据泄露。
- 不再使用某个身份时执行 `lark-cli auth logout` 清理凭证。

## 参考链接

- [官方 GitHub 仓库](https://github.com/larksuite/cli)
- [中文 README](https://github.com/larksuite/cli/blob/main/README.zh.md)
- [飞书开放平台介绍](https://open.feishu.cn/document/mcp_open_tools/feishu-cli-let-ai-actually-do-your-work-in-feishu)
- [npm 包](https://www.npmjs.com/package/@larksuite/cli)
