# Chromium 桌面浏览器

这是一个可直接运行的浏览器服务：Xvfb 提供虚拟显示，Fluxbox 管理窗口，
Chromium 负责浏览网页，x11vnc + noVNC 将桌面提供到浏览器中。另有 CDP 端口供
Playwright、Puppeteer 或其他 Agent 接入。支持 Docker Compose 和原生 systemd 两种部署。

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

安装脚本会安装 Chromium、Xvfb、Fluxbox、x11vnc、noVNC 等依赖，生成一个随机的
8 字符 VNC 密码，并启动服务。密码及其他配置位于 `/etc/default/browser-desktop`。
Ubuntu 的 Chromium Snap 无法在普通 system service cgroup 中启动，因此安装脚本会使用
Playwright 提供的 Chromium 构建；Debian 使用发行版原生 `chromium` 软件包。浏览器以
独立低权限用户运行，并默认关闭 Chromium sandbox，以兼容 Ubuntu 的 user namespace 限制。

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

CDP 默认只暴露到宿主机 `127.0.0.1:9222`。容器健康后可以检查：

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

- `START_URL`：启动页。
- `SCREEN_WIDTH`、`SCREEN_HEIGHT`、`SCREEN_DEPTH`：虚拟屏幕参数。
- `NOVNC_BIND_ADDRESS`、`NOVNC_PORT`：noVNC 的宿主机监听地址和端口。
- `CDP_BIND_ADDRESS`、`CDP_PORT`：CDP 的宿主机监听地址和端口。
- `CHROMIUM_FLAGS`：追加 Chromium 参数，以空格分隔。

服务默认只监听 `127.0.0.1`。如需远程使用，建议通过 SSH 隧道访问：

```bash
ssh -L 6080:127.0.0.1:6080 -L 9222:127.0.0.1:9222 user@server
```

不要把 CDP 端口直接暴露到公网；CDP 本身没有认证，拿到该端口通常就能完整控制
浏览器及其登录态。noVNC 即便设置了密码，也应配合防火墙、SSH 隧道或 HTTPS 反向代理。
