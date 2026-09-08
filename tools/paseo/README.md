# Paseo 使用指南

Paseo 在主机上运行编码代理，通过桌面、手机、网页或 CLI 管理同一组工作区与会话。适合远程使用服务器上的 Codex 等工具、查看任务进度和继续对话。产品入口见 [Paseo 官网](https://paseo.sh/)。

> 整理日期：2026-09-08。命令按本机 `paseo --version` 输出的 **0.7.2** 及 CLI 帮助核对；本机实践与通用说明分别标注。

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

## 参考入口

- [Paseo 官方文档](https://paseo.sh/docs)
- [Paseo CLI 参考](https://paseo.sh/docs/cli)
- [Paseo 源码](https://github.com/getpaseo/paseo)
- [仓库内 Codex 文档](../codex/README.md)

本机验证依据：Paseo 0.7.2 CLI 帮助、安装包内 Codex provider 的模式映射、`config.json` 的终端配置、热加载结果，以及修复后的用户反馈。
