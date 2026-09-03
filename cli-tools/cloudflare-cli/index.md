# Cloudflare CLI（`cf`）

[`cf`](https://www.npmjs.com/package/cf) 是 Cloudflare 的统一命令行工具，覆盖 Worker 部署、账户与用户管理、DNS、R2、Zones、AI、Cloudforce One 等能力。当前记录基于 `cf 0.8.0`；该版本仍是 technical preview。

## 安装与要求

需要 Node.js 22 或更高版本：

```bash
npm install -g cf
cf --version
```

查看帮助：

```bash
cf --help
cf <command> --help
```

## 认证与 profile

最简单的方式是启动 Cloudflare 登录流程：

```bash
cf auth login
cf auth whoami
```

需要多个 Cloudflare 身份时，可创建命名 profile，并按目录绑定：

```bash
cf auth create work
cf auth activate work
cf auth list
cf auth deactivate
cf auth delete work
```

认证凭据的解析顺序为：

1. `CLOUDFLARE_API_TOKEN` 环境变量。
2. `--profile` 指定的 OAuth profile。
3. 当前目录或最近父目录绑定的 profile。
4. 默认 profile（必要时自动刷新）。

```bash
cf --profile work zones list
```

`cf auth logout` 和 `cf auth login` 管理默认 profile；命名 profile 使用 `create`、`delete`、`activate`、`deactivate` 和 `list` 管理。令牌和 OAuth profile 不要提交到仓库或写入脚本日志。

## 常用工作流

```bash
# 查看当前身份
cf auth whoami

# 构建、启动本地开发服务、部署
cf build
cf dev
cf deploy

# 部署前只构建并检查，不上传 Worker
cf deploy --dry-run

# 指定部署模式、版本标签和说明
cf deploy --mode production --tag release-1 --message "release"

# 生成 shell 补全（以 Bash 为例）
cf complete bash >> ~/.bashrc
```

部署已有 Build Output API 文件时使用 `cf deploy --prebuilt`。`--secrets-file` 可从 JSON 或 `.env` 文件上传 secrets；这类文件应放在仓库外或加入 `.gitignore`。

## Cloudflare Pages Drop / Direct Upload

Cloudflare Pages 的“Drop”通常指控制台里的 Drag and drop；命令行对应的是 Direct Upload。两者都适合已经生成好的静态文件目录。单个文件最大 25 MiB；Wrangler 最多上传 20,000 个文件，控制台拖放最多 1,000 个文件。

### 网页拖放

1. 打开 Cloudflare Dashboard → Workers & Pages。
2. 选择 **Create application → Get started → Drag and drop your files**。
3. 填写项目名，拖入构建输出目录或 zip 文件。
4. 点击 **Deploy site**；已有项目则选择 **Create a new deployment**。

项目默认地址为 `<project-name>.pages.dev`；如果名称已被占用，Cloudflare 会附加随机后缀。

### Wrangler 命令行上传

`cf` 负责账户、认证和 Pages 项目管理；本机 `cf 0.8.0` 的 Pages deployment API 命令只提交部署元数据，不能把本地目录自动打包成资产清单。因此上传本地目录时使用 Cloudflare 官方 Wrangler Pages 上传器：

```bash
# 推荐使用 Cloudflare API Token；不要把 token 写进仓库
export CLOUDFLARE_API_TOKEN='你的 API Token'
export CLOUDFLARE_ACCOUNT_ID='你的 Account ID'

# 创建 Direct Upload 项目（只需一次）
cf pages projects create --body '{"name":"my-site","production_branch":"main"}'

# 上传静态目录并发布生产版本
npx wrangler pages deploy ./dist --project-name my-site --branch main

# 查看项目和部署
cf pages projects get my-site
cf pages projects deployments list my-site
```

如果项目已经存在，只执行上传和查看命令即可。纯静态项目可直接把仓库根目录作为目录上传，但应先排除 `.git`、依赖目录、日志、密钥和不需要公开的文档；更稳妥的做法是准备一个专门的 `dist/` 输出目录。

### 用 `cf` 完成认证

```bash
cf auth login
cf auth whoami
cf pages projects list
```

`cf auth whoami` 能确认当前账号与 Pages 权限。Wrangler 在非交互环境中通常要求 `CLOUDFLARE_API_TOKEN`；`cf` 保存的 OAuth profile 不应复制到脚本或提交到仓库。需要持续部署时，建议在 CI 的 secret 中配置 API Token 和 Account ID。

### 验证与排障

```bash
curl -I https://my-site.pages.dev/
cf pages projects get my-site
cf pages projects deployments list my-site
```

- `404`：先检查部署返回的唯一预览地址，再检查项目的 canonical deployment；部署完成后 `<project-name>.pages.dev` 才会指向最新生产版本。
- `manifest field was expected`：说明直接调用了 Pages deployment API，但没有先完成 Direct Upload 资产上传；改用 `npx wrangler pages deploy` 或控制台拖放。
- Wrangler 提示缺少 `CLOUDFLARE_API_TOKEN`：设置 API Token，或在可交互终端执行 `npx wrangler login`。
- `functions/` 不是普通静态资源；需要 Pages Functions 时使用 Wrangler，并从包含 `functions/` 的项目目录部署。控制台拖放不负责编译该目录。

参考：[Pages Direct Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/)、[Pages API：Upload asset](https://developers.cloudflare.com/api/go/resources/pages/subresources/assets/methods/upload/)、[Pages API：Create deployment](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/)。

## 命令总览（`cf --help`）

| 命令 | 用途 |
|---|---|
| `auth` | 登录、退出登录和管理认证 profile |
| `build` | 构建 Cloudflare 项目 |
| `complete [shell]` | 生成和处理 shell 补全 |
| `deploy` | 部署项目到 Cloudflare |
| `dev [implArgs..]` | 运行项目的 Cloudflare 本地开发服务器 |
| `triggers` | 管理 Routes、Workflows、Cron 等触发器 |
| `versions` | 管理 Worker Versions |
| `schema [command..]` | 查看命令对应的 API schema 详情 |
| `agent-context [product]` | 输出 Agent 上下文和工具定义；`--list` 列出产品 |
| `account` / `accounts` | 账户及账户设置、成员、角色、订阅和 API token |
| `ai-audit` / `ai-search` | AI Audit、AI Search |
| `billing` | 订阅及附加服务的账单 profile 和用量 |
| `browser-extension` | Browser Extension |
| `cloudforce-one` | 威胁情报：调查、指标扫描和事件跟踪 |
| `dns` | DNS、DNSSEC、分析和 zone transfer |
| `email-sending` | 发送邮件和管理发送子域 |
| `hyperdrive` | 数据库查询缓存与连接池 |
| `images` | Cloudflare Images |
| `moq` | MOQ |
| `organization` / `organizations` | 组织及多用户组织设置 |
| `pay-per-crawl` | Pay Per Crawl |
| `pipelines` | 实时摄取、转换并路由事件流 |
| `r2` | R2 bucket、生命周期、事件通知和数据迁移 |
| `rate-limit-analytics` | Rate Limit Analytics |
| `registrar` / `registrar-sandbox` | 域名注册、转移及 Registrar 沙盒 |
| `resource-sharing` | Resource Sharing |
| `security-center` | 安全态势、配置错误和漏洞 |
| `share` | Share |
| `tenant` | Tenant |
| `user` | 用户 profile、邀请、组织、账单和个人 API token |
| `workflows` | 可重试、持久化的多步骤 Workers Workflow |
| `zone` / `zones` | Zone 设置；Zones 支持列出、创建和配置域名 |

## 全局参数

这些参数可与大多数命令一起使用：

| 参数 | 说明 |
|---|---|
| `-q, --quiet` | 抑制非必要输出 |
| `-z, --zone <id-or-domain>` | 指定 Zone ID 或域名，覆盖 `CLOUDFLARE_ZONE_ID` |
| `--profile <name>` | 使用指定认证 profile |
| `--local` | 将请求路由到本地 `wrangler dev` / `cf dev` Miniflare 会话 |
| `--local-endpoint <url>` | 本地 Miniflare endpoint；配合 `--local` 使用 |
| `-h, --help` | 显示帮助 |
| `-v, --version` | 显示版本 |

## 输出和 Agent 使用

命令结果默认以 JSON 写到 stdout；spinner、成功标记等状态信息写到 stderr。因此适合通过 `jq` 过滤或串联脚本：

```bash
cf zones list | jq
cf auth whoami --quiet
```

修改类操作应先查看对应命令的帮助，并优先使用命令提供的 dry-run 能力。想让 Agent 获取某个产品的命令定义时，可使用：

```bash
cf agent-context --list
cf agent-context dns
cf schema dns
```

## 参考链接

- [npm 包](https://www.npmjs.com/package/cf)
- [Cloudflare Developers](https://developers.cloudflare.com/)
- [Cloudflare CLI 公告](https://blog.cloudflare.com/cf-cli-local-explorer/)

> 帮助快照：`cf 0.8.0`，2026-09-03。CLI 处于预览阶段，命令和参数可能变化；以本机 `cf --help` 及子命令帮助为准。
