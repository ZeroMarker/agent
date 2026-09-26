# Caddy 使用笔记

> 官网：https://caddyserver.com/
> 官方文档：https://caddyserver.com/docs/
> 仓库：https://github.com/caddyserver/caddy
> 一句话：Caddy 是一个默认启用自动 HTTPS、配置简洁的 Web 服务器和反向代理。

## 1. 当前环境

| 项目 | 值 |
| --- | --- |
| Caddy 版本 | `2.6.2` |
| 运行方式 | systemd 服务 `caddy.service`（已启用，开机自启） |
| 配置文件 | `/etc/caddy/Caddyfile` |
| 数据目录 | `/var/lib/caddy`（证书、自动保存的配置） |
| 证书颁发 | Let's Encrypt（ACME v2，自动申请与续期） |
| 管理 API | `http://127.0.0.1:2019`（仅本机监听，勿暴露到公网） |
| 域名 | `20070809.xyz` |

## 2. 本机部署实例

当前 `/etc/caddy/Caddyfile`（`sudo caddy adapt` 可看展开后的完整站点清单）：

| 主机 | 上游 | basicauth |
|---|---|---|
| `20070809.xyz` | 127.0.0.1:8080（SysMon，默认） | 是 |
| `tiktok.20070809.xyz` | 127.0.0.1:8766 | 是 |
| `douyin.20070809.xyz` | 127.0.0.1:8001 | 是 |
| `edit.20070809.xyz` | 127.0.0.1:8345 | 是 |
| `netdata.20070809.xyz` | 127.0.0.1:19999 | 是 |
| `212.20070809.xyz` | 127.0.0.1:8512 | 是 |
| `dsh.20070809.xyz` | 127.0.0.1:3080 | 是 |
| `cr.20070809.xyz` | 127.0.0.1:6080（Chromium noVNC） | 是 |
| `ibkr.20070809.xyz` | 127.0.0.1:8081 | 否（免密） |

结构说明：

- 每个应用一个独立子域名，在自己根路径运行，站点块里直接 `reverse_proxy`，不再使用旧的路径前缀代理。`cr` 仅额外把根路径重定向到 noVNC 入口页。
- 站名即 `20070809.xyz` 的子域，需在 Cloudflare 为每个子域加 A/AAAA 指向本机，否则 Caddy 无法签发证书。
- `encode gzip` 压缩响应；`basicauth { admin <hash> }` 为每个子站点套同一套账号；`ibkr` 是唯一免密项（继承原 `/public` 豁免）。
- 旧路径代理（`/tiktok` `/douyin` `/edit` `/netdata` `/212` `/public/ibkr`）已全部移除，改为子域名；旧路径访问已失效。
- `dsh.20070809.xyz` 承载 dsh web：它是**绝对根路径 SPA**（`/assets` `/plugins` `/api`/WebSocket 都以 `/` 为基准），无法与 `20070809.xyz` 根路径（被 SysMon 占用 `/api`·`/manifest`）共存于同一主机，故用独立子域名。
- `cr.20070809.xyz` 反代 Chromium 的 noVNC 服务；访问根路径会跳转到自动连接、按比例缩放的 `/vnc.html`，WebSocket 由 Caddy 自动透传。公网入口使用共享 Basic Auth，VNC 自身密码已关闭；noVNC 端口仅监听回环地址，不能直接暴露公网。

