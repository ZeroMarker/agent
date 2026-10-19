# AionUi WebUI：systemd + Caddy

本机入口：**https://aion.20070809.xyz**。浏览器使用 HTTPS 默认端口 `443`，不需要填写后端地址或连接端口。

2026-10-10 部署 AionUi `v2.2.2` 的独立 WebUI；源码固定在 `6744099b279b991c17e31c243f0920477bd31cb6`。该服务与 `cli.20070809.xyz` 的 Paseo 分开运行。

## 登录和认证

2026-10-11 已将 Caddy Basic Auth 迁移到 [Authelia 统一登录](../../deploy/authelia/README.md)。访问站点先跳转到 `auth.20070809.xyz`，使用 Authelia 账号 `mark` 登录（2026-10-15 由 `admin` 更换）。2026-10-19 移除了 AionUi 网页的第二层密码登录：统一登录通过后直接进入原有本地账号的聊天界面。

后端继续以 `aioncore --local` 运行，API 和 WebSocket 使用 `system_default_user`。网页使用 `/api/system/current-user` 读取后端实际身份，避免独立认证路由 `/api/auth/user` 在本地模式仍要求 Cookie。前端补丁与回归测试见 [local-auth.patch](deploy/local-auth.patch)。Caddy 保留旧前端 `/api/auth/user` 的兼容响应，位于 Authelia 授权之后并设置 `Cache-Control: no-store`；切换多用户或非本地模式时必须移除此兼容响应。原密码哈希与聊天数据保留。

**本版本必须保留 Caddy 认证。** 实测独立启动器以 `aioncore --local` 运行：`/api/conversations` 在无 Cookie 时仍返回 `200`。Caddy 对页面、API（包括上述会话适配）和 WebSocket 通过 Authelia `forward_auth` 验证会话；只有 PWA manifest、图标和 service worker 脚本公开，以便浏览器读取安装信息和更新缓存。页面入口要求重新验证 HTTP 缓存，worker 使用新的缓存版本清理旧页面。

## 部署结构

| 项目 | 本机配置 |
|---|---|
| systemd | `aionui-webui.service`，已启用开机自启 |
| WebUI | `127.0.0.1:25808` |
| Rust 后端 | 自动分配回环端口，由启动器管理 |
| Caddy 片段 | `/etc/caddy/aionui.caddy`，由主 Caddyfile 导入 |
| 源码和前端产物 | `/home/ubuntu/.local/share/aionui/source`、`out/renderer` |
| Rust 二进制 | `/home/ubuntu/.local/share/aionui/runtime/aioncore` |
| 数据库和聊天记录 | `/home/ubuntu/.aionui-web` |
| 私有服务日志 | `/home/ubuntu/.local/state/aionui/service.log` |

独立模式使用 Node 22 + tsx 启动上游 `scripts/webui.ts`，运行时不启动 Electron 或 Xvfb。启动环境包含本机 CLI 工具路径；模型/API 配置仍需在 AionUi 中完成。

## 安装与构建记录

Wiki 中旧的 GitHub 独立安装包链接在本次核对时不可用，因此从固定标签构建前端，并使用官方 ARM64 Debian 包里的 Rust 后端。

官方安装包：`https://static.aionui.com/releases/2.2.2/AionUi-2.2.2-linux-arm64.deb`。

- Debian 包 SHA-256：`3e8e2f292371fcb1ed5ba9a3a28386e7f0610fcc765480b1e95762e1110515e2`。
- 复制后的 `aioncore` SHA-256：`090a50a06d3122f1e2665520429a4af42a8f8b710ffccdf39bdb333780dcfb18`。

本次安装了该 Debian 包，再把后端复制到独立目录；服务不依赖 `/opt/AionUi`。官方桌面包使用账户登录流程，不能直接当作本地管理员模式的独立 WebUI。

前端构建命令（Bun 在隔离的 runtime 目录，版本 `1.4.2`）：

