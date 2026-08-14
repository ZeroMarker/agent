# 基于 Agent Harness 的 LangGraph 集群设计

## 1. 背景

当前实现将 Research、Coding、Review 作为同一模型的连续文本调用。它可以演示工作流，但还不是具备实际执行能力的 Agent 集群：

- Agent 没有独立工作目录和生命周期；
- Research 没有资料检索工具；
- Coding 只能生成修改建议，不能操作仓库；
- Review 审查模型描述，而不是真实 Git diff；
- 所有角色共享大段上下文，成本高且容易互相强化错误；
- 缺少任务持久化、失败恢复、权限控制和用户审批。

本方案将 LangGraph 作为控制面，将 Agent Harness 作为执行单元。每个 Harness 拥有独立上下文、工具、工作区、运行循环和结果协议。

## 2. 设计目标

1. Agent 能够读取、修改并验证真实项目。
2. 多个 Agent 可以安全并行执行，避免相互覆盖。
3. 用户能够实时查看状态、追加约束、回答问题和审批外部操作。
4. 任务在进程异常后可以从 checkpoint 恢复。
5. 每项修改能够追溯到 Agent、任务、来源、Git commit 和检查结果。
6. 模型负责决策，Harness 负责权限、执行、隔离和记录。

## 3. 总体架构

```text
用户
 ├── CLI
 ├── Web Console
 └── REST API / SSE
          │
          ▼
┌──────────────────────────────┐
│ LangGraph Orchestrator       │
│ 任务拆分、调度、状态、审批    │
└──────────────┬───────────────┘
               │
      ┌────────┴────────┐
      ▼                 ▼
Research Harness   Repo Audit Harness
      └────────┬────────┘
               ▼
         Planner Harness
               │
      ┌────────┼─────────┐
      ▼        ▼         ▼
 China Worker US Worker Docs Worker
      └────────┼─────────┘
               ▼
          Test Harness
               ▼
         Review Harness
         │            │
       通过           退回
         ▼            │
         Merge Harness◀┘
```

LangGraph 负责控制流，不直接承担文件操作。每个 Agent 节点调用一个 Harness；Harness 可以在内部运行完整的工具调用循环。

## 4. Harness 定义

每个 Harness 至少包含以下能力：

- 独立系统提示词和模型配置；
- 独立 Git worktree；
- 明确的文件所有权范围；
- 受限工具集合；
- 最大执行步数、超时和预算；
- 结构化输入输出；
- 工具调用和模型调用日志；
- 可取消、重试和恢复的生命周期；
- 产出本地 commit，而不是只返回“已修改”的文字描述。

建议的基础接口：

```python
class HarnessResult(TypedDict):
    agent_id: str
    task_id: str
    status: Literal["completed", "failed", "blocked"]
    worktree: str
    commit_sha: str | None
    changed_files: list[str]
    sources: list[SourceRecord]
    checks: list[CheckResult]
    findings: list[Finding]
    handoff: str
```

Harness 生命周期：

```text
CREATED → PREPARING → RUNNING → VALIDATING → COMPLETED
                         │            │
                         ├→ BLOCKED   └→ FAILED
                         └→ CANCELLED
```

## 5. Agent 角色

### Repo Audit Harness

- 扫描目录结构、语言、依赖和文档；
- 识别现有测试、规范文件和工作区状态；
- 只读，不修改项目；
- 输出可拆分的文件集合及风险信息。

### Research Harness

- 使用允许的搜索和页面读取工具；
- 保存来源标题、URL、访问时间和支持命题；
- 区分原始来源、二手来源和未核验材料；
- 不直接修改项目文件。

### Planner Harness

- 将目标拆成结构化子任务；
- 为子任务分配文件范围、依赖和验收条件；
- 标记可并行任务与串行依赖；
- 不生成没有执行者的笼统建议。

### Worker Harness

- 在独立 worktree 中读取和修改文件；
- 只能操作任务授权的路径；
- 运行相关检查并创建本地 commit；
- 返回真实 changed files 和 commit SHA。

Worker 可以按领域拆分，例如 China Law、US Law、Documentation、Code、Security 和 Test。

### Test Harness

- 合并前检查各 Worker 产物；
- 运行项目测试、格式检查和链接检查；
- 将失败精确关联到对应 commit 和任务；
- 不在未授权情况下修改业务内容。

### Review Harness

- 审查真实 diff、来源和测试结果；
- 使用结构化结论：批准、退回或阻塞；
- 退回时指定目标 Worker、文件和验收条件；
- 不以输出首行字符串作为唯一判断协议。

### Merge Harness

