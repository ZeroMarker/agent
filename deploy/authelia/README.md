# Authelia 统一会话认证

2026-10-11 已在本机部署 Authelia v4.39.28，将原有 21 个 Basic Auth 站点统一迁移到 Cookie 会话认证。

登录入口：https://auth.20070809.xyz 。用户名 `admin`，密码沿用原 Caddy 密码；直接复用原 bcrypt 哈希，不记录明文。

保护站点：`20070809.xyz` 及其子域 `212`、`aion`、`alpaca`、`bili`、`bnb`、`clip`、`cpc`、`cr`、`credit`、`dl`、`douyin`、`dsh`、`ff`、`film`、`gh`、`iptv`、`jav`、`muse`、`prowlarr`、`tiktok`。

Paseo、IBKR 和其他原先未使用 Basic Auth 的站点保留原配置。dsh 等应用自身认证仍保留，Authelia 不会自动登录应用。AionUi 于 2026-10-19 增加了针对本地模式的代理适配，统一登录后直接进入原有账号，见 [AionUi 登录说明](../../tools/aionui/README.md#登录和认证)。

## 日常访问

1. 打开任一受保护站点，浏览器跳转到统一登录页。
2. 输入 `admin` 和迁移前的 Caddy 密码，登录后返回原站点。
3. 在同一浏览器访问其他受保护站点时共享会话；应用自身要求登录时仍需完成其登录。
4. 在 Authelia 登录门户退出后，统一会话失效。

当前域名、上游和公开站点清单见 [Caddy 本机部署](../../notes/caddy.md#2-本机部署实例)。`curl -u` 不再用于这些站点的代理层认证。

## 部署

- [compose.yaml](compose.yaml) 固定镜像摘要，使用 host 网络；Authelia 配置只监听 `127.0.0.1:9091`，没有公网服务端口。
- 实际配置、账号哈希和 SQLite 数据保存在 `/etc/authelia`，目录权限 700，配置和账号文件权限 600，不入库。
- 主 Caddyfile 导入 `/etc/caddy/authelia.caddy`；每个受保护站点使用 `import authelia` 代替 `basic_auth`。模板见 [authelia.caddy](authelia.caddy)。不向应用注入身份头，保留应用原有认证逻辑。
- 授权默认拒绝，仅允许 `admin` 访问列出的站点，采用单因素密码登录。
- Cookie 使用 `Secure`、`HttpOnly`、`SameSite=Lax`，域为 `20070809.xyz`；空闲 1 小时失效，普通会话 12 小时，勾选记住登录为 30 天。
- 会话存储为单实例内存，容器重启后需重新登录。密码重置功能关闭，通知文件仅存本机。

```bash
sudo docker compose -f /home/ubuntu/agent/deploy/authelia/compose.yaml up -d
sudo docker exec authelia authelia config validate --config /config/configuration.yml
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo systemctl reload caddy
curl -fsS http://127.0.0.1:9091/api/health
```

## 代理鉴权只接受 Cookie

实际 `/etc/authelia/configuration.yml` 必须明确限制 `forward-auth` 的策略：

```yaml
server:
  address: tcp://127.0.0.1:9091/
  endpoints:
    authz:
      forward-auth:
        implementation: ForwardAuth
        authn_strategies:
          - name: CookieSession
```

这只限制代理鉴权端点；登录门户仍使用账号密码建立会话，应用自身的 Authorization 请求头仍透传。

2026-10-11 排查发现：默认 `forward-auth` 优先接受 `HeaderAuthorization`，浏览器在 Basic Auth 迁移后仍可能发送缓存凭据。页面 API 轮询因此反复校验原 bcrypt 哈希（cost 14），约 10 分钟内出现 600 次成功密码验证，容器 CPU 达到 171%。已将实际配置改为仅使用 `CookieSession`；旧 Basic 凭据不再参与代理鉴权，客户端需登录 Authelia。修正后 10 秒采样平均 CPU 为 0.2%，Docker 即时采样为 0.15%，采样期间未新增密码验证记录。

参考：[认证端点策略与默认 Basic 缓存行为](https://www.authelia.com/configuration/miscellaneous/server-endpoints-authz/)。

## 运维

```bash
sudo docker compose -f /home/ubuntu/agent/deploy/authelia/compose.yaml ps
sudo docker logs --tail 50 authelia
# 修改私有配置后先校验，再重启；重启会使现有会话失效
sudo docker exec authelia authelia config validate --config /config/configuration.yml
sudo docker compose -f /home/ubuntu/agent/deploy/authelia/compose.yaml restart authelia
```

备份时保存整个 `/etc/authelia`、Caddy 实际配置及迁移备份目录；SQLite 数据宜在容器停止时备份。真实密码、账号哈希、会话 Cookie 和通知内容均不提交到仓库。

## 验证

21 个站点未登录时均进入统一登录流程；noVNC 根路径先跳转到 `/vnc.html`，入口页同样受保护。源站 TLS 和公网登录页均正常。

使用临时随机账号完成密码登录、Secure/HttpOnly Cookie、全部 21 个站点的会话授权和退出失效验证；验证后删除测试账号并恢复仅 `admin` 的授权。原 admin 哈希与迁移前一致。未持有原密码明文，因此未执行真实 admin 浏览器登录或逐个应用的完整交互验证。

## 回滚

原配置的私有备份位置记录在 `/etc/authelia/migration.json`。以下命令恢复主配置和所有原片段，验证后热重载：

```bash
sudo python3 - <<'PY'
import json, pathlib, shutil, subprocess
state = json.loads(pathlib.Path('/etc/authelia/migration.json').read_text())
manifest = json.loads((pathlib.Path(state['backup']) / 'manifest.json').read_text())
for target, source in manifest.items():
    shutil.copyfile(source, target)
subprocess.run(['caddy', 'validate', '--config', '/etc/caddy/Caddyfile', '--adapter', 'caddyfile'], check=True)
subprocess.run(['systemctl', 'reload', 'caddy'], check=True)
PY
```

恢复后可停止 Authelia 容器；保留私有数据及备份以便再次迁移。

参考：[Authelia 的 Caddy 集成](https://www.authelia.com/integration/proxies/caddy/)、[会话配置](https://www.authelia.com/configuration/session/introduction/)。
