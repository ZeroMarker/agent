# Chromium 桌面浏览器

这是一个可直接运行的容器化浏览器：Xvfb 提供虚拟显示，Fluxbox 管理窗口，
Chromium 负责浏览网页，x11vnc + noVNC 将桌面提供到浏览器中。另有 CDP 端口供
Playwright、Puppeteer 或其他 Agent 接入。

## 启动

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

常用环境变量见 `.env.example`：

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