**dsh web 注意**：跑在 systemd `dsh-web.service` 下（`dsh web --no-open --host 127.0.0.1 --port 3080 --trusted-host dsh.20070809.xyz`，开机自启，崩溃自动重启），版本为 `@deepseek-ai/dsh@0.1.5-rc.3`（全局 npm 装于 pi-node 的 node 下；2026-09-26 重启服务，使已安装版本及模型目录生效）。opencode 相关已移除：`oc.20070809.xyz` 站点、`opencode-usage.service`（`/opt/opencode-usage`）、`~/.dsh/profiles/web` 对 `@dsh-ltctfer/dsh-opencode-go-usage` 的依赖/`cordis.patch.yml` 插入项及 `/tmp/dsh-opencode-go-usage` 源码均已删除——该插件（上游最新 0.1.1）引用了已被删除的 `installSettingsSection`，在新版下启动即 crash-loop（`SyntaxError ... does not provide an export named 'installSettingsSection'`），正是此前钉在旧版的原因；移除后升级一次启动成功。公网访问有**两道门**：① 服务端 `/api` browser-trust fence 认 Host，`--trusted-host` 已放行公网域名（缺它时所有 `/api` 走公网都是 403）；② 设置/提供方目录页还有**客户端门**——前端按浏览器地址栏算 `isLoopback`（仅 `localhost`/`127/8`/`::1` 算回环），公网域名打开时设置 mirror 强制 `unavailable`，报 `settings are unavailable in this browser`，服务端改不了。结论：聊天主界面走公网子域名；**改模型/供应商/凭证必须用回环地址开页面**——本机直接开 `http://127.0.0.1:3080`，远程则 `ssh -L 3080:127.0.0.1:3080 ubuntu@<本机IP>` 后在自己电脑开 `http://127.0.0.1:3080`。

**访问 token**：0.1.2-rc.1 起 `dsh web` 启动时生成一次性访问 token，只打印到日志（`dsh web: http://127.0.0.1:3080/?token=...`）；不带 token 访问回环地址一律 401。取当前值：

```bash
journalctl -u dsh-web.service --no-pager | grep -o 'token=[A-Za-z0-9_-]*' | tail -1
```

- 打开 `http://127.0.0.1:3080/?token=<值>`（公网为 `https://dsh.20070809.xyz/?token=<值>`，先过 Caddy Basic Auth）→ 303 并 `Set-Cookie: dsh-auth-<kid>=v1.<payload>.<sig>`，之后同一浏览器不再需要 token。
- cookie 载荷里的 `authority` 绑定签发来源的 host：按回环签发的 cookie 拿到公网域名用是 401，反之亦然；有效期 30 天（`Max-Age=2592000`），`HttpOnly; SameSite=Strict`。
- token 本身不落盘（`~/.dsh` 内无副本），服务重启后必须重新从日志取。
- 本笔记不记录 token 值：仓库公开（`github.com/ZeroMarker/agent`），需要时按上面命令现取。

修改配置后的操作顺序（本机实际操作）：

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile   # 格式化配置
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile  # 校验
sudo systemctl reload caddy                       # 热重载，不中断服务
```

验证：

```bash
systemctl status caddy --no-pager                 # 服务运行状态
sudo ss -lntup | grep -E ':(80|443)\b'            # 80/443 监听情况
# 子域名未加 DNS 前，直接探测后端可通性：
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8766/   # tiktok 后端
# DNS 生效后访问子域名（除 ibkr 外需 admin 密码）：
curl -k -u admin:<密码> -o /dev/null -w '%{http_code}\n' https://tiktok.20070809.xyz/
curl -k -o /dev/null -w '%{http_code}\n' https://ibkr.20070809.xyz/   # 免密
# Chromium/noVNC：根路径 302；未认证访问入口页为 401；本机后端为 200
curl -o /dev/null -w '%{http_code}\n' https://cr.20070809.xyz/
curl -o /dev/null -w '%{http_code}\n' https://cr.20070809.xyz/vnc.html
curl -o /dev/null -w '%{http_code}\n' http://127.0.0.1:6080/vnc.html
```

证书存放位置：

```bash
sudo find /var/lib/caddy/.local/share/caddy/certificates -name '*.crt'
```

## 3. 适用场景

- 为本机的 Web 应用提供域名、HTTPS 和反向代理。
- 托管静态网站或单页应用（SPA）。
- 在多个后端之间负载均衡，并进行健康检查。
- 为内网服务签发本地 CA 证书。

Caddy 的原生配置是 JSON；日常使用通常编写更易读的 `Caddyfile`，由配置适配器转换为 JSON。只要域名解析到服务器、80/443 端口可从公网访问，且未显式关闭 HTTPS，Caddy 通常会自动申请、安装和续期证书，并把 HTTP 重定向到 HTTPS。

## 4. 安装

### Debian / Ubuntu / Raspberry Pi OS

官方软件包会安装并启动 `caddy.service`：

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
sudo chmod o+r /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### Fedora / RHEL / CentOS

```bash
# Fedora
sudo dnf install dnf5-plugins
sudo dnf copr enable @caddy/caddy
sudo dnf install caddy

