# FilmCraft 网页版 / Caddy 部署

FilmCraft 是 Rust 编写的视频编辑软件，其 WebAssembly 版本可作为静态网站托管。此次使用官方发布包部署，没有构建源码或启动视频处理后端。[源码](https://github.com/storytold/filmcraft)、[Web 说明](https://github.com/storytold/filmcraft/blob/main/docs/web.md)

## 当前部署

| 项目 | 值 |
| --- | --- |
| 部署日期 | 2026-10-09 |
| 访问地址 | https://film.20070809.xyz/ |
| 版本 | `v0.4.0` |
| 官方包 | `filmcraft-web-0.4.0.zip` |
| 站点目录 | `/srv/filmcraft/releases/0.4.0` |
| 当前版本入口 | `/srv/filmcraft/current`，符号链接指向版本目录 |
| Caddy 配置片段 | `/etc/caddy/film.caddy` |
| 主配置 | `/etc/caddy/Caddyfile`，通过 `import` 加载片段 |
| 服务 | 现有 `caddy.service`，无需额外应用进程 |
| 登录 | 用户名 `admin`，沿用现有 Caddy 站点密码 |

发布包来源：[FilmCraft v0.4.0](https://github.com/storytold/filmcraft/releases/tag/v0.4.0)。下载后已与该 release 的 `SHA256SUMS.txt` 核对，SHA-256 为：

```text
0dec892acec8e65e2af0177e96f958877f50e2aea0f0e6385128322b679519d9
```

## Caddy 配置

下面是配置结构；密码散列只保留在服务器配置中，不写入公开仓库。

```caddyfile
film.20070809.xyz {
    root * /srv/filmcraft/current
    encode zstd gzip
    basic_auth {
        admin <沿用现有站点的密码散列>
    }
    header {
        Cross-Origin-Opener-Policy same-origin
        Cross-Origin-Embedder-Policy require-corp
        Cross-Origin-Resource-Policy same-origin
        Cache-Control no-cache
    }
    @versioned {
        path *.wasm *.js
        query v=*
    }
    header @versioned Cache-Control "private, max-age=31536000, immutable"
    file_server {
        precompressed gzip
        hide .htaccess _headers
    }
}
```

WASM、JavaScript 和 HTML 已预生成 gzip 文件；WASM 原始大小为 40,753,243 字节，gzip 后为 14,683,144 字节。Caddy 正确提供 `application/wasm`。带构建版本参数的 JS/WASM 使用长期私有缓存，HTML 每次重新验证。

## 验证结果与使用范围

- Caddy 配置校验通过，并已热重载。
- Caddy 成功获取 `film.20070809.xyz` 的 HTTPS 证书；公网未登录访问返回 `401` 和 Basic Auth 验证头。
- 使用临时回环 Caddy 服务及 Chromium 测试官方包：页面 `200`，WASM 初始化与应用启动完成，`window.filmcraft` API 可用，没有页面脚本错误；画面显示预览、素材库和时间线。
- 回环测试确认 WASM 类型、gzip 与跨源隔离响应头；临时测试服务已关闭。

浏览器启动测试使用 `?webgl` 与软件图形渲染。公网登录后的完整工作流、用户设备 WebGPU、真实素材导入和视频导出尚未实测。

编辑器在用户浏览器中处理素材，服务器提供静态文件。网页版与桌面版存在性能、线程及功能差异；具体限制见[官方 Web 文档](https://github.com/storytold/filmcraft/blob/main/docs/web.md)。遇到图形后端问题可尝试 https://film.20070809.xyz/?webgl 。

## 更新与回滚

更新时下载对应版本 Web 包及校验文件，核对 SHA-256，解压到新的 `/srv/filmcraft/releases/<版本>`，再生成压缩文件并切换 `current` 链接。保留旧版本以便回滚，避免将新版本直接覆盖到旧目录。

若只切换静态目录，通常无需重启 Caddy。修改配置后先执行 `sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile`，通过后执行 `sudo systemctl reload caddy`。

此次修改前的主配置备份为 `/etc/caddy/Caddyfile.bak-filmcraft-20261009011425`。恢复整份配置前应确认没有后续站点修改，避免覆盖其他应用的变更。
