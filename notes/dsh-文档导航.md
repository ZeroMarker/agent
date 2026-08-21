# DeepSeek Harness 文档导航（整理版）

> 基于 `deepseek-ai/deepseek-harness` @ `dsh-0.1.0-rc.8`（开发者预览版）整理
> 仓库：<https://github.com/deepseek-ai/deepseek-harness>（本文是基于该仓库 docs/ 的导航整理，本地未保留源码克隆，以线上仓库为准）

---

## 1. 文档总体情况

| 项目 | 说明 |
|---|---|
| 规模 | `docs/` 下约 150+ 文档文件 |
| 语言 | 中英双语成对维护：`foo.md`（英）+ `foo.zh.md`（中）+ `foo.i18n.yaml`（一致性记录），双语同等权威 |
| 生成机制 | 部分文档由 `scripts/gen-doc-graphs.ts` 自动生成（含 mermaid/flowchart 图表），手改会被覆盖；用 `pnpm run verify-doc-graphs` 校验 |
| 类型文档 | 子系统页中的类型声明与源码等价，由 `pnpm run verify-type-equiv` 漂移检查 |
| 约定 | `docs/i18n/` 定义了翻译规则与术语表（`terminology.md` 为术语唯一权威） |

---

## 2. 文档地图（先看这里）

| 文档 | 作用 |
|---|---|
| `docs/graph-atlas.md` | **总索引**：列出 9 张关系图及其模式（generated / hybrid / curated），并说明各自从哪里生成 |
| `docs/module-graph.md` | 包依赖关系图（generated） |
| `docs/tool-catalog.md` | 工具 Schema 目录 + 包映射（generated） |
| `docs/capability-seams.md` | 能力缝（capability seam）与核心服务图（hybrid） |
| `docs/event-producer-consumer.md` | 事件生产者/消费者矩阵：每个事件的声明包、分发模式（`emit`/`waterfall`/`parallel`/`serial`）、调度方与监听方 |
| `docs/agent-lifecycle.md` | Agent turn/step 生命周期时序图（curated，mermaid） |
| `docs/tool-execution-pipeline.md` | 工具执行管线图（curated） |
| `apps/cli/composition.md`、`examples/{headless-agent,acp-agent}/composition.md` | 各应用的组合（composition）图（hybrid） |

---

## 3. 按角色推荐的阅读路径

### 最终用户（跑 Web UI）
1. 根目录 `README.md` → `npx @deepseek-ai/dsh web`
2. `docs/user/guide/index.md`（配置模型 → 选工作区 → 跑任务）
3. `docs/user/guide/providers.md`（各模型供应商 + 自定义 OpenAI 兼容端点）
4. `docs/user/guide/python-sdk.md`（用 Python SDK 驱动）

### 插件开发者（给 Harness 写插件）
1. `docs/user/develop/basic/index.md` —— 第一个插件（本地项目、cordis.yml、三种插件形态）
2. `docs/user/develop/framework/index.md` —— 插件与生命周期（fiber 状态机、依赖驱动加载、HMR）
3. `docs/user/develop/practice/index.md` —— 三角色能力设计（Service Definition / Provider / Consumer）
4. 配套具体主题：`basic/tool.md`（第一个工具）、`basic/config.md`、`basic/publish.md`（发布）、`practice/llm-adapter.md`（LLM 适配器）
5. 查烹饪书 `docs/cookbook/`（见 §6）

### Cordis 学习者（框架本身）
1. `docs/cordis-primer.md` —— 五句话讲清 Cordis（插件=对象、上下文=服务仓库、`inject` 声明依赖、类型化事件、可逆注册）
2. `docs/cordis-tutorial/index.md` —— 7 章动手教程（无需 API key，全部可本地跑）
3. `docs/cordis-api/` —— API 参考（context / events / fiber / registry / service）

### 贡献者 / 维护者
1. `docs/development.md` —— 环境搭建 + 贡献者参考（CI 门槛、常用命令、`ts type-equiv`）
2. `docs/testing.md` —— 测试政策（分层、with-key 政策、优先真实现）
3. `docs/i18n/README.md` —— 双语配对约定与校验
4. `AGENTS.md`（16KB，仓库根）—— 给 agent 的开发规则
5. `docs/postmortem/` —— 事故复盘（4 篇，见 §7）

---

## 4. 概念与架构级文档

| 文档 | 内容 |
|---|---|
| `docs/architecture.md` | 总架构：Cordis、Profiles/bundles、核心包、事件、Turn 流程、会话日志、能力缝、"新行为放哪里" |
| `docs/cordis-primer.md` | Cordis 五大思想、四种分发模式语义、waterfall 中间件语义、Loader 配置 |
| `docs/glossary.md` | 术语表：capability-seam、agent-scope（scope key/影子/setup 窗口/谱系）、goal、human command、loop hierarchy（turn/step/round） |
| `docs/api-gateway.md` | Typert API 网关：`@Remote`/`@RemoteScope` 声明、Host/Client 契约生成、`ctx.remote` 运行时调用 |
| `docs/defensive-patterns.md` | 防御性编程模式（正交结果独立上报、异步≠同步、dispose 必须达静默等 7 条） |
| `docs/rescope.md` | vendored 包改名（如 cordis → 内部名）的映射与迁移指南 |
| `docs/web-styling.md` | Web UI 样式规范与组件规则 |