- 验证目标 commit 和文件范围；
- 按依赖顺序合并 Worker commit；
- 处理冲突或生成冲突任务；
- 未经授权不推送远程仓库。

## 6. 工作区隔离

每个写入型 Agent 使用独立 Git worktree：

```text
runtime/worktrees/
├── run-123-china-law/
├── run-123-us-law/
└── run-123-docs/
```

基本流程：

1. 从任务基线 commit 创建分支和 worktree；
2. Worker 只在自己的 worktree 修改；
3. Worker 完成检查后创建 commit；
4. Review 查看 commit diff；
5. Merge Harness 将批准的 commit 合入集成分支；
6. 任务结束后清理 worktree，保留日志和 commit 引用。

## 7. LangGraph 工作流

```text
START
  ↓
initialize_run
  ↓
repo_audit ─────┐
research ───────┤ 并行
                ↓
              plan
                ↓ Send(task × N)
        worker_harness × N
                ↓ fan-in
             integrate
                ↓
               test
                ↓
              review
          ┌─────┴─────┐
        approve      revise
          ↓            │
         merge ◀────────┘
          ↓
         END
```

使用 `Send` 根据 Planner 生成的任务数量动态创建 Worker。状态中的列表字段必须配置 reducer，避免并行节点相互覆盖。

建议使用 SQLite 保存本地 checkpoint，生产环境切换为 PostgreSQL。每次运行使用独立 `thread_id`。

## 8. 状态模型

```python
class ClusterState(TypedDict, total=False):
    run_id: str
    repository: str
    base_commit: str
    objective: str
    constraints: list[Constraint]
    permissions: PermissionPolicy
    tasks: list[TaskSpec]
    results: Annotated[list[HarnessResult], operator.add]
    sources: Annotated[list[SourceRecord], operator.add]
    checks: Annotated[list[CheckResult], operator.add]
    approvals: list[ApprovalRequest]
    messages: Annotated[list[RunMessage], operator.add]
    status: RunStatus
```

不要把完整仓库文本存入共享状态。状态只保存文件引用、摘要、artifact ID 和 commit SHA；Harness 按任务需要加载具体文件。

## 9. 工具和权限

推荐工具：

- `read_file`：读取授权路径；
- `search_files`：在仓库中检索；
- `apply_patch`：修改授权文件；
- `run_command`：执行白名单命令；
- `web_search`：检索资料；
- `open_url`：读取允许域名；
- `git_diff`、`git_commit`：管理本地变更；
- `report_finding`：提交结构化发现；
- `request_input`：向用户提问。

权限分级：

| 等级 | 操作 | 默认行为 |
|---|---|---|
| 自动 | 读取、搜索、运行只读检查 | 直接执行 |
| 可回滚 | 修改独立 worktree、创建本地 commit | 执行并记录 |
| 外部影响 | 合并主分支、推送、开 PR、删除文件 | 请求审批 |

Harness 执行器必须在工具层强制权限，不能只依赖系统提示词。

## 10. 用户交互

### CLI

```bash
swarm run --repo ~/case "搜集资料并优化项目"
swarm watch <run-id>
swarm status <run-id>
swarm diff <run-id>
swarm agent logs <run-id> research-cn
swarm reply <run-id> "只使用官方一级来源"
swarm approve <run-id>
swarm reject <run-id> --reason "保留现有案例"
swarm cancel <run-id>
swarm resume <run-id>
```

`watch` 示例：

```text
Run: run-123                         RUNNING

✓ repo-audit       39 files scanned
● research-cn      searching official sources
● research-us      checking Supreme Court cases
✓ planner          8 tasks generated
○ china-law        waiting
○ us-law           waiting

Tokens: 84,230   Cost: ¥0.13   Elapsed: 01:42
```

### 交互式终端

```bash
swarm chat --repo ~/case
```

用户在运行中追加的要求应转换成结构化约束：

```json
{
  "scope": ["代孕相关法律以及实操/**"],
  "source_policy": ["government", "court"],
  "prohibited_actions": ["delete_existing_cases"]
}
```

约束写入共享状态，并发送给尚未完成的相关 Harness。

### Web 控制台

建议页面：

- Runs：运行列表、状态、耗时和费用；
- Graph：当前 LangGraph 节点；
- Agents：Harness 状态和工具日志；
- Tasks：Planner 子任务；
- Sources：Research 来源；
- Changes：按 Agent 和文件展示 diff；
- Approvals：待审批操作；
- Checkpoints：恢复和回放；
- Settings：模型、权限、预算和并发数。

### REST API

创建运行：

```http
POST /v1/runs
Content-Type: application/json
```

