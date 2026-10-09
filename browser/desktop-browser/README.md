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
| VNC 空闲降频 | 已关闭（`x11vnc -nonap`） |
| noVNC | `127.0.0.1:6080` |
| CDP | `127.0.0.1:9222` |
| 浏览器程序 | `/opt/browser-desktop/bin/chromium` |
| 虚拟屏 | `1920x1080x24`（Xvfb `:99`，16:9） |
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

安装脚本会安装 Chromium、Xvfb、Fluxbox、x11vnc、websockify 等依赖，并把经过
SHA-256 校验的上游 noVNC 静态资源安装到 `/opt/browser-desktop/novnc`。脚本默认生成一个随机的
8 字符 VNC 密码并启动服务。密码及其他配置位于 `/etc/default/browser-desktop`；本机实例
因已有 Caddy Basic Auth，另行设置了 `VNC_AUTH=false`。
Ubuntu 的 Chromium Snap 无法在普通 system service cgroup 中启动，因此安装脚本会使用
Playwright 提供的 Chromium 构建；Debian 使用发行版原生 `chromium` 软件包。浏览器以
独立低权限用户运行，并默认关闭 Chromium sandbox，以兼容 Ubuntu 的 user namespace 限制。

### 显示比例与分辨率

虚拟屏分辨率由 Xvfb 的 `-screen 0 WxHxD` 决定（即 `SCREEN_WIDTH`/`SCREEN_HEIGHT`/
`SCREEN_DEPTH`），本机为 `1920x1080x24`（16:9）。Chromium 以 `--start-maximized` 铺满屏幕，
窗口实际尺寸比屏幕矮约 22 像素（Fluxbox 工具栏），即 `1920x1058`。

x11vnc 默认会在画面空闲时降低轮询频率。本机关闭此机制，以免恢复操作时出现明显的
画面更新延迟；测试数据见下方性能排查记录。

noVNC 侧由 URL 参数 `resize=scale` 决定呈现方式：整幅远端画面等比缩放到浏览器窗口，
比例与窗口不一致时留黑边，**不会**改变远端分辨率。窗口小于 1920x1080 时画面连同文字一起
缩小；要看得更大，应调小 `SCREEN_WIDTH`/`SCREEN_HEIGHT`，而不是放大浏览器窗口。

远端自适应（`resize=remote`）在本机不可用：Xvfb 的 RANDR 上限等于启动时的 `-screen` 尺寸，
且只暴露该尺寸一个模式，因此 x11vnc 协商 `ExtDesktopSize` 时无法改到窗口尺寸。用一个独立的
`1440x900` 屏复现（不影响运行实例）：

```bash
Xvfb :98 -screen 0 1440x900x24 +extension RANDR -ac &
DISPLAY=:98 xrandr                  # maximum 1440x900，仅一个 1440x900 模式
DISPLAY=:98 xrandr --fb 1920x1080   # screen cannot be larger than 1440x900
DISPLAY=:98 xrandr --fb 1280x720    # 帧缓冲会缩到 1280x720，但输出仍为 1440x900（无匹配模式），并报 BadValue
```

结论：`resize=scale` 只是等比缩放；要「随窗口自动匹配」必须换掉 Xvfb（改用支持动态分辨率
和多模式的方案，如 TigerVNC 自带 Xvnc 或 XRDP）。

修改分辨率的步骤：

```bash
sudo sed -i 's/^SCREEN_WIDTH=.*/SCREEN_WIDTH=1920/; s/^SCREEN_HEIGHT=.*/SCREEN_HEIGHT=1080/' \
    /etc/default/browser-desktop
sudo systemctl restart browser-desktop
DISPLAY=:99 xdpyinfo | grep dimensions                 # dimensions: 1920x1080 pixels
DISPLAY=:99 xwininfo -root -tree | grep '"chromium"'   # 最大化窗口尺寸
```

重启会关闭浏览器里已打开的页面；登录态存放在用户数据目录，不会丢失。
`systemd/browser-desktop.env.example` 与 Docker 的 `.env.example` 仍保留模板默认值
`1440x900`，本机实例在 `/etc/default/browser-desktop` 中覆盖。

### 性能排查记录（2026-09-28）

用户反馈远程操作卡顿。主机的 CPU、可用内存和磁盘等待均未持续打满，
本机 noVNC 静态页面响应约 11 ms。将虚拟屏从 `1920x1080` 降到 `1280x720`
没有带来有效改善；将 noVNC 画质/压缩从默认的 `6/2` 改为 `3/6` 有一些改善，
再降到 `2/6` 没有进一步改善。最终按用户要求恢复 `1920x1080` 和 `6/2`。
公网入口显式带上画质参数，以覆盖 noVNC 保存在客户端的旧设置。