# RHEL / CentOS：将第一行改为
sudo dnf install dnf-plugins-core
```

### Docker Compose

```yaml
services:
  caddy:
    image: caddy:2
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp" # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./site:/srv:ro
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

`/data` 中保存证书和私钥，生产环境必须持久化。官方发行包只包含标准模块；需要 DNS provider 等第三方模块时，可从下载页选择模块，或使用 `xcaddy` 构建自定义二进制。

## 5. Caddyfile 快速开始

Linux 官方包默认读取 `/etc/caddy/Caddyfile`。

### 反向代理

```caddyfile
example.com {
    encode zstd gzip
    reverse_proxy 127.0.0.1:3000
}
```

DNS 的 A/AAAA 记录需指向服务器，防火墙和云安全组需放行 TCP 80、TCP 443；若使用 HTTP/3，再放行 UDP 443。

### 静态网站

```caddyfile
example.com {
    root * /srv/example
    encode zstd gzip
    file_server
}
```

运行服务的 `caddy` 用户必须能读取站点文件。推荐使用 `/srv` 或 `/var/www/html`，不要把内容放在只有个人用户可进入的 home 目录中。

### 单页应用（SPA）

```caddyfile
example.com {
    root * /srv/example
    encode zstd gzip
    try_files {path} /index.html
    file_server
}
```

### API 与前端分流

```caddyfile
example.com {
    handle /api/* {
        reverse_proxy 127.0.0.1:8080
    }

    handle {
        root * /srv/example
        try_files {path} /index.html
        file_server
    }
}
```

如果后端不需要 `/api` 前缀，使用 `handle_path /api/*`，它会在转发前去掉匹配到的前缀。

### 多后端负载均衡

```caddyfile
example.com {
    reverse_proxy app1:8080 app2:8080 app3:8080 {
        lb_policy round_robin
        health_uri /healthz
        lb_try_duration 5s
    }
}
```

### HTTPS 上游

```caddyfile
example.com {
    reverse_proxy https://backend.example.net
}
```

不要在生产环境使用 `tls_insecure_skip_verify`。上游使用私有 CA 时，应通过 `tls_trust_pool` 信任该 CA；上游证书名称与连接地址不一致时，再配置 `tls_server_name`。

## 6. HTTPS 配置

### 公网域名

一般不需要写 `tls` 指令：站点地址写成域名即可启用自动 HTTPS。申请证书前检查：

- 域名 A/AAAA 记录正确；错误的 AAAA 记录也会导致验证失败。
- 80/443 未被 Nginx、Apache 等进程占用。
- 公网能访问 80/443，CDN 或防火墙未阻断 ACME 验证。
- Caddy 的 `/data` 目录可写且持久化。

可在全局选项设置 ACME 联系邮箱：

```caddyfile
{
    email admin@example.com
}

example.com {
    reverse_proxy localhost:3000
}
```

### 本机或内网 HTTPS

```caddyfile
app.internal {
    tls internal
    reverse_proxy 127.0.0.1:3000
}
```

`tls internal` 使用 Caddy 自带的本地 CA。客户端必须信任其根证书；在容器或无权限环境中，Caddy 可能无法自动安装信任根，需要手动分发。

### 仅使用 HTTP

站点地址显式写出 `http://`：

```caddyfile
http://localhost:8080 {
    respond "Caddy is running"
}
```

## 7. 检查、格式化与加载配置

修改配置后，先格式化和验证，再无中断重载：

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo systemctl reload caddy
```

常用命令：

```bash
caddy version
caddy list-modules
caddy adapt --config ./Caddyfile --adapter caddyfile --pretty
caddy run --config ./Caddyfile --adapter caddyfile
caddy reload --config ./Caddyfile --adapter caddyfile
```

`caddy run` 在前台运行，适合容器和调试；`caddy start` 会放到后台，但生产 Linux 环境更推荐 systemd。配置变更应使用 `reload`，不要通过停止再启动制造服务中断。

## 8. systemd 服务与日志

```bash
systemctl status caddy
sudo systemctl enable --now caddy
sudo systemctl reload caddy
sudo systemctl restart caddy
sudo systemctl stop caddy