```json
{
  "repository": "/root/case",
  "objective": "搜集官方资料并优化项目",
  "max_parallel_agents": 4,
  "budget": {
    "max_tokens": 500000,
    "max_cost_cny": 10
  },
  "permissions": {
    "read": ["**/*"],
    "write": ["**/*.md"],
    "network": ["approved_sources"],
    "git_commit": true,
    "git_push": false
  }
}
```

通过 SSE 或 WebSocket 推送事件：

```text
event: agent.started
data: {"agent":"research-cn"}

event: change.created
data: {"agent":"china-law","file":"人口与计划生育法.md"}

event: approval.required
data: {"approval_id":"apr-123","action":"merge"}
```

## 11. 用户问题和中断

Agent 提问使用结构化 interrupt：

```json
{
  "type": "question",
  "agent": "china-law",
  "question": "无法核验的案例应如何处理？",
  "options": ["保留并标记", "删除", "移入待核验目录"],
  "default": "保留并标记",
  "blocking_scope": ["task-case-cleanup"]
}
```

只暂停依赖该答案的任务，其他 Harness 继续执行。用户回答后从 checkpoint 恢复。

## 12. 审批模型

审批页面或 CLI 必须展示实际动作，而不是抽象描述：

```text
需要审批：合并 Agent 修改

修改文件：7
新增：32 行
删除：1 行
来源：Research CN 8 项、Research US 12 项
检查：Markdown ✓  本地链接 ✓

[查看完整 Diff] [批准合并] [退回修改] [拒绝]
```

用户可以批准全部修改，也可以按 Agent、commit 或文件部分批准。

## 13. 目录结构

```text
swarm/
├── orchestrator/
│   ├── graph.py
│   ├── scheduler.py
│   └── state.py
├── harness/
│   ├── base.py
│   ├── process.py
│   ├── workspace.py
│   └── result.py
├── agents/
│   ├── research/
│   ├── planner/
│   ├── china_law/
│   ├── us_law/
│   ├── docs/
│   ├── test/
│   └── review/
├── tools/
│   ├── filesystem.py
│   ├── git.py
│   ├── web_search.py
│   └── markdown.py
├── policies/
│   ├── permissions.yaml
│   └── ownership.yaml
└── runtime/
    ├── checkpoints/
    ├── artifacts/
    ├── logs/
    └── worktrees/
```

## 14. 分阶段实施

### Phase 1：本地可执行 Harness

- 定义 TaskSpec、HarnessResult 和事件协议；
- 实现 Git worktree 管理；
- 实现文件、命令和 Git 工具；
- Worker 能真实修改文件并提交；
- 提供 `run`、`watch`、`status` 和 `diff` CLI。

### Phase 2：多 Agent 编排

- 增加 Repo Audit、Planner、Worker、Test、Review；
- 使用 `Send` 并行分发任务；
- 增加 SQLite checkpoint；
- 支持失败恢复和定向退回。

### Phase 3：用户协作

- 增加运行中消息和结构化约束；
- 增加 interrupt、reply、approve 和 reject；
- 支持按文件或 commit 审批。

### Phase 4：服务化

- FastAPI REST API；
- SSE/WebSocket 事件流；
- Web 控制台；
- PostgreSQL、用户权限和审计日志。

### Phase 5：分布式执行

- Harness 打包为容器 Worker；
- Redis/Kafka 任务队列；
- Kubernetes 调度和资源限制；
- 多模型路由、限流、费用统计和可观测性。

## 15. 第一版验收标准

第一版完成时，应满足：

1. 用户可通过 CLI 对指定仓库启动任务；
2. Planner 能生成两个以上可并行子任务；
3. Worker 在独立 worktree 中实际修改文件；
4. 每个 Worker 返回 commit SHA 和检查结果；
5. Review 审查真实 diff，并可定向退回；
6. 用户可查看日志和 diff，并审批是否合并；
7. 进程重启后能够从 checkpoint 恢复；
8. 未经审批不会推送、开 PR 或修改远程状态。

## 16. 推荐技术栈

- LangGraph：控制流、并行分发和 checkpoint；
- LangChain `create_agent`：Harness 内部工具调用循环；
- DeepSeek：Agent 推理模型；
- Git worktree：并行工作区隔离；
- SQLite：本地运行状态；
- PostgreSQL：生产持久化；
- FastAPI：API 和 SSE；
- Rich/Textual：CLI 状态界面；
- Docker/Kubernetes：后续分布式 Harness Worker。

该架构的核心原则是：**Agent 负责推理，Harness 负责执行，LangGraph 负责协调，Git 负责产物隔离和追溯，用户负责外部影响操作的最终授权。**
