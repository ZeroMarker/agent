# weibo-cli

[`weibo-cli`](https://www.npmjs.com/package/@weibo-ai/weibo-cli) 是微博开放平台的官方开源命令行工具，由微博开放平台团队发布（npm 包 `@weibo-ai/weibo-cli`，MIT 协议）。可在终端操作微博、评论、关注关系、搜索、用户等能力，支持结构化 JSON/YAML/表格输出，适合人类用户和 AI Agent。

## 适合场景

- 在终端读取首页信息流、按 ID 批量获取微博内容。
- 按昵称批量查询用户、查看关注列表、读取评论。
- 按关键词搜索微博（`search statuses/limited`）。
- 让 Codex、Claude Code、pi 等 AI Agent 通过命令行读取或操作微博数据。
- 用 `--output json` 串联 `jq` 做脚本化分析。
- 查看自己的账号信息、套餐与额度（`weibo me`）。

## 安装

需要 Node.js ≥ 18（无原生依赖，轻量）。

```bash
# 方式一：官方安装脚本（会自动执行 npm 全局安装）
curl -fsSL https://open.weibo.com/cli/install.sh | bash

# 方式二：直接 npm 全局安装
npm install -g @weibo-ai/weibo-cli
```

安装后命令为 `weibo`（同时提供 `wb`、`weibo-cli` 别名）。验证：

```bash
weibo --version
weibo doctor     # 检查登录、开发者认证、服务开通状态
```

## 认证

| 命令 | 说明 |
|---|---|
| `auth login` | 自动选择：桌面 TTY 走浏览器，非 TTY 走设备码 |
| `auth login --device` | 强制设备码登录（SSH / 远程 / headless，需在浏览器确认） |
| `auth whoami` | 验证当前登录会话 |
| `auth token` | 显示或导出当前 access token |
| `auth revoke` | 吊销当前会话 |
| `auth logout` | 清除本地存储的全部凭据 |

设备码登录流程（headless 环境）：

```bash
weibo auth login --device
# 输出形如：
#   Open this URL in any browser:
#     https://open.weibo.com/cli/api/oauth/device?user_code=XXXX-XXXX
#   Enter this code: XXXX-XXXX
# 在浏览器登录微博并确认授权后，CLI 自动完成令牌保存
```

无人值守（CI / Agent 宿主）环境配置令牌环境变量：

```bash
export WEIBO_CLI_TOKEN='<access-token>'
# 或：export WEIBO_CLI_REFRESH_TOKEN='<refresh-token>'
```

令牌默认存入操作系统密钥链（Secret Service / Keychain）；无密钥链环境使用环境变量注入。登录前执行 `auth whoami` 会提示「缺少登录令牌」。

`doctor` 是就绪检查，会逐项报告：登录账号 → 完成开发者认证 → 开通服务。

## 常用命令

命令模式：`weibo <group> <action> [flags]`，action 可能含 `/`（如 `show_batch/other`）。平台命令分组：`statuses`、`comments`、`friendships`、`search`、`users`、`attitudes`、`tags`、`short_url`、`wbindex`；内置命令：`auth`、`me`、`commands`、`config`、`version`、`upgrade`。

### 账号与检查

```bash
weibo me                    # 账号信息、套餐、用量
weibo doctor                # 就绪检查
weibo auth whoami           # 当前登录身份
weibo version
weibo check_update          # 检查更新（不弹横幅）
weibo upgrade               # 检查并安装更新
```

### 微博内容

```bash
# 首页信息流（自己 + 关注的人）
weibo statuses friends_timeline/biz --count 5

# 按 ID 批量获取微博
weibo statuses show_batch/biz --ids 1234567890

# 评论
weibo comments show/biz --id 1234567890
weibo comments to_me/biz
```

### 用户与关注

```bash
# 按昵称批量查询用户（已知昵称时推荐）
weibo users show_batch/other --screen_name 来去之间

# 查看单个用户
weibo users show/biz

# 关注列表
weibo friendships friends/biz
```

### 搜索

```bash
weibo search statuses/limited --q 关键词
```

### 浏览命令目录

```bash
weibo commands list                    # 全部平台命令
weibo commands list --group statuses   # 按分组筛选
weibo commands show users show_batch/other   # 查看单个命令详情
```

> 注意：`commands list` 等平台命令需要先登录；未登录时 `weibo --help` 只显示内置命令。

## 输出与脚本化

全局标志 `--output json|table|yaml|raw`。省略时使用各命令默认格式（如 `doctor` 默认人类可读的就绪报告）。指定 `--output` 后，失败时也会以该格式把 API/错误体写入 stderr。

```bash
weibo statuses friends_timeline/biz --output json | jq '.[] | .text'
weibo statuses friends_timeline/biz --output table
weibo me --output json
```

其他全局标志：`--token <token>`（临时指定令牌）、`-h/--help`（始终输出人类可读帮助，优先于 `--output`）。

## 注意事项

- 写操作类命令（发微博、评论等）可能产生不可逆影响，Agent 调用前确认参数与意图。
- 不要把 token 写入仓库或日志；泄露后使用 `auth revoke` 吊销会话。
- 设备码有有效期，超时未确认会报 `Device authorization timed out`，需要重新执行 `auth login --device`。
- 微博开放平台能力需要完成开发者认证并开通服务（见 `weibo doctor`），否则对应命令会失败。

## 参考链接

- [npm 包主页](https://www.npmjs.com/package/@weibo-ai/weibo-cli)
- [官方安装脚本](https://open.weibo.com/cli/install.sh)
- [微博开放平台](https://open.weibo.com/)