```bash
git clone --depth 1 --branch v2.2.2 https://github.com/iOfficeAI/AionUi.git \
  /home/ubuntu/.local/share/aionui/source
cd /home/ubuntu/.local/share/aionui/source
ELECTRON_SKIP_BINARY_DOWNLOAD=1 \
  /home/ubuntu/.local/share/aionui/runtime/node_modules/.bin/bun \
  install --frozen-lockfile --ignore-scripts
git apply /path/to/agent/tools/aionui/deploy/local-auth.patch
node node_modules/electron-vite/bin/electron-vite.js build \
  --config packages/desktop/electron.vite.config.ts
```

配置模板：[systemd](deploy/aionui-webui.service)、[Caddy](deploy/aionui.caddy)。Caddy 模板依赖主配置导入 `/etc/caddy/authelia.caddy` 中的 `authelia` 片段。禁止把密码或真实哈希提交到仓库。

复制模板到新服务器前，准备源码、依赖、前端产物与 Rust 后端，并创建权限 `700` 的日志目录。首次启动日志可能含管理员明文密码，因此服务使用私有文件日志而不是共享 journal。

```bash
sudo install -m 644 tools/aionui/deploy/aionui-webui.service \
  /etc/systemd/system/aionui-webui.service
sudo systemctl daemon-reload
sudo systemctl enable --now aionui-webui

# 先部署 Authelia，并在主配置导入认证片段及 /etc/caddy/aionui.caddy：
sudo caddy fmt --overwrite /etc/caddy/aionui.caddy
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

## 运维

2026-10-10 初次部署记录（当时使用 Basic Auth）：前端生产构建成功，浏览器完成页面登录并进入 `#/guid`，登录 Cookie 的 WebSocket 连接成功，服务重启后凭据仍有效。随后纠正密码配置：Caddy 与 AionUi 均复用已有 admin 哈希，旧的独立密码作废；公网无凭据页面和 API 返回 `401`。纠正后未获取已有密码明文，验证范围为哈希一致、旧密码被拒绝和服务正常启动。Caddy 验证通过，HTTPS 证书已签发。

2026-10-11 迁移后：未登录的页面和 API 均由 Authelia 拦截，浏览器访问跳转到统一登录页；会话授权及退出验证见 [统一认证验证记录](../../deploy/authelia/README.md#验证)。应用自身的完整浏览器交互未在迁移时重测。

2026-10-19 单次登录验证：通过独立回环 Caddy 测试实例模拟外层认证通过，在全新浏览器上下文中直接进入 `#/guid`，原有会话列表可见、无 JavaScript 异常，刷新和旧 `#/login` 链接均进入主页，无 Cookie 的 WebSocket 握手成功。生产配置验证并热重载后，未登录的页面、会话适配、会话列表和 WebSocket 路径仍跳转 Authelia。公网真实账号的登录后流程未自动重测。随后将免重复登录逻辑下沉到前端，更新 worker 缓存版本；前端身份成功、未授权和无效响应三个回归测试通过，TypeScript、i18n 与针对修改文件的 lint 检查通过。在无代理会话适配的本地服务上，全新浏览器访问 `#/login` 和刷新均直接进入 `#/guid`；旧 v2 worker 缓存升级后被删除并自动重载主页，WebSocket 正常。公网 worker 返回新版脚本，页面和身份接口仍由 Authelia 保护。

```bash
systemctl status aionui-webui --no-pager
sudo systemctl restart aionui-webui
tail -n 100 /home/ubuntu/.local/state/aionui/service.log
```

备份时停止服务，再备份整个 `/home/ubuntu/.aionui-web`；同时保存私有凭据和实际 Caddy 配置。升级前备份数据，在独立目录构建新前端并准备匹配的后端，通过启动、认证与 WebSocket 验证后再切换服务路径。不要仅更新前端而继续使用不匹配的 Rust 后端。

## 资料

- [官方 WebUI 配置指南（中文）](https://github.com/iOfficeAI/AionUi/wiki/WebUI-Configuration-Guide-Chinese)
- [v2.2.2 独立启动器](https://github.com/iOfficeAI/AionUi/blob/v2.2.2/scripts/webui.ts)
- [后端启动参数](https://github.com/iOfficeAI/AionUi/blob/v2.2.2/packages/web-host/src/backend-launcher.ts)
- [官方发布记录](https://github.com/iOfficeAI/AionUi/releases/tag/v2.2.2)