进一步在服务器本机用 RFB 客户端连续请求 `1x1` 像素的非增量画面更新，
发现 x11vnc 默认空闲降频会让后续请求反复等待约 510 ms。
经本机 websockify/WebSocket 请求时也有相同等待；直接读取整屏则只需数十毫秒。
在运行中的 x11vnc 上执行以下命令后，同一测试的直接 VNC 更新约 11–14 ms，
本机 WebSocket 更新约 21 ms：

```bash
sudo -u browser-desktop env DISPLAY=:99 x11vnc -R nonap
```

`start-browser.sh` 已添加 `-nonap`，使服务下次启动时继续禁用空闲降频，
无需每次运行上面的命令。连接空闲的 VNC 客户端进行 5 秒采样时，
x11vnc 和 Xvfb 分别占用约单核的 3.4% 和 2.4% CPU。
用户复测后确认有改善，当前体验可接受。

这些时间是本机的画面更新测试，不等同于公网的点击到显示延迟。
x11vnc 日志中的 `client latency` 会受其画面更新调度影响，不能单独用来判断
公网链路延迟；若以后仍卡顿，应在有问题的操作发生时分别测网页响应和客户端链路。

### 只看到 Ubuntu 壁纸：窗口折叠排查（2026-10-09）

本次用户反馈桌面只剩 Ubuntu 标志，怀疑浏览器崩溃。检查时 Chromium、Fluxbox、
Xvfb 和 VNC 均仍在运行，CDP 正常响应。Chromium 窗口的 `_NET_WM_STATE` 包含
`_NET_WM_STATE_SHADED`，外层窗口高度只有 21 像素：Fluxbox 把窗口折叠到标题栏，
因此露出了桌面壁纸。移除 SHADED 状态后浏览器立即恢复，原有标签页和表单均保留，
没有重启服务。

本机 `/home/browser-desktop/.fluxbox/keys` 中有以下绑定：

```text
OnTitlebar Double Mouse1 :Shade
```

即双击窗口管理器标题栏会切换折叠状态；再次双击同一标题栏即可展开。
误双击是可能的触发原因，但现有日志不记录具体鼠标点击或 Shade 动作，无法追溯
本次究竟由哪次操作触发。VNC 里的 PointerEvent 统计只有事件数量，不能据此认定发生了双击。

遇到相同现象时，先检查服务、CDP 和窗口状态，避免直接重启而中断当前页面：

```bash
systemctl show browser-desktop \
    -p ActiveState -p SubState -p ActiveEnterTimestamp -p NRestarts -p Result
curl -fsS --max-time 5 http://127.0.0.1:9222/json/version

# 服务启用了 PrivateTmp；进入其挂载命名空间，才能访问对应的 X11 socket。
desktop_pid=$(systemctl show browser-desktop -p MainPID --value)
sudo nsenter -t "$desktop_pid" -m -- env DISPLAY=:99 xwininfo -root -tree
# 从上一步找到 Chromium 页面窗口的 ID，填入下面的变量。
window_id='替换为实际窗口 ID，如 0xe00003'
sudo nsenter -t "$desktop_pid" -m -- env DISPLAY=:99 \
    xprop -id "$window_id" _NET_WM_STATE WM_STATE
```

若状态包含 `_NET_WM_STATE_SHADED`，通过 noVNC 双击顶部 Fluxbox 标题栏展开，
然后重新检查状态和画面。上述 `:99` 对应本机实例；修改过 `DISPLAY_NUMBER` 时需同步替换。

本次日志分析（时间均为 UTC）：

| 证据 | 判断与限制 |
|---|---|
| 服务自 10 月 8 日 06:35:23 运行，`NRestarts=0` | 本轮运行期间没有自动重启 |
| 10 月 8 日 06:35:22 先出现 systemd `Stopping`，随后退出码 143 并重新启动 | 前一次退出发生在停止服务过程中，与次日窗口折叠事件无关；不能据此判断为自发崩溃 |
| 内核日志未发现 OOM、进程被杀或 segfault；Chromium 的 pending/completed 崩溃报告目录为空 | 没有找到记录在案的崩溃证据，不代表日志能覆盖所有异常 |
| 10 月 9 日 02:33:13、02:33:50 VNC 连接成功；中间在 02:33:44 断开 | 客户端发生重连，服务仍能完成协议协商；日志未说明断开原因 |
| 01:10、01:15 的 VNC 延迟估计约 44–62 ms；02:33 约 620–629 ms | 后两次连接更新时序较慢；不能单凭该值定位公网链路，也不能解释 SHADED 状态 |
| Chromium 在 01:28–02:32 出现桌面 portal 请求取消/结束消息 | 没有伴随浏览器退出；日志不足以确定具体是哪次桌面交互 |
| 启动时出现 GPU/EGL、PipeWire、缺失桌面服务、Fluxbox 配置回退及键盘符号警告 | 这些消息早于事件，服务随后正常运行；未发现它们导致窗口折叠的证据 |
| x11vnc 忽略部分客户端 encoding，同时成功选用 tight 并发送 1920×1080 尺寸 | 本次这些消息没有阻止连接和画面传输 |