---

## 5. 子系统参考（`docs/subsystems/`，36 页）

每页 = 一个子系统的**词汇与接线的唯一参考**：是什么、移动什么数据结构，含生成的 **Cordis API** 段（服务 + 事件引用）。与 `architecture.md`（讲跨子系统行为）互补。

| 页面 | 负责内容 |
|---|---|
| `core.md` | `packages/core` 如何控制 agent 循环、AgentHandle、turn/step 契约、全仓类型模式 |
| `llm-streaming.md` | `Message`/`ContentBlock`、StreamChunk 线上协议、BlockAssembler、LlmAdapter |
| `token-meter.md` | token 计量的不可变标量与位置回放测量 |
| `scope.md` | 作用域注册身份、分发载体、Scope 上下文 |
| `typert.md` | 远程调用描述符、lookup/Context 声明、Host 网关/Client API 边界 |
| `goal.md` | 持久化目标身份、生命周期快照、激活、轮次归属 |
| `schedule.md` | 会话内提醒记录、持久转换、投递 |
| `commands.md` | 人类命令注册表服务（`/命令`） |
| `session.md` | SessionEventMap 全目录、TurnTrigger/TurnEndReason、deriveMessages |
| `persistence.md` | 持久层：SessionPersistence、JSONL+SQLite、崩溃恢复 |
| `settings.md` | 用户设置：分层解析（默认→base→用户文档）、热提交 |
| `credentials.md` | 凭据引用（只存引用不存值）、按操作解析、多来源层 |
| `session-query.md` | 会话查询：逻辑记录、精确事件读取、全文检索分页 |
| `feedback.md` | 每条消息的反馈记录、乐观版本、旁车持久化 |
| `session-title.md` | 会话标题快照与异步生成契约 |
| `session-reference.md` | 跨会话结构化引用与错误分类 |
| `system-prompt.md` | 系统提示词组装：分区、工具结果、协作式组装 |
| `tools.md` | ToolDefinition 全字段、Schema DSL、守卫执行管线 |
| `user-questions.md` | UI 侧人类提问缝：AskUserQuestionRequest、答案词汇表 |
| `approval.md` | 一次性用户批准缝：ApprovalRequest、每会话策略、审计事件 |
| `attachment.md` | 持久化图片身份/元数据、AttachmentStore 缝 |
| `shell.md` | bash 执行器缝：ShellExecRequest/Spec、后台句柄 |
| `subprocess.md` | 子进程缝：显式 SpawnSpec、偏移读取、DSH_* 环境变量 |
| `terminal.md` | 持久终端 id、后端/会话契约、受限读取 |
| `sandbox.md` | 每会话策略解析 + 进程约束缝（landlock、fail-closed） |
| `code-runtime.md` | 代码执行缝：CodeRunRequest/Result、捕获日志、失败分类 |
| `extensions.md` | 动态 Cordis 插件/包：Host/Client 激活、审批、运行时检查 |
| `filesystem.md` | 文件系统缝：FsTarget、读/写/编辑结果、观察状态 |
| `lsp.md` | LSP 导航缝：四种操作、LspError |
| `skills.md` | 技能服务：发现优先级、SkillSummary/Definition、加载 |
| `compaction.md` | 上下文压缩缝：compaction/* 事件、CompactionEngine |
| `subagent.md` | 子代理缝：命名 provider 注册表、能力在启动时/运行时拆分 |
| `agent-team.md` | Agent 团队：隐式 Lead、可续接队友、持久邮箱、任务 DAG |
| `web.md` | Web 访问缝：WebSearch/WebFetch、provider 可用性 |
| `spill.md` | spill 存储缝：SaveTextSpill、SpillRef、品牌化 SpillLocator |
| `workflow.md` | 工作流缝：WorkflowStartRequest/Meta/Run/Result、错误致命性 |
| `jobs.md` | 后台任务运行时：JobId、生产者契约、ctx.jobs |
| `permission-presets.md` | 权限预设层：PresetSpec/Option、派生 custom 状态 |
| `plan.md` | 计划模式：plan/mode 状态、exit_plan_mode 审查弧 |
| `invariants.md` | 运行时不变式注册表（`tools.guard()` 等） |
| `web-server.md` | HTTP 载体：WebRouteKind/WebRoute、匹配顺序、fallback 席位 |
| `storage.md` | 存储子系统：StorageBackend 契约、DomainSpec/Domain、`domain/changed` |
| `workspace.md` | 工作区注册表：Workspace/WorkspaceId、会话 cwd 关系 |
| `client-modules.md` | Web 插件表：`dsh.client` 声明、WebBootGraph 组合 |
| `session-projection.md` | 投影缝：ProjectionDefinition、一致截断快照、变更流 |
| `session-telemetry.md` | 出站会话上报缝：SessionTelemetryRecord/Sink、脱敏瀑布 |

> 注：README 表格共 46 行，以上按表列全。

---

## 6. 烹饪书（`docs/cookbook/`，扩展模式参考）

| 文档 | 内容 |
|---|---|
| `extension-cookbook.md` | **总纲**：工具插件 / hook 插件（权限门示例）/ UI 插件 / 服务插件 / 配置插件等形态速览 |
| `adding-a-tool.md` | 加一个工具（`defineTool` 注解式、JSON-Schema 直传、执行策略选择规则） |
| `adding-an-llm-adapter.md` | 加 LLM 适配器 |
| `adding-a-settings-card.md` | 加设置卡片（Web UI） |
| `adding-a-conversation-node.md` | 加会话节点（Chat 渲染器） |
| `adding-a-package.md` | 新包清单（包结构、发布准备） |
| `adding-a-vendored-package.md` | 引入 vendored 包 |
| `maintaining-dsh-code-review.md` | 维护者：代码评审流程 |
| `responding-to-pr-review-on-a-stack.md` | 开发者：栈式 PR 评审的回应 |

---

## 7. 事故复盘（`docs/postmortem/`）

写复盘的前提：bug **微妙**、**系统性**（逃逸原因在流程）且**再发现代价高**。每篇以 30 秒 Executive summary 开头。

| # | 主题 |
|---|---|
| 0001 | ACP 服务器连接崩溃：`export default` 丢掉了插件的 `inject` |
| 0002 | 字面量 `!!js` 对象导致文件系统快照工具被永久禁用 |
| 0003 | Web agent 验证了替换后的服务器而非托管其会话的 GUI |
| 0004 | Landlock 部分执行通知将子进程失败误分类 |

---

## 8. 目录类文档（catalog）

| 文档 | 内容 |
|---|---|
| `docs/tool-catalog.md` | 全部模型侧工具 Schema：`ask_user_question`、`run_code`、`exit_plan_mode`、`bash`/`pwsh`、`cordis_*`（define/inspect/run/stop/undefine）等 |
| `docs/config-catalog.md` | 全部插件配置项（`@deepseek-ai/dsh-*` 每个包的配置 schema） |
| `docs/persistence-catalog.md` | 会话持久化事件目录：`agent/*`、`approval/*`、`llm/*`、`sandbox/*`、`session/*`、`step/*` 等全部事件及信封格式 |
| `docs/event-producer-consumer.md` | 见 §2（事件矩阵） |

---

## 9. Cordis API 参考（`docs/cordis-api/`）

| 文档 | 内容 |
|---|---|
| `context.md` | Context：服务注册、effect/on、生命周期 |
| `events.md` | 事件系统：四种分发模式 |
| `fiber.md` | Fiber 状态机 |
| `registry.md` | 注册表与加载 |
| `service.md` | Service 基类与依赖注入 |
| `inherited.md` | 从 vendor 继承的未翻译参考 |

---

## 10. 仓库其他文档入口

| 位置 | 内容 |
|---|---|
| 根 `README.md` / `README.zh.md` | 项目简介 + 快速运行（npm / 源码两种方式） |
| `AGENTS.md`（根，`CLAUDE.md` 为软链） | 给 agent 的仓库级开发规则（16KB，配合 `docs/development.md`） |
| `apps/cli/README.md` | CLI 模式说明（web / headless / acp 等） |
| `apps/web/` | Web 应用源码 |
| `examples/README.md` | 6 个可运行示例：`mcp-memory`、`headless-agent`、`jsonrpc-agent`（Python SDK + JSON-RPC）、`web-cordis`（自指 agent）、`web-schedule`（提醒覆盖层）、`acp-agent`（ACP 服务端） |
| `python/README.md` | Python SDK：`sdk`（高层 turns API + JSON-RPC 客户端）、`sdk-runtime`（捆绑运行时二进制），开发见 `python/development.md` |
| `native/` | `landlock-run`（开销最小的原生放牧工具，供沙箱使用） |
| `vendor/README.md` | vendored 依赖（Cordis 源码与同步流程） |

---

## 11. 快速速查

- **启动 Web UI**：`npx @deepseek-ai/dsh web` → http://127.0.0.1:3080（`--no-open` 不弹浏览器）
- **源码运行**：`pnpm install && pnpm run build && pnpm dsh web`
- **文档校验**：`pnpm run verify-doc-graphs`（图）、`pnpm run verify-type-equiv`（类型）、`pnpm run verify-translation-pairing`（双语配对）
- **重新生成图**：`pnpm run gen-doc-graphs`
- **术语速记**：`seam`=可替换能力的完整三角色（定义/提供者/消费者）；`scope`=按 agent 注册的单位；`turn`⊃`step`（一轮输入 → 一个模型请求+其工具执行）；`round`=外层策略迭代（如 goal round）