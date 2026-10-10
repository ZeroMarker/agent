# CloudCLI / Claude Code UI

[CloudCLI](https://github.com/siteboon/claudecodeui) 是 Claude Code、Codex、Cursor CLI 与 OpenCode 的桌面/手机 Web 界面，提供项目与会话管理、聊天、文件编辑、Git 操作、终端和插件。适合从手机继续服务器上的编码会话。上游采用 AGPL-3.0-or-later；官方说明见 [README](https://github.com/siteboon/claudecodeui#readme)。

## 本机部署

2026-10-10 部署，使用 npm 发布包 **1.37.4**，不需要本机编译前端。

| 项目 | 配置 |
| --- | --- |
| HTTPS 入口 | <https://cli.20070809.xyz> |
| 后端 | `127.0.0.1:3001`，仅回环监听 |
| 应用服务 | 系统级 `cloudcli.service`，开机自启、异常退出自动重启 |
| 运行身份 | `ubuntu`，`HOME=/home/ubuntu` |
| 安装目录 | `/home/ubuntu/.local/share/cloudcli` |
| 账号数据库 | `/home/ubuntu/.local/state/cloudcli/auth.db` |
| systemd 配置 | `/etc/systemd/system/cloudcli.service` |
| Caddy 配置 | `/etc/caddy/cloudcli.caddy`，主 Caddyfile 导入 |
| DNS | 复用现有 Cloudflare 代理的 `*.20070809.xyz` A 记录 |
| Node.js | `/usr/local/bin/node`，v22.23.2，Linux ARM64 |

访问首页时，先使用已有 Caddy `admin` 账号和密码。首次进入后创建 CloudCLI 自身的账号；这是单用户系统，已有账号后禁止再次注册。部署没有代建账号，数据库检查返回 `needsSetup=true`。CloudCLI 的账号、JWT 密钥、CLI 凭据与会话数据不提交到仓库。

服务使用现有用户的 HOME 和 PATH，可以读取该用户的项目与 CLI 登录状态；它不是隔离沙箱。已安装的 Claude/Codex CLI 可被找到，但本次没有发送模型请求，也没有验证每个提供方的登录与聊天。登录后先选择提供方、项目和会话，确认凭据可用，再开始工作。

## 安装与配置

要求 Node.js 22+、npm、systemd 和已有 Caddy 服务。本机采用独立 npm prefix，固定版本：

```bash
mkdir -p ~/.local/share/cloudcli ~/.local/state/cloudcli
npm install --prefix ~/.local/share/cloudcli --save-exact @cloudcli-ai/cloudcli@1.37.4
~/.local/share/cloudcli/node_modules/.bin/cloudcli version
~/.local/share/cloudcli/node_modules/.bin/cloudcli help

sudo install -m 644 tools/claudecodeui/deploy/cloudcli.service /etc/systemd/system/cloudcli.service
sudo systemd-analyze verify /etc/systemd/system/cloudcli.service
sudo systemctl daemon-reload
sudo systemctl enable --now cloudcli
```

[服务单元](deploy/cloudcli.service) 是本机落盘副本；其他服务器需修改用户名、HOME、工作目录、Node/CLI 路径和数据库路径。`HOST=127.0.0.1`、`SERVER_PORT=3001` 和 `DATABASE_PATH` 由 systemd 注入，无需额外 `.env`。启动日志中的「No .env file found」不影响这些变量。`UMask=0077` 限制新建数据文件的权限。

常用 CLI 命令：

```bash
~/.local/share/cloudcli/node_modules/.bin/cloudcli start --port 3001
~/.local/share/cloudcli/node_modules/.bin/cloudcli status
~/.local/share/cloudcli/node_modules/.bin/cloudcli version
```

正式部署由 systemd 启动，不要再手动启动第二个进程抢占端口。`status` 是 CLI 配置位置说明；本机运行参数以 `systemctl cat cloudcli` 为准。

## Caddy CLI 配置与认证

[Caddy 模板](deploy/cloudcli.caddy.example) 中的 `<PASSWORD_HASH>` 需替换成已有站点的密码哈希，或通过 `caddy hash-password` 交互生成；真实哈希不放进仓库。复制到 `/etc/caddy/cloudcli.caddy` 后，在 `/etc/caddy/Caddyfile` 加一行：

```caddyfile
import /etc/caddy/cloudcli.caddy
```

配置前先备份主文件，随后用 Caddy CLI 校验、热加载：

```bash
sudo cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak-$(date +%Y%m%d%H%M%S)
sudo caddy fmt --overwrite /etc/caddy/cloudcli.caddy
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

本机复用现有 Caddy 密码，并成功签发 Let's Encrypt 证书。Caddy 自动处理 HTTP→HTTPS 和 WebSocket 升级，无需手写 Upgrade 头。相关命令见 [Caddy 官方 CLI 文档](https://caddyserver.com/docs/command-line)。

**不能对所有请求直接叠加 Basic Auth**：CloudCLI 的 API 使用 `Authorization: Bearer …`，会与 Caddy 的 Basic Auth 共用同一个头。模板采用互斥 `handle`：

- 首页、静态资源、`/health` 和首次注册 `/api/auth/register` 必须通过 Caddy Basic Auth。
- `/api/*`（注册除外）、`/ws`、`/shell`、`/desktop-notifications` 和 `/plugin-ws/*` 交给 CloudCLI 自身认证；登录/认证状态接口保留应用原本的公开行为。
- 转发时移除浏览器的 Basic Authorization，保留 Bearer token，避免干扰应用的 JWT / SSE 查询 token 校验。

因此 Caddy 登录保护页面入口和注册，CloudCLI 的 JWT 保护项目、文件、终端等操作。不要为了省去登录而启用上游的平台模式绕过认证。

## 验证与运维

```bash
systemctl is-enabled cloudcli
systemctl is-active cloudcli caddy
ss -ltn 'sport = :3001'
curl -fsS http://127.0.0.1:3001/health
curl -fsS https://cli.20070809.xyz/api/auth/status
curl -sS -o /dev/null -w '%{http_code}\n' https://cli.20070809.xyz/
curl -sS -X POST -o /dev/null -w '%{http_code}\n' https://cli.20070809.xyz/api/auth/register
curl -sS -H 'Authorization: Bearer invalid' https://cli.20070809.xyz/api/projects

sudo systemctl restart cloudcli
journalctl -u cloudcli -n 100 --no-pager
journalctl -u cloudcli -f
```

本次验证：服务 enabled/active；重启后健康接口返回 `status=ok`、版本 `1.37.4`；端口仅监听 `127.0.0.1`；后端首页 200；公网首页与注册均返回 401；无效 Bearer 请求得到 CloudCLI 的 `AUTH_TOKEN_INVALID`，确认请求到达应用的 JWT 校验。Caddy 配置校验通过，HTTPS 正常。首次账号创建、登录后的浏览器聊天与终端仍需用户进入页面后使用。

升级时先备份数据库（含 SQLite 的 WAL/SHM；停止服务后备份最简单），再安装选定版本并重启；仅升级磁盘上的包不会替换正在运行的进程：

```bash
sudo systemctl stop cloudcli
cp -a ~/.local/state/cloudcli ~/.local/state/cloudcli.bak-$(date +%Y%m%d%H%M%S)
npm install --prefix ~/.local/share/cloudcli --save-exact @cloudcli-ai/cloudcli@<目标版本>
sudo systemctl start cloudcli
curl -fsS http://127.0.0.1:3001/health
```

包升级失败时重新安装 `1.37.4`；如果新版本迁移了数据库，应结合备份恢复，而不只降级 npm 包。停用时执行 `sudo systemctl disable --now cloudcli`，删除主 Caddyfile 的对应 import 后校验并热加载。保留安装目录和数据库，方便恢复。