journalctl -u caddy --no-pager -n 100
journalctl -u caddy -f
```

访问日志需要显式开启：

```caddyfile
example.com {
    log {
        output file /var/log/caddy/access.log {
            roll_size 100MiB
            roll_keep 10
            roll_keep_for 720h
        }
    }
    reverse_proxy localhost:3000
}
```

确保 `caddy` 用户可以创建或写入日志目录。若只需集中查看服务日志，直接使用默认的 journald 更省事。

## 9. 常见问题排查

### 证书申请失败

```bash
dig +short A example.com
dig +short AAAA example.com
sudo ss -lntup | grep -E ':(80|443)\b'
journalctl -u caddy --no-pager -n 200
```

重点检查 DNS、IPv6、端口占用、防火墙、NAT 和 ACME 速率限制。不要反复重启碰运气；先从日志中的 ACME 错误定位原因。

### 返回 502 Bad Gateway

```bash
curl -v http://127.0.0.1:3000/
sudo -u caddy curl -v http://127.0.0.1:3000/
```

确认后端已监听、端口正确，并注意容器中的 `localhost` 只指当前容器：Compose 下通常应使用服务名，如 `reverse_proxy app:3000`。

### 静态文件返回 403 / 404

逐级检查目录权限和实际路径：

```bash
namei -l /srv/example/index.html
sudo -u caddy test -r /srv/example/index.html && echo readable
```

### 配置看似正确但路由不符合预期

Caddyfile 会按内置指令顺序排序，而不是永远逐行执行。复杂路由使用互斥的 `handle` 块；必须严格保持书写顺序时使用 `route`。可通过 `caddy adapt --pretty` 查看最终 JSON 配置。

## 10. 安全与运维建议

- 不要把 Caddy 管理 API（默认 `localhost:2019`）暴露到公网。
- 证书私钥位于 Caddy 数据目录；限制权限、持久化存储并纳入备份策略。
- 使用 CDN 或另一层代理时，只有配置了可信代理范围，才能安全地信任客户端 IP 转发头。
- 升级前运行 `caddy validate`；需要第三方模块时，确认新二进制仍包含所需模块。
- 容器中将配置文件设为只读，但 `/data` 和 `/config` 保持可写。

## 11. 官方资料

- [安装](https://caddyserver.com/docs/install)
- [Caddyfile 教程](https://caddyserver.com/docs/caddyfile-tutorial)
- [Caddyfile 指令索引](https://caddyserver.com/docs/caddyfile/directives)
- [自动 HTTPS](https://caddyserver.com/docs/automatic-https)
- [运行与 systemd](https://caddyserver.com/docs/running)
- [命令行参考](https://caddyserver.com/docs/command-line)
- [Docker 镜像](https://hub.docker.com/_/caddy)

### dsh 模型列表更新后未生效（2026-09-26）

全局 npm 包已是 `0.1.5-rc.3`，但 `dsh-web.service` 仍是 9 月 11 日启动的进程。升级磁盘上的包不会自动重启 systemd 服务，运行中的模型目录需要重启后重新加载。本次执行 `sudo systemctl restart dsh-web.service` 后，通过模型选择器实际使用的 `POST /api/session/modelCatalog` 验证：DeepSeek 目录包含 `deepseek-flash`（`DeepSeek-V41-Flash`），OpenCode Go 目录包含 `glm-5.3`、`kimi-k3` 等模型，`failures` 为空。默认模型仍为 `deepseek-v4-flash`。

以后更新包后执行：

```bash
npm install -g @deepseek-ai/dsh@latest
sudo systemctl restart dsh-web.service
systemctl is-active dsh-web.service
```

浏览器刷新页面后重新打开模型选择器。若需要检查发布通道，可运行 `npm view @deepseek-ai/dsh dist-tags`；本次核对时 `latest` 为 `0.1.5-rc.3`，`next` 为 `0.1.7-rc.2`。GitHub 新发布的预览版与 npm `latest` 不一定同步，见[上游发布记录](https://github.com/deepseek-ai/deepseek-harness/releases)。
