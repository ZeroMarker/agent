# Clash for Linux 笔记

> 仓库：https://github.com/wnlen/clash-for-linux
> 一个更完整、更优雅的 Linux Clash / Mihomo 运行平台（纯 Shell 实现）。本文是对官方 README 与源码（install.sh / scripts/core）的整理速查。

## 1. 项目定位

- **是什么**：Linux 上的 Clash / Mihomo 一键运行平台，把"内核下载、订阅管理、配置生成、节点切换、开机自启、诊断排障"收口成一组 `clash` 命令。
- **适用场景**：VPS / 远程开发环境、本地 Ubuntu / Debian / WSL、OpenWrt / NAS / 小主机（x86 / ARM）、需要稳定访问 GitHub / Go / Node / Docker 生态的开发者。
- **技术栈**：纯 Bash 脚本，无第三方运行时依赖（只依赖系统命令：bash / curl / tar / gzip / unzip 等）。
- **参考项目**：命令行交互风格参考了 [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install)，但为独立实现，非 fork。
- **免责声明**：仅用于学习研究 Shell 编程，勿用于违反法律法规的用途。

## 2. 安装

### 一键安装（推荐）

```bash
git clone --branch master --depth 1 https://ghfast.top/https://github.com/wnlen/clash-for-linux.git
cd clash-for-linux
bash install.sh
```

