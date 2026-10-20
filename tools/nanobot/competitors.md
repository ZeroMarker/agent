# Nanobot 竞品整理

整理日期：2026-10-20。对象为 [HKUDS/nanobot](https://github.com/HKUDS/nanobot)。

范围：能通过聊天入口执行工具、保留状态并长期运行的自托管个人 AI 助手。以下依据官方仓库和文档整理，未安装实测；功能描述以核查时默认分支为准，不代表所有稳定发行版均已具备。选型建议是基于产品定位的判断，不是性能或稳定性排名。

## 先看结论

- **优先对标 OpenClaw、ZeroClaw、AstrBot**：分别代表跨设备助手、原生编译运行时、国内 IM 机器人平台三条路线。
- **低资源设备看 PicoClaw、NullClaw**：重点核查目标架构、实际启用功能和完整进程树的开销。
- **重视不同 Agent 的执行隔离看 NanoClaw**：容器、工作目录和凭证代理是主要区别。
- **只想从微信调用已有编码代理看 WeClaw**：它是桥接层，也可以和 nanobot 组合使用。

## Nanobot 的比较基准

Nanobot 是 Python 自托管个人 Agent，提供浏览器、终端和 IM 入口，结合文件与 Shell 工具、MCP、长期记忆、定时自动化及多 Agent 委派。它的吸引力是可读、可改的 Python 栈与一体化助手体验；“轻量”并不等于只有聊天转发功能。[官方介绍](https://github.com/HKUDS/nanobot#readme)

本仓库已有 [nanobot 使用指南](README.md)，其中记录 v0.3.5；这是已有部署文档的版本记录，不能当作上游最新版本。

## 竞品总览

表内“适合场景”和“取舍”为选型判断，其余产品能力可由同行官方链接核查。

| 产品 | 类型／主要技术 | 相对 nanobot 的侧重点 | 适合场景 | 取舍与核查项 |
|---|---|---|---|---|
| [OpenClaw](https://github.com/openclaw/openclaw) | 直接竞品；Node.js／TypeScript | Gateway、渠道、工具／Skills／插件，以及设备端应用与节点能力 | 想把个人助手延伸到多个设备和聊天入口 | 部署时需理解网关、节点与插件配置；主会话工具默认在宿主执行，沙箱需配置 |
| [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) | 直接竞品；Rust | 单二进制运行时、可替换组件、操作审批、系统级沙箱及 SOP 自动化 | 常驻服务、需要明确执行策略或事件触发流程 | 深度定制转向 Rust；具体渠道和工具需核对安装包的编译选项 |
| [PicoClaw](https://github.com/sipeed/picoclaw) | 直接竞品；Go | 低资源设备部署、跨平台二进制，同时提供 WebUI、MCP 和定时任务 | ARM／RISC-V 小主机、希望控制运行时开销 | 上游注明处于快速开发阶段；低内存宣传值不能代替完整工作负载测试 |
| [NanoClaw](https://github.com/nanocoai/nanoclaw) | 直接竞品；Node.js／TypeScript + 容器 | 每个 Agent 的容器、工作目录和记忆边界，凭证网关；以 Claude Agent SDK 为主要执行路线 | 希望隔离不同助手的文件与执行环境 | 需维护容器和凭证代理；其他 Provider／渠道按 Skills 引入，不能假设默认全部安装 |
| [NullClaw](https://github.com/nullclaw/nullclaw) | 直接竞品；Zig | 小型原生运行时、可替换记忆后端、多种沙箱与硬件接口 | 对二进制体积敏感、愿意维护 Zig 栈的边缘部署 | 源码构建要求特定 Zig 版本；目标平台与依赖仍需核对 |
| [AstrBot](https://github.com/AstrBotDevs/AstrBot) | 场景竞品；Python | IM 接入、插件市场、知识库、人设及可视化管理，也提供 Agent／MCP／Skills／沙箱 | QQ 群、企业微信、飞书、公众号等聊天机器人与知识助手 | 插件与平台适配器是部署的重要组成；群聊管理与个人工作空间自动化应分别验收 |
| [WeClaw](https://github.com/fastclaw-ai/weclaw) | 局部替代／互补；Go | 微信通过 ACP、CLI、HTTP 调用已有 Agent | 已有 Claude／Codex 等代理，只缺微信入口 | 执行、记忆和任务能力主要取决于后端；README 标注仅个人学习、非商业用途 |

## 按关键差异比较

### 1. 多入口与设备能力：OpenClaw

OpenClaw 将 Gateway、聊天渠道、控制界面和设备节点组织在同一套助手架构里。若需求涉及语音、摄像头、屏幕和设备本地动作，值得优先研究其应用与节点方案。是否采用仍应取决于目标设备实际支持的能力。[架构与入口](https://github.com/openclaw/openclaw#how-it-fits-together)

### 2. 原生运行时与执行策略：ZeroClaw

ZeroClaw 提供多渠道、多模型、工具、Web dashboard 和事件触发 SOP；官方说明默认采用 supervised 自主性策略，并提供审批、工作空间边界和多种沙箱后端。与 nanobot 比较时，重点看配置策略能否覆盖实际操作，而非只比较实现语言。[功能与安全说明](https://github.com/zeroclaw-labs/zeroclaw#readme)

### 3. 资源占用：PicoClaw、NullClaw

PicoClaw 的重点是 Go 运行时与低成本硬件；官方同时说明近期构建可能使用 10–20 MB 内存，不能只引用标题中的低于 10 MB。NullClaw 宣传约 678 KB 二进制与约 1 MB RAM，这些属于上游自述，本文未复测。[PicoClaw 说明](https://github.com/sipeed/picoclaw#readme)、[NullClaw 说明](https://github.com/nullclaw/nullclaw#readme)

比较时应固定同一模型 API、任务与渠道，统计网关、WebUI、MCP 子进程、浏览器和容器的总资源。使用远程模型时，小运行时也不意味着可以在相同内存内本地运行大模型。

### 4. Agent 隔离：NanoClaw

NanoClaw 把执行放在容器中，并提供按 Agent 的工作目录、记忆边界和凭证网关。它适合用来比较“不同助手能看到什么、能执行什么”；实际隔离效果仍受挂载目录、网络与代理策略影响。[隔离模型](https://github.com/nanocoai/nanoclaw/blob/main/docs/isolation-model.md)、[项目说明](https://github.com/nanocoai/nanoclaw#readme)

旧地址 `qwibitai/nanoclaw` 已跳转至 `nanocoai/nanoclaw`，检索与收藏优先使用新地址。

### 5. 国内聊天平台：AstrBot、WeClaw

AstrBot 将国内 IM 接入、插件、知识库和人设作为显著能力，适合与 nanobot 的 QQ／飞书等渠道做场景对比。WeClaw 则负责把微信消息转给已有 Agent，适合补入口。[AstrBot 功能介绍](https://github.com/AstrBotDevs/AstrBot#key-features)、[WeClaw 工作方式](https://github.com/fastclaw-ai/weclaw#how-it-works)

接入时要分别确认 QQ 官方机器人与 OneBot、个人微信与企业微信／公众号；“支持 QQ／微信”不足以说明接口、群聊权限、附件或主动推送能力相同。

## 结合本仓库的选型顺序

仓库已记录 nanobot、ZeroClaw 和 WeClaw 的使用方式。基于这些现有文档，建议按需求验证：

| 当前需求 | 优先比较 | 验证重点 |
|---|---|---|
| 延续现有 QQ 个人助手 | Nanobot ↔ AstrBot | 多轮上下文、群聊触发、附件、插件与定时消息 |
| 常驻网关与操作权限控制 | Nanobot ↔ ZeroClaw | 审批、路径权限、沙箱、服务重启及任务恢复 |
| 跨设备个人助手 | Nanobot ↔ OpenClaw | 目标设备节点、语音／屏幕能力和远程连接 |
| 小内存设备 | Nanobot ↔ PicoClaw／NullClaw | 目标 CPU 支持、完整资源开销及功能裁剪 |
| 多个助手之间隔离 | Nanobot ↔ NanoClaw | 文件可见性、记忆边界、凭证与容器生命周期 |
| 微信调用现有编码代理 | WeClaw + 现有后端 | 后端会话恢复、工作目录、消息格式和权限交互 |

可用一组共同任务做小规模验证：文件总结与修改、带历史的多轮对话、重启后的记忆读取、定时任务投递、附件收发、越界文件访问。记录完成率、人工介入次数、模型费用和资源峰值，再决定是否迁移。

## 不作为直接竞品的类别

- **编码代理**：主要围绕代码仓库与开发任务，可作为桥接工具的后端，但不天然等同于长期运行的多渠道个人助手。
- **通用 Agent 开发框架**：更偏开发底座，需要自行组装渠道、状态和运维能力。
- **工作流／聊天应用平台**：与知识助手和自动化有重合，若目标是流程编排或团队应用，应另开对比。

本文没有做付费套餐、许可证兼容性或生产稳定性评估；这些需要在确定部署方式与用途后另行核查。
