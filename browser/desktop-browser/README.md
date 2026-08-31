# Chromium 桌面浏览器

这是一个可直接运行的浏览器服务：Xvfb 提供虚拟显示，Fluxbox 管理窗口，
Chromium 负责浏览网页，x11vnc + noVNC 将桌面提供到浏览器中。另有 CDP 端口供
Playwright、Puppeteer 或其他 Agent 接入。支持 Docker Compose 和原生 systemd 两种部署。

## 当前实例

本机使用 Ubuntu 24.04 ARM64 + systemd 运行，实际拓扑如下：

```text
https://cr.20070809.xyz
  -> Caddy HTTPS + Basic Auth
  -> 127.0.0.1:6080 (noVNC/WebSocket)
  -> 127.0.0.1:5900 (x11vnc，无 VNC 密码)
  -> Xvfb :99 + Fluxbox + Chromium

Agent -> 127.0.0.1:9222 (CDP，仅本机)
```

| 项目 | 当前值 |
|---|---|
| systemd 服务 | `browser-desktop.service`，已启用并运行 |
| 公网入口 | `https://cr.20070809.xyz` |
| 公网认证 | Caddy Basic Auth |
| VNC 认证 | 已关闭（`VNC_AUTH=false`） |
| noVNC | `127.0.0.1:6080` |
| CDP | `127.0.0.1:9222` |
| 浏览器程序 | `/opt/browser-desktop/bin/chromium` |
| 用户数据 | `/home/browser-desktop/.config/chromium` |
| 进程日志 | `/var/log/browser-desktop/` |

公网只开放 Caddy 的 80/443；5900、6080 和 9222 均不得直接暴露。

## Docker Compose

需要 Docker Engine 和 Docker Compose v2。

```bash
cd browser/desktop-browser
cp .env.example .env
# 编辑 .env，至少设置一个不超过 8 个字符的 VNC_PASSWORD
docker compose up -d --build
```

打开 <http://127.0.0.1:6080/vnc.html?autoconnect=1&resize=scale>，输入 `.env` 中的
`VNC_PASSWORD` 即可看到 Chromium。受 VNC 协议限制，密码最多 8 个字符；默认密码
`browser` 仅用于本机试用。

查看运行状态和日志：

```bash
docker compose ps
docker compose logs -f browser
```

停止服务：

```bash
docker compose down
```

浏览器配置保存在 `chromium-data` 命名卷中，普通的 `docker compose down` 不会删除
登录态。确实需要清空配置时再执行 `docker compose down --volumes`。

## systemd（Debian/Ubuntu）

原生方案使用独立的 `browser-desktop` 系统用户，浏览器数据保存在
`/home/browser-desktop/.config/chromium`，noVNC 和 CDP 默认仅监听本机。

```bash
cd browser/desktop-browser
sudo ./install-systemd.sh
```

安装脚本会安装 Chromium、Xvfb、Fluxbox、x11vnc、noVNC 等依赖，默认生成一个随机的
8 字符 VNC 密码并启动服务。密码及其他配置位于 `/etc/default/browser-desktop`；本机实例
因已有 Caddy Basic Auth，另行设置了 `VNC_AUTH=false`。
Ubuntu 的 Chromium Snap 无法在普通 system service cgroup 中启动，因此安装脚本会使用
Playwright 提供的 Chromium 构建；Debian 使用发行版原生 `chromium` 软件包。浏览器以
独立低权限用户运行，并默认关闭 Chromium sandbox，以兼容 Ubuntu 的 user namespace 限制。

### Ubuntu noVNC 与 Node.js 18

Ubuntu 24.04 的 `novnc` 软件包硬依赖发行版的 `nodejs`，当前会安装 Node.js 18。这里的
Node.js 是 Ubuntu 对 noVNC 的打包依赖；`browser-desktop` 的运行脚本和 Chromium 本身
并不直接依赖 Node.js。

不要直接执行 `apt-get remove nodejs` 后再执行 `apt-get autoremove`：APT 会连带卸载
`novnc`、`python3-novnc` 及部分 Python 依赖。已经运行的 websockify 进程可能暂时存活，
但 noVNC 页面会在进程退出、服务重启或文件清理后失效，Caddy 随后可能返回 502。

发生此问题时可恢复发行版软件包并重启服务：

```bash
sudo apt-get install --no-install-recommends novnc
sudo systemctl restart browser-desktop
curl -f http://127.0.0.1:6080/vnc.html >/dev/null
curl -f http://127.0.0.1:9222/json/version >/dev/null
```