- 加速前缀 `ghfast.top` 失效可换 [ghproxy.link](https://ghproxy.link/) 上的其他镜像。
- **WSL 注意**：不能放在 Windows 挂载目录 `/mnt/c/` 下，必须装到 Linux 原生目录。
- **dash 问题**：部分系统 `/bin/sh` 是 dash，运行脚本报错（报错含 `-en [ OK ]`），用 `bash xxx.sh`。

### 安装范围（scope）

```bash
bash install.sh            # auto：root → system，普通用户 → user
bash install.sh system     # 写 /usr/bin、systemd，支持 Tun（需 root / CAP_NET_ADMIN）
bash install.sh user       # 用户级：systemd-user 或脚本模式
bash install.sh script     # 纯脚本模式，不注册开机自启，重启后需手动 clashon
bash install.sh system --offline   # 严格离线安装（缺本地资源直接失败，不回退联网）
```

| 范围 | 安装位置 | 开机自启 | Tun |
| --- | --- | --- | --- |
| `system` | `/opt/clash-for-linux`（可用 `CLASH_INSTALL_HOME` 覆盖）+ `/usr/bin` 命令入口 | systemd | ✅（需 root） |
| `user` | `~/.local/share/clash-for-linux` + 用户命令入口 | systemd-user 或脚本 | 视权限 |
| `script` | 项目目录内，仅命令入口 | ❌ 不注册 | 无 procd |

OpenWrt 下只有 `script` 模式兼容（x86_64 / aarch64），无 procd 自启 / LuCI / UCI / opkg 支持，不承诺 MIPS 与 armv7。建议放持久化目录（别放 `/tmp`、`/run`），依赖先 `opkg install bash curl tar gzip coreutils-readlink unzip`。

## 3. 目录结构与三层架构

```
clash-for-linux/
├── install.sh              # 安装入口
├── uninstall.sh            # 卸载入口
├── .env                    # 安装/运行参数（可自定义）
├── config/                 # 静态配置
│   ├── template.yaml       # 运行配置模板
│   ├── mixin.yaml          # 运行补丁（兼容读取，实际用 runtime/mixin.yaml）
│   └── profiles.yaml       # 订阅配置文件
├── scripts/
│   ├── core/               # 核心逻辑：clashctl / config / runtime / proxy / alias / completion / update
│   ├── init/               # 安装初始化：systemd / systemd-user / script 三种后端
│   └── dev/                # 开发自检脚本（check-*）
├── resources/
│   ├── bin/                # 离线内核/工具包（mihomo、clash、yq、subconverter）
│   ├── geo/                # GEO 数据（Country.mmdb 等）
│   ├── dashboard/          # Web 控制台前端（zashboard dist.zip）
│   └── shell.png / ui.png
└── runtime/                # ⚠️ 运行时目录（动态生成，不纳入版本库）
    ├── bin/                # 内核二进制
    ├── config.yaml         # 编译产出的最终运行配置
    ├── subscriptions/      # 订阅文件存放
    ├── subscriptions.yaml  # 订阅状态清单
    ├── mixin.yaml          # 运行补丁（实际生效处）
    ├── dashboard/          # 解压后的前端
    ├── logs/               # 日志
    └── tmp/                # 构建中间文件
```

官方给出的理解模型：

- **Control 层**（用户入口）：`clash` / `clashon` / `clashoff` / `status` / `doctor` / `ui` / `select`
- **Build 层**（配置生成）：多订阅保存 → 单一 active 主订阅 → **active-only 编译链**（`generate_config` 只处理当前 active 订阅）→ 下载/转换/校验 → 应用 `runtime/mixin.yaml` 补丁 → 输出 `runtime/config.yaml`
- **Runtime 层**（运行容器）：内核、运行配置、订阅状态、dashboard、日志、中间文件全部动态生成，**不属于仓库内容**。

## 4. 命令速查

安装后可用 `clash`、`clashon`、`clashoff` 等入口；旧入口 `clashctl`、`clashsecret`、`clashsub`、`clashtun`、`clashtest` 保留兼容。

### 日常常用

| 命令 | 作用 |
| --- | --- |
| `clashon` | 🚀 开启代理 |
| `clashoff` | ⛔ 关闭代理 |
| `clash select` | 💫 编号交互选择策略组和节点 |
| `clash mode` / `clash mode global|rule|direct` | 🧭 查看/切换路由模式 |
| `clash test` / `clashtest ["节点选择"]` | 🌐 测试当前策略组节点访问 Google / YouTube（不切节点，不可达返回非零） |
| `clashui` | 🕹️ 显示 Web 控制台地址、密钥、内网/公网入口 |
| `clash status` | 🔍 状态总览 |
| `clash doctor` | 🩺 诊断面板（排障首选） |
| `clash log` / `clash logs` | 📜 查看日志 |

### 订阅管理

| 命令 | 作用 |
| --- | --- |
| `clash add <链接> <名称>` | ➕ 添加订阅（支持 Clash YAML / Base64 / vmess / vless / trojan / tuic / hysteria2 / hy2 / anytls 分享链接） |
| `clash add local` | ➕ 从 `runtime/subscriptions/` 交互导入本地文件（等价 `clash add "file://$PROJECT_DIR/runtime/subscriptions/clash.yaml"`） |
| `clash add "file:///绝对路径/x.yaml" 名称` | 直接导入本地绝对路径 |
| `clash use` | 💱 切换当前主订阅 |
| `clash ls` | 📜 订阅列表 |
| `clash sub list` / `update` / `enable <名>` / `disable <名>` / `rename <旧> <新>` / `remove <名>` | 📡 订阅高级管理 |
| `clash config show` | 📡 查看当前生效订阅 |
| `clash config regen` | 🧩 重新编译运行配置 |

### 系统配置

| 命令 | 作用 |
| --- | --- |
| `clash secret` / `clash secret 123`（`clashsecret` 同） | 🔑 查看 / 设置控制器密钥（设置后重启生效） |
| `clash lan on|off|status` | 🏠 局域网代理（默认已开：`allow-lan: true` + controller 绑 `0.0.0.0`） |
| `clash ipv6 on|off|auto|status` | 🌐 内核 IPv6 + DNS AAAA 管理（IPv6-only 节点必备） |
| `clash tun on|off|on-proxy-off|off-proxy-on` | 🧪 Tun 透明接管模式 |
| `clash tun doctor` / `clash tun logs` | 🩺 Tun 诊断 / 日志 |
| `clash boot on|off|status` | 🚦 开机接管总开关（内核自启 + 代理持久块） |
| `clash boot runtime on|off|status` | 🚦 仅内核开机自启（systemd / systemd-user；script 后端 unsupported） |
| `clash boot proxy on|off|status` | 📜 仅 `/etc/environment` 代理持久块 |
| `clash mixin` / `edit` / `raw` / `runtime` | 🧩 查看模板 / 编辑补丁 / 查看补丁原文 / 查看最终运行配置 |
| `clash relay add <名> <节点A> <节点B> [--domain 域名|--match]` / `list` / `remove` | 🔗 多跳节点（relay 策略组串联，节点名须与订阅完全一致） |
| `clash config kernel mihomo|clash` | 🧩 切换内核 |
| `clash upgrade [mihomo|clash]` | 🚀 升级当前或指定内核 |
| `clash update` | 🔄 更新项目代码与运行依赖 |
| `clash completion bash|zsh` | 💡 导出 Shell 补全脚本 |
| `clash dev reset` | 🧪 恢复到安装前状态（保留项目目录和已下载文件） |

## 5. 配置详解

### `.env`（安装/运行参数）

```bash
KERNEL_TYPE=mihomo                    # mihomo | clash
MIXED_PORT=7890                       # 混合端口
EXTERNAL_CONTROLLER=0.0.0.0:9090      # 控制端口
CLASH_DNS_PORT=1053                   # DNS 端口
CLASH_CONTROLLER_SECRET=              # 控制器密钥（默认自动生成）
CLASH_SUBSCRIPTION_URL=               # 订阅地址（首次安装可留空，装完 clash add）
CLASH_AUTO_UPDATE_SUBSCRIPTIONS=true
CLASH_SHELL_AUTO_RESTORE_PROXY=true   # 登录 Shell 自动恢复代理变量（SSH 登录也触发）
CLASH_IPV6=auto                       # true | false | auto
CLASH_SUBSCRIPTION_UA=clash-verge/v2.4.0   # 订阅拉取 UA（让服务商返回 HY2/AnyTLS 等现代协议）
MIHOMO_VERSION=v1.19.23
CLASH_VERSION=v1.18.0
YQ_VERSION=v4.52.4
SUBCONVERTER_VERSION=v0.9.9
CLASH_BUNDLED_ASSET_ENABLED=true      # 是否优先使用 resources/bin 内置依赖
CLASH_BUNDLED_ASSET_DIR=              # 项目外资源目录
CLASH_OFFLINE=false
CLASH_PREDOWNLOAD_GEO=true            # 安装期预下载 GEO 数据
CLASH_GH_PROXY=                       # 自定义 GitHub 加速前缀（优先于内置镜像池）
CLASH_GH_PROXY_POOL=                  # 自定义镜像池（label|prefix|mode，mode: full/hostpath）
```

要点：
- GitHub 资源下载内置镜像池（`gh-proxy.org`、`ghfast.top`、`ghproxy.net`、`kkgithub.com`）自动加速，无需配置；镜像使用状态 `clash doctor` 可查。
- 正式支持架构仅 `amd64`、`arm64`、`armv7`，超出明确失败。
- 离线分发：`bash scripts/prefetch-assets.sh --arch amd64 --kernel mihomo --output clash-assets-mihomo-amd64.tar.gz` 生成资源包（含版本清单 + SHA256SUMS），拷到目标机解压后 `bash install.sh --offline`。`--dry-run` 只列文件不下载；`--no-geo` 生成精简包。
- 严格离线时订阅也不能用远程 URL，要么暂不配订阅，要么用 `file://` 导入本地 YAML。

### 运行配置模板（config/template.yaml）

默认模板包含：`mixed-port: 7890`、`allow-lan: true`、`mode: rule`、`external-controller: 0.0.0.0:9090`、Tun 段（默认关闭）、DNS 段（fake-ip，`0.0.0.0:1053`）、空的 proxies/proxy-groups/rules。最终配置 = 订阅解析结果 + 模板 + mixin 补丁。

### Mixin 补丁（runtime/mixin.yaml，兼容 config/mixin.yaml）

三种操作：
- `override`：覆盖字段（如 `dns.enable: true`）
- `prepend`：数组项插到最前（如规则优先匹配 `DOMAIN-SUFFIX,example.com,DIRECT`）
- `append`：数组项追加到最后（如兜底 `MATCH,节点选择`）

```yaml
override:
  dns:
    enable: true
append:
  rules:
    - MATCH,节点选择
```

编辑 `clash mixin edit` 后自动重新生成配置；代理运行中会自动重启应用。多跳节点（relay）也写入这里。

## 6. 关键行为与注意点

- **端口自动检测**：`MIXED_PORT` 等被占用时自动重新分配，避免冲突。
- **密钥安全**：默认自动生成随机 Secret；`clashui` 会展示。控制台暴露公网时建议定期换密钥或走 SSH 端口转发。
- **LAN 默认开启**：运行配置强制写 `allow-lan: true` 且 controller 绑 `0.0.0.0`，防止订阅里的 `allow-lan: false` 覆盖；设备代理设 `http://<本机IP>:7890`，不通先查防火墙。
- **WSL / 普通用户降级**：无权写 `/etc/environment` 时 `clashon` 自动降级——运行时照常启动、当前 Shell 代理变量生效，但系统级持久接管与开机代理不可用。
- **Tun 模式**：`tun on` 只开 Tun 不动系统代理；要"Tun 接管 + 关系统代理"用 `clash tun on-proxy-off`，恢复用 `clash tun off-proxy-on`。`doctor` 会检测 Tun 与系统代理是否同时开启（重复接管），并提示。Tun 诊断不会把 root 直接等同 CAP_NET_ADMIN，会结合后端、容器环境、进程能力、Tun adapter、策略路由、路由表与日志综合判断。
- **IPv6 / Hysteria2**：IPv6-only 节点需 `clash config kernel mihomo` + `clash ipv6 on`（同时写 `ipv6: true` 与 `dns.ipv6: true`）；宿主仍需有 IPv6 默认路由，HY2 走 UDP/QUIC 需放行 UDP。
- **连通性测试**：`clash test` 默认测当前路由模式对应策略组的选择节点访问 Google / YouTube 并显示延迟；不切换节点；任一目标不可达返回非零状态，适合脚本判断。
- **global 模式**：走 `GLOBAL` 策略组当前选择，要调整先 `clash select`。
- **UI 找不到节点**：多为厂商订阅是 Base64 编码且格式不合规；本项目已集成自动识别转换，仍不行需自建或第三方转换（有泄露风险）。
- **`RULE-SET` 报错**：`error: unsupported rule type RULE-SET`，见 [Clash WIKI FAQ](https://github.com/Dreamacro/clash/wiki/FAQ#error-unsupported-rule-type-rule-set)。

## 7. 卸载

```bash
bash uninstall.sh                      # 完整卸载：停内核、关系统代理持久接管、删 systemd/脚本入口、补全、alias、密钥、运行目录
bash uninstall.sh --keep-runtime       # 只移除入口，保留 runtime/ 数据
bash uninstall.sh --dev-reset          # 只清安装状态，保留订阅与下载缓存（调试用）
bash uninstall.sh --remove-project     # 完整卸载 + 项目目录移到 ~/.local/share/clash-for-linux-backups/（需确认路径，非交互加 --yes）
```

`--purge-runtime` 是旧兼容别名（默认卸载已清理运行目录）。

## 8. 手动设置系统级透明代理（iptables 方案）

```bash
# 1. 开启 IP 转发
echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf && sysctl -p

# 2. 配置 iptables（先清旧规则，放行本机访问代理端口，其余 TCP 全部重定向到 7892）
iptables -t nat -F
iptables -t nat -A OUTPUT -p tcp --dport 7890 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 7891 -j RETURN
iptables -t nat -A OUTPUT -p tcp --dport 7892 -j RETURN
iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports 7892
iptables-save | tee /etc/iptables.rules

# 3. 开机生效（/etc/rc.local 加 iptables-restore < /etc/iptables.rules，chmod +x）
```

## 9. 相关项目

- [clash](https://clash.wiki/) / [mihomo](https://github.com/MetaCubeX/mihomo) — 内核
- [subconverter](https://github.com/asdlokj1qpi233/subconverter) — 订阅转换
- [zashboard](https://github.com/Zephyruso/zashboard) — 默认 Web 控制台前端
- [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) — 交互风格参考项目