### 日志位置与取证限制

systemd 部署的组件日志位于 `/var/log/browser-desktop/`，读取需要相应权限：

| 日志 | 内容 |
|---|---|
| `chromium.log` | Chromium 标准输出/错误、CDP 启动信息及桌面集成消息 |
| `fluxbox.log` | 窗口管理器启动及配置错误；不记录逐次窗口操作 |
| `x11vnc.log` | VNC 连接/断开、协议与编码协商、传输和输入事件数量、延迟估计 |
| `novnc.log` | websockify 启动、WebSocket 连接及代理错误 |
| `journalctl -u browser-desktop` | systemd 服务生命周期、启动脚本输出及 Xvfb 消息 |

```bash
sudo journalctl -u browser-desktop --since '2026-10-09 01:00:00' --no-pager
sudo tail -n 100 /var/log/browser-desktop/chromium.log
sudo tail -n 100 /var/log/browser-desktop/fluxbox.log
sudo tail -n 100 /var/log/browser-desktop/x11vnc.log
sudo tail -n 100 /var/log/browser-desktop/novnc.log
sudo journalctl -k --since '2026-10-09 01:00:00' --no-pager \
    | rg -i 'oom|out of memory|killed process|segfault'
```

当前启动脚本使用 `>` 写入上述四个组件日志，**每次服务启动会覆盖旧内容**，
且没有配置组件日志轮转。需要追查时应在重启前保存日志；systemd journal 的历史保留
则取决于主机 journald 配置。Chromium 和 Fluxbox 的部分消息没有完整时间戳，
不能把它们精确对应到每一次用户操作。

### noVNC 版本与升级

本项目不安装发行版的 `novnc` 包。它会拉取固定的上游 noVNC 1.7.0 源码归档、校验
SHA-256 后作为纯静态资源使用；运行时只需要 Python `websockify`，不依赖 Node.js。
实际版本目录为 `/opt/browser-desktop/novnc-1.7.0`，`/opt/browser-desktop/novnc` 是指向
当前版本的符号链接。

从旧版部署迁移时，先重新运行安装脚本并验证服务，再移除发行版 noVNC：

```bash
sudo ./install-systemd.sh
curl -f http://127.0.0.1:6080/vnc.html >/dev/null
sudo apt-get remove novnc
sudo systemctl restart browser-desktop
curl -f http://127.0.0.1:6080/vnc.html >/dev/null
curl -f http://127.0.0.1:9222/json/version >/dev/null
```

此后 `nodejs` 已不再是 browser-desktop 的依赖。仅在确认没有其他程序使用系统 Node.js
后，才删除旧部署拉入的 Node.js 18；先用模拟运行检查 APT 将删除的内容：

```bash
sudo apt-get --simulate autoremove
sudo apt-get autoremove
```

当前实例的外部 SSH 客户端还会启动 Orca relay，它自身要求 Node.js 18+ 和 npm。该需求与
noVNC 无关；本机把 Pi 自带的 Node.js 22 暴露给非交互 SSH 环境，而不是重新安装发行版
Node.js 18：

```bash
sudo ln -sfn /home/ubuntu/.local/share/pi-node/node-v22.23.2-linux-arm64/bin/node /usr/local/bin/node
sudo ln -sfn /home/ubuntu/.local/share/pi-node/node-v22.23.2-linux-arm64/bin/npm /usr/local/bin/npm
sudo ln -sfn /home/ubuntu/.local/share/pi-node/node-v22.23.2-linux-arm64/bin/npx /usr/local/bin/npx
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin node --version
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin npm --version
```

升级或移动 Pi 的 Node.js 目录后需要同步更新这三个符号链接，否则外部 SSH relay 会再次
报告找不到 Node.js。

升级 noVNC 时，同时修改 `install-novnc.sh` 中的默认版本和对应归档 SHA-256，重新运行
安装脚本并验证 noVNC 页面和 WebSocket 连接。旧版本目录会保留，回滚时可把
`/opt/browser-desktop/novnc` 重新指向旧目录后重启服务。

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
    redir / /vnc.html?autoconnect=1&resize=scale&quality=6&compression=2 302
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