本机的 Pi CLI 使用独立目录中的 Node.js 22，不应依赖 `/usr/bin/node`。交互式 shell 已将
该目录放在 PATH 前部；若通过 systemd、cron 等非交互环境启动 Pi，必须显式设置 PATH，
否则可能误用 noVNC 拉入的 Node.js 18，并因缺少较新的 Node API 而启动失败：

```ini
Environment=PATH=/home/ubuntu/.local/share/pi-node/node-v22.23.2-linux-arm64/bin:/usr/local/bin:/usr/bin:/bin
```

可选待办：改为在 `/opt/browser-desktop` 独立部署上游 noVNC 静态资源，或采用其他不依赖
发行版 `nodejs` 包的安装方式，并固定版本、校验下载内容及记录升级流程。完成后可移除
Ubuntu `novnc` 包及系统 Node.js 18，同时保留 Python `websockify`；这不是当前部署的必要
修复，实施前需要验证安装、升级、回滚和服务重启后的完整链路。

若服务只通过带认证的 Caddy 等反向代理访问，可在 `/etc/default/browser-desktop` 设置
`VNC_AUTH=false` 取消第二层 VNC 密码，然后重启服务。此时必须继续让 `6080` 仅监听
`127.0.0.1`，不能直接暴露到公网。

常用管理命令：

```bash
sudo systemctl status browser-desktop
sudo journalctl -u browser-desktop -f
sudo systemctl restart browser-desktop
sudo systemctl stop browser-desktop
```

修改 `/etc/default/browser-desktop` 后需要重启服务。各进程的详细日志位于
`/var/log/browser-desktop/`。

卸载服务（保留 Chromium 和其他系统软件包）：

```bash
sudo systemctl disable --now browser-desktop
sudo rm /etc/systemd/system/browser-desktop.service
sudo systemctl daemon-reload
```

如需同时删除浏览器登录态，再删除 `/home/browser-desktop`。这是不可恢复操作，执行前
应确认无需保留登录信息。

## 自动化接入

CDP 默认只暴露到本机 `127.0.0.1:9222`。服务健康后可以检查：

```bash
curl http://127.0.0.1:9222/json/version
```

Playwright 示例：

```javascript
import { chromium } from "playwright";

const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
const context = browser.contexts()[0];
const page = context.pages()[0] ?? await context.newPage();
await page.goto("https://example.com");
```

## 配置

Docker 的常用环境变量见 `.env.example`；systemd 的对应配置位于
`/etc/default/browser-desktop`，模板见 `systemd/browser-desktop.env.example`：

- `VNC_AUTH`：是否启用 VNC 自身认证；关闭前必须确保 noVNC 有外层认证且只监听回环。
- `VNC_PASSWORD`：VNC 密码，仅在 `VNC_AUTH=true` 时使用，最多 8 个字符。
- `START_URL`：启动页。
- `SCREEN_WIDTH`、`SCREEN_HEIGHT`、`SCREEN_DEPTH`：虚拟屏幕参数。
- Docker：`NOVNC_BIND_ADDRESS`、`NOVNC_PORT`、`CDP_BIND_ADDRESS`、`CDP_PORT` 控制宿主机映射。
- systemd：`NOVNC_LISTEN_ADDRESS`、`NOVNC_LISTEN_PORT`、`CDP_LISTEN_ADDRESS`、`CDP_LISTEN_PORT` 控制监听。
- `CHROMIUM_FLAGS`：追加 Chromium 参数，以空格分隔。

服务默认只监听 `127.0.0.1`。如需远程使用，建议通过 SSH 隧道访问：

```bash
ssh -L 6080:127.0.0.1:6080 -L 9222:127.0.0.1:9222 user@server
```

不要把 CDP 端口直接暴露到公网；CDP 本身没有认证，拿到该端口通常就能完整控制
浏览器及其登录态。当前实例的 VNC 密码已关闭，安全边界是回环监听和 Caddy Basic Auth；
若绕过 Caddy 暴露 noVNC，等同于公开浏览器桌面。

## Caddy 反向代理

当前站点配置的关键结构如下，WebSocket 无需额外指令：

```caddyfile
cr.20070809.xyz {
    encode gzip
    basicauth {
        admin <bcrypt-hash>
    }
    redir / /vnc.html?autoconnect=1&resize=scale 302
    reverse_proxy 127.0.0.1:6080
}
```

检查完整链路：

```bash
systemctl is-active browser-desktop caddy
curl http://127.0.0.1:6080/vnc.html                    # 200
curl http://127.0.0.1:9222/json/version                # CDP JSON
curl -o /dev/null -w '%{http_code}\n' https://cr.20070809.xyz/          # 302
curl -o /dev/null -w '%{http_code}\n' https://cr.20070809.xyz/vnc.html  # 401（未认证）
```
