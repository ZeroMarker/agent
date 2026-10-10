# Paseo Web UI：systemd + Caddy 部署

按 [上游自托管 Web UI 文档](https://github.com/getpaseo/paseo/blob/main/public-docs/web-ui.md) 部署。Web UI 随 daemon 发布，不需要单独构建前端；浏览器从同一地址加载页面并连接 API / WebSocket。

## 当前环境

2026-10-10：本机 Paseo 从 0.7.2 升级至 npm 发布版 **0.11.2**，替代 CloudCLI 的公网入口。

| 项目 | 值 |
| --- | --- |
| 入口 | <https://cli.20070809.xyz> |
| 上游 | `127.0.0.1:6767` |
| 服务 | 系统级 `paseo.service`，开机自启，异常退出自动重启 |
| 身份与工作目录 | `ubuntu`，`/home/ubuntu/agent` |
| 配置与已有状态 | `/home/ubuntu/.paseo/config.json` 与原 `~/.paseo` 数据 |
| npm 包 | `/home/ubuntu/.local/share/pi-node/node-v22.23.2-linux-arm64/lib/node_modules/@getpaseo/cli` |
| 运行时配置 | `/etc/systemd/system/paseo.service`、`/etc/caddy/paseo.caddy` |
| DNS / TLS | 现有 Cloudflare wildcard DNS、Caddy 自动 HTTPS |

打开页面后，在 **Paseo 自己的登录界面**输入原 Caddy `admin` 账号使用的密码，无需用户名。配置复用了原 Caddy 的 bcrypt 哈希，没有记录明文。页面静态资源可公开加载，代理数据和操作由 Paseo 密码认证保护；Caddy 不再叠加 Basic Auth，以免与应用 Bearer 头冲突。

原 Paseo HOME、relay、项目、插件和终端启动配置继续使用；旧的手动 daemon 已停止，统一由 systemd 管理。CloudCLI 的 `cloudcli.service` 已停止并禁用开机启动；安装包、数据库与旧 Caddy 片段保留用于回退，但旧片段不再被导入。CloudCLI 的账号与会话不会自动迁移到 Paseo。

Caddy 还为旧 `/sw.js` 提供一次迁移用的 service worker：激活时清空该域缓存、注销旧 worker 并重新加载页面。若浏览器仍显示旧 CloudCLI，刷新页面；必要时清除该站点数据再访问。

## 安装与启动

本机 Node.js 22。首次配置先备份 `~/.paseo/config.json`；已有 daemon 先停止，再交给 systemd，避免端口争用。

```bash
npm install -g @getpaseo/cli@0.11.2
paseo --version
paseo daemon stop
```

在原 `config.json` 中合并以下字段，保留其他设置：

```json
{
  "daemon": {
    "listen": "127.0.0.1:6767",
    "hostnames": ["cli.20070809.xyz"],
    "auth": { "password": "<bcrypt-password-hash>" }
  },
  "features": { "webUi": { "enabled": true } }
}
```

密码字段必须是 bcrypt 哈希。本机从原 Caddy 配置复用；新机器使用 `paseo daemon set-password` 交互设置。配置文件权限设为 600。不要把真实密码、哈希、配对信息或用户状态提交到公开仓库。

也可使用当前版本的配置 CLI 修改非敏感字段：

```bash
paseo daemon config set features.webUi.enabled true
paseo daemon config set daemon.hostnames '["cli.20070809.xyz"]'
```

安装 [systemd 单元](deploy/paseo.service)：

```bash
sudo install -m 644 tools/paseo/deploy/paseo.service /etc/systemd/system/paseo.service
sudo systemd-analyze verify /etc/systemd/system/paseo.service
sudo systemctl daemon-reload
sudo systemctl enable --now paseo
```

服务执行 `paseo daemon run`，保持前台监督进程供 systemd 跟踪；不要用后台 `daemon start` 作为 `ExecStart`。单元含绝对 Node 与 npm 包路径，其他机器需按用户名和安装目录调整。不要另行运行 `paseo start`；维护时使用 `systemctl`。

## Caddy CLI 部署

本机主 `/etc/caddy/Caddyfile` 已将 CloudCLI 的 import 替换为：

```caddyfile
import /etc/caddy/paseo.caddy
```

[站点配置](deploy/paseo.caddy)：

以下是主要反向代理部分，仓库中的完整配置另含旧 CloudCLI service worker 清理路由。

```caddyfile
cli.20070809.xyz {
    encode zstd gzip
    reverse_proxy 127.0.0.1:6767
}
```

Caddy 处理 HTTPS、WebSocket 升级和转发头；保留 Host，由 Paseo allowlist 接受。默认信任回环代理，浏览器连接同源 `wss://cli.20070809.xyz/ws`。不需要公网开放 6767，也不需要单独部署 hosted app。

```bash
sudo install -m 644 tools/paseo/deploy/paseo.caddy /etc/caddy/paseo.caddy
sudo caddy fmt --overwrite /etc/caddy/paseo.caddy
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

## 验证与运维

```bash
systemctl is-enabled paseo
systemctl is-active paseo caddy
ss -ltn 'sport = :6767'
curl -fsS http://127.0.0.1:6767/api/health
curl -fsS https://cli.20070809.xyz/api/health
curl -sS -o /dev/null -w '%{http_code}\n' https://cli.20070809.xyz/
curl -sS -o /dev/null -w '%{http_code}\n' https://cli.20070809.xyz/api/agents
paseo provider models codex --json

sudo systemctl restart paseo
journalctl -u paseo -n 100 --no-pager
journalctl -u paseo -f
```

验证结果：公网页面 200，健康接口 `status=ok`，未经认证及错误密码的 API 请求均为 401，未允许的 Host 为 403；6767 仅回环监听。公网 WSS 可以升级，错误密码的连接被关闭；服务重启后健康检查正常。CLI 查询的原生 Codex 列表包含 `gpt-6.1-sol`，支持 `low / medium / high / xhigh / max / ultra`，无需 CloudCLI 的补模型脚本。本次没有发送模型推理请求。

本机 CLI 默认通过本地 IPC 连接；显式使用 TCP 连接时可交互读取密码到环境变量，避免密码出现在命令参数中：

```bash
read -rsp 'Paseo password: ' PASEO_PASSWORD
export PASEO_PASSWORD
paseo ls --host 127.0.0.1:6767
unset PASEO_PASSWORD
```

修改密码或需要重启的配置后使用 `sudo systemctl restart paseo`。升级前停止服务并备份 `~/.paseo`，升级 npm 包后重新启动；保留原版本的备份，以便处理状态迁移。

页面 403 时检查 `daemon.hostnames`；页面能加载但连不上时检查密码与浏览器 WebSocket 连接。`paseo daemon status` 可能在短时间内显示 status RPC 超时，应结合 `/api/health`、systemd、日志与 `paseo provider models codex` 判断进程及 provider 是否正常，不要据此重复启动 daemon。

回退到 CloudCLI：停止 Paseo，确认旧 CloudCLI 安装和数据库仍在，再启用 `cloudcli.service`；将主 Caddyfile 的 import 改回 `/etc/caddy/cloudcli.caddy`，校验并热加载。原 CloudCLI 的页面 / JWT 认证规则见 [历史部署文档](../claudecodeui/README.md)。

参考：[Web UI](https://github.com/getpaseo/paseo/blob/main/public-docs/web-ui.md)、[配置](https://github.com/getpaseo/paseo/blob/main/public-docs/configuration.md)、[安全](https://github.com/getpaseo/paseo/blob/main/public-docs/security.md)。
