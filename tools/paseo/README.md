# Paseo 使用指南

Paseo 在主机上运行编码代理，通过桌面、手机、网页或 CLI 管理同一组工作区与会话。适合远程使用服务器上的 Codex 等工具、查看任务进度和继续对话。产品入口见 [Paseo 官网](https://paseo.sh/)。

> 2026-10-10：本机已升级 **0.11.2**，Web UI 通过 systemd + Caddy 部署于 <https://cli.20070809.xyz>，替代 CloudCLI。当前部署、密码登录与模型列表见 [Web UI 部署说明](web-ui.md)。下文保留 2026-09-08 的 **0.7.2** CLI 与 YOLO 配置实践，命令以当前 `--help` 为准。

## 安装与连接

先安装并登录需要使用的代理 CLI，确认它能在主机上独立运行。Paseo 负责管理代理，模型账号与认证仍需单独准备。

```bash
npm install -g @getpaseo/cli
paseo --version
paseo onboard
```

`onboard` 初始化配置、启动 daemon 并提供配对指引。按提示选择 relay，或使用自己的直连网络。以后查看状态、再次显示配对信息：

```bash
paseo status
paseo daemon pair
```

桌面应用也可以直接安装，附带并自动启动 daemon。安装与连接方式见 [官方入门文档](https://paseo.sh/docs)。

## 两种使用方式

| 方式 | 操作对象 | Codex 权限设置 |
|---|---|---|
| Paseo 工作区终端中的 Codex 启动配置 | 终端里的 Codex CLI | `daemon.terminalProfiles` 中的启动参数，例如 `--yolo` |
| Paseo 内置 Codex 代理会话 | Paseo 管理的代理，使用 Codex app-server 集成 | 会话的 `Full Access` 模式，CLI 标识为 `full-access` |

两者配置分别生效。修改终端启动参数不会切换内置代理会话的权限模式。

## 常用命令

以下命令按本机 0.7.2 的 `--help` 整理；完整说明见 [官方 CLI 文档](https://paseo.sh/docs/cli)。`<id>` 等占位符需要替换成实际值。

### Daemon 与代理诊断

```bash
paseo start
paseo status
paseo reload --json
paseo restart

paseo provider ls
paseo provider models codex
paseo provider diagnostic codex --json
```

`reload` 重新读取配置；检查返回的 `appliedPaths` 和 `restartRequiredPaths`，判断哪些设置已经生效、哪些需要重启。`restart` 会重启 daemon，操作前留意正在进行的任务。

代理找不到命令、版本与终端不一致时，优先使用 `provider diagnostic` 检查 daemon 实际使用的环境与可执行文件。

### 创建与继续任务

```bash
# 在指定目录启动 Codex 任务
paseo run --provider codex --cwd /path/to/repo "解释这个项目的目录结构"

# 后台启动，命令立即返回
paseo run --provider codex --background "检查当前改动"

paseo ls
paseo inspect <id>
paseo attach <id>
paseo logs <id>
paseo send <id> "继续处理刚才发现的问题"
paseo wait <id>
paseo stop <id>
```

`stop` 中断正在执行的任务，不删除会话。`send` 会向已有会话发送新任务或补充要求。

### 内置 Codex 会话的 Full Access

```bash
# 新会话
paseo run --provider codex --mode full-access "处理当前项目的任务"

# 查询已有会话支持的模式，再切换
paseo agent mode <id> --list
paseo agent mode <id> full-access
```

也可以在 Paseo 界面把会话权限切换为 **Full Access**。本机安装的 provider 实现将其映射为 `approvalPolicy: "never"` 和 `sandbox: "danger-full-access"`，即不要求额外审批、不使用 Codex 沙箱限制。

## 配置文件与热加载

默认配置目录为 `~/.paseo`；指定 `PASEO_HOME` 时以对应目录为准。

| 路径 | 用途 |
|---|---|
| `~/.paseo/config.json` | daemon、应用与功能配置 |
| `~/.paseo/daemon.log` | 本机 daemon 日志 |

修改前先备份：

```bash
cp ~/.paseo/config.json ~/.paseo/config.json.bak-$(date +%Y%m%d-%H%M%S)
```

### Codex 终端默认启用 YOLO

在 `config.json` 的 `daemon.terminalProfiles` 数组里，找到 `id` 为 `codex` 的条目，将参数设置为：

```json
{
  "id": "codex",
  "name": "Codex",
  "command": "codex",
  "args": ["--yolo", "{{{prompt}}}"],
  "icon": "codex"
}
```

这是数组中的单个条目，不是完整配置文件。保留其他终端条目和已有设置，`{{{prompt}}}` 占位符也保留原样。

修改后检查 JSON 并热加载：

```bash
python3 -m json.tool ~/.paseo/config.json >/dev/null
paseo reload --json
```

本机此次返回：

```json
{
  "appliedPaths": ["daemon.terminalProfiles"],
  "restartRequiredPaths": [],
  "overrideControlledPaths": []
}
```

重新通过该配置打开 Codex 终端即可使用新参数。已经运行的 Codex 进程不会因热加载而改变启动参数。回退时移除 `--yolo`，再次热加载并打开新终端。

## 排障：终端别名生效，Paseo 中却没进入 YOLO

### 本次现象与处理结果

本机 `~/.bashrc` 中已有：

```bash
alias codex='codex --yolo'
```

但 Paseo 的 Codex 终端配置只有 `"args": ["{{{prompt}}}"]`，没有显式传入 `--yolo`。2026-09-08 将参数加入该配置并热加载后，用户确认可以正常使用。

### 为什么不能依赖 `.bashrc` 的 alias

别名是 shell 内部的命令替换规则，不是可执行文件，也不会像环境变量一样传给子进程。启动程序如果直接执行 `codex`，就不会应用 Bash 的别名。

还需要区分以下条件：

1. 启动链路是否经过 Bash，以及 Bash 是否读取了 `~/.bashrc`。非交互式 Bash 通常不会自动读取它。
2. 即使显式读取，文件是否提前返回。本机文件开头存在下面的交互检查。
3. 是否启用别名展开。非交互式 Bash 默认不展开别名。

```bash
case $- in
  *i*) ;;
    *) return;;
esac
```

`$-` 包含当前 shell 的选项标志；包含 `i` 表示交互式 shell。上面的代码表示：交互式会话继续读取，否则停止执行当前文件，后面的 alias 也就不会加载。

因此，不能仅凭这段代码就断言 Paseo 一定是“读取 `.bashrc` 后提前退出”：它也可能没有读取该文件，或根本没有通过 Bash 启动。此次有效修复是将所需参数直接写进 Paseo 的终端配置。

### 排查顺序

1. 确认使用的是工作区终端，还是内置代理会话。
2. 终端模式检查 `terminalProfiles` 的 `codex` 条目及 `--yolo`；内置会话检查 `paseo agent mode <id> --list` 和界面中的当前模式。
3. 配置修改后检查 `paseo reload --json` 返回值，并重新打开对应终端。
4. 命令或版本异常时运行 `paseo provider diagnostic codex --json`；再结合 `~/.paseo/daemon.log` 检查错误。

## 使用情况列表

使用情况列表由 0.11.2 内置的 usage-source 插件提供，与 `config.json` 无关。插件清单见安装包 `@getpaseo/server/dist/server/server/plugins/builtin/index.js`：Claude、Codex、Copilot、Cursor、Grok、Kimi、MiniMax、opencode-go、Z.ai。插件在 daemon 启动时扫描本机凭据，找到才显示对应条目，因此列表可能出现未主动配置的服务。

| 条目 | 凭据查找顺序 |
|---|---|
| GitHub Copilot | 环境变量 `COPILOT_TOKEN`、`GITHUB_TOKEN`、`GITHUB_PAT`，然后 `~/.config/gh/hosts.yml` |
| MiniMax | 环境变量 `MINIMAX_API_KEY`，然后 `~/.mmx/credentials.json`、`~/.mmx/config.json` |
| OpenCode Go | `$XDG_DATA_HOME/opencode/auth.json`；未设置时为 `~/.local/share/opencode/auth.json`，读取 `opencode-go` 下的 `type: "api"` 和 `key` |

本机情况（2026-10-15）：

- Copilot 来自 `gh` CLI 登录留下的 `~/.config/gh/hosts.yml`，没有 Copilot 订阅也会被识别。为保留 `gh` 登录，未处理。
- MiniMax 来自已卸载的 `mmx` CLI 遗留的 `~/.mmx/config.json`。卸载程序不会删除配置目录；删除 `~/.mmx` 并 `paseo restart` 后不再识别。

去掉某个条目时，删除或移走对应凭据，再执行 `paseo restart`。插件只在启动时扫描，`reload` 不会重新发现账号。

### OpenCode 2 更新 Key 后，Go 用量仍无法显示

2026-10-18 本机验证：**Paseo 0.11.2 + OpenCode 2.0.28** 存在凭据存储兼容问题。OpenCode 2 将凭据写入 `~/.local/share/opencode/opencode.db` 的 `credential` 表，Paseo 的 Go 用量插件仍只读取旧的 `auth.json`，不会读取数据库，也不会使用 `OPENCODE_API_KEY` 环境变量。

此次旧文件的修改时间停在 2026-08-19。旧 Key 请求 `https://opencode.ai/zen/go/v1/usage` 返回 `401 / api_key_expired`；数据库内当前启用的新 Key 请求同一接口返回 `200`。因此，即使 `/connect` 已更新成功，Paseo 仍会使用过期的 Key。仅重启 Paseo 无法解决文件内容过旧的问题。

排查时先确认 Paseo 服务的运行用户、`HOME` 和 `XDG_DATA_HOME`，再比较旧文件的修改时间与数据库中当前启用的凭据。不要只根据 `auth.json` 的返回结果判断 OpenCode 当前登录是否有效。接口明确返回 `api_key_expired` 时需要在 OpenCode Console 创建新 Key；重新登录不会续期旧 Key。

临时处理：将数据库中当前启用的 Go Key 同步到旧格式文件。下面脚本适用于上述已验证版本，使用当前用户的数据目录，保留其他服务的凭据，备份原文件，并以仅当前用户可读写的权限原子替换文件。以与 Paseo 相同的用户和数据目录执行；不要用 `sudo` 切换到 root，也不要将 Key 或备份提交到仓库。

```bash
python3 - <<'PY'
import json
import os
import sqlite3
import tempfile
from datetime import datetime, timezone
from pathlib import Path

data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "opencode"
auth = data / "auth.json"
db = sqlite3.connect((data / "opencode.db").as_uri() + "?mode=ro", uri=True)
try:
    rows = db.execute(
        "SELECT value FROM credential WHERE integration_id = ? AND active = 1",
        ("opencode-go",),
    ).fetchall()
finally:
    db.close()
if len(rows) != 1:
    raise SystemExit("需要且只能有一个启用的 OpenCode Go 凭据，请先在 OpenCode 中确认当前账号")
credential = json.loads(rows[0][0])
if credential.get("type") != "key" or not isinstance(credential.get("key"), str) or not credential["key"]:
    raise SystemExit("凭据格式与已验证版本不同，停止同步")
original = auth.read_bytes() if auth.exists() else None
content = json.loads(original) if original is not None else {}
content["opencode-go"] = {"type": "api", "key": credential["key"]}
if original is not None:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = auth.with_name(f"auth.json.bak-{stamp}")
    with os.fdopen(os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as f:
        f.write(original)
    print("原文件已备份至", backup)
fd, temporary = tempfile.mkstemp(prefix=".auth-", dir=data)
try:
    with os.fdopen(fd, "w") as f:
        json.dump(content, f, indent=2)
        f.write("\n")
    os.replace(temporary, auth)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
print("已同步当前 OpenCode Go Key，未输出凭据内容")
PY
```

同步后刷新 Paseo 用量页面。本机以插件相同的 Node.js `fetch` 请求方式验证，兼容文件中的 Key 已返回 `200`。插件每次获取用量都会重新读取文件，因此已有 Go 条目无需为更换 Key 重启；如果此前没有对应条目，需重启以重新发现账号。此次 Python 默认 User-Agent 请求曾被 Cloudflare 返回 `403 / browser_signature_banned`，应区分该访问拦截与 API Key 认证失败。

这是一次性兼容处理；以后更换 Key 或切换 Go 账号仍需同步，直到 Paseo 支持 OpenCode 2 的凭据存储。升级版本后先检查插件实现，勿假设上述数据库结构和同步步骤始终适用。备份同样包含敏感凭据，确认恢复后可删除不再需要的备份。

## 参考入口

- [Paseo 官方文档](https://paseo.sh/docs)
- [Paseo CLI 参考](https://paseo.sh/docs/cli)
- [Paseo 源码](https://github.com/getpaseo/paseo)
- [仓库内 Codex 文档](../codex/README.md)

本机验证依据：Paseo 0.7.2 CLI 帮助、安装包内 Codex provider 的模式映射、`config.json` 的终端配置、热加载结果，以及修复后的用户反馈。
