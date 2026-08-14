# Cloudflare Computer 笔记

> 仓库：https://github.com/cloudflare/computer
> 本文是对该仓库 README 与 `docs/` 设计规范的整理笔记，按"是什么 → 架构 → 上手 → 各接口 → 例子 → 限制"组织，便于快速查找。

## 1. 一句话总结

**Cloudflare Computer** 是一个运行在 Cloudflare Durable Object 里的"虚拟文件系统 + 可插拔执行后端"框架：文件系统的权威状态存在 DO 的 SQLite 里，通过 `workspace.runtime` 这一个入口把命令/代码路由到不同的执行后端（Linux 容器、Dynamic Worker 里的 shell、Dynamic Worker 里的 JavaScript 隔离运行时）。主要面向**需要一个小型可移植工作目录的 AI Agent**。

> ⚠️ **PREVIEW ONLY**：官方明确声明仅供反馈、实验、原型使用，API 不稳定，**不适合生产**。`docs/` 里的规范是"前瞻性"的——读它看设计意图，不一定是当前代码的准确描述。

## 2. 核心架构

```
┌────────────────────────────┐              ┌─────────────────────────┐
│ Durable Object (宿主机)      │              │ 沙箱容器                  │
│  ┌──────────────────────┐  │  capnweb WS  │  ┌─────────────────────┐ │
│  │ Workspace            │◀┼──────────────▶│  │ computerd 守护进程    │ │
│  │  fs     : 文件系统 API │  │              │  │  HTTP 服务 (:8080)   │ │
│  │  runtime: exec 路由    │  │              │  │  FUSE 挂载 (/workspace)│ │
│  │  push()/pull() 同步    │  │              │  │  exec 运行器          │ │
│  └──────────┬───────────┘  │              │  └──────────┬──────────┘ │
│             │              │              │             │            │
│  SQLite (ctx.storage)      │              │  进程级内存 VFS            │
│  └ 权威状态，重启不丢        │              │  └ 容器重启即丢            │
└────────────────────────────┘              └─────────────────────────┘
```

核心设计决策：

- **单一事实来源在 DO 侧**。所有 `fs` 操作落 SQLite，跨 DO 重启持久。
- **1 个 DO ↔ 1 个容器**。capnweb WebSocket 会话唯一，push/pull 水位线只对单一对端说话，便于以后做休眠（hibernation）。
- **双向增量同步**。两边各持单调递增的 rev 计数器，不用整树传输；`exec` 之前 push、`exec` 之后 pull。
- **DO 是 WS 服务端**（不是容器直接暴露 `/ws`）：容器通过出站拦截（egress interception）回拨 DO，保证流量先经过 DO 控制的路由。

### 三种执行后端（backend）

| 后端 | 包入口 | source 含义 | 需要什么 |
| --- | --- | --- | --- |
| **Container**（容器） | `@cloudflare/computer/backends/container` | shell 命令 | Cloudflare Container 里跑 `computerd` + FUSE |
| **Worker shell** | `@cloudflare/computer/backends/worker-shell` | just-bash 命令 | Worker Loader 绑定 + `experimental` flag |
| **Worker JavaScript** | `@cloudflare/computer/backends/worker-javascript` | ECMAScript 模块 | Worker Loader 绑定 + `experimental` flag |

- **Container**：完整 Linux 用户态、真二进制、真网络；冷启动慢，FUSE 重 I/O 有性能损耗。
- **Worker shell**：最快、无需容器；每个 fs 操作都回传到同一个 DO，**没有第二份存储、没有同步往返**。命令按功能组拆包（`curl`、`python`、`sqlite`、`jq`、`yq`、`file`、`xan`、`html-to-markdown`、`js-exec`），不 import 的组会被 tree-shake 掉。
- **Worker JavaScript**：全新 Dynamic Worker 里跑 ES Module，支持结构化 input/value、持久化相对导入、可配置库、Workspace 支撑的 `node:fs/promises`、受信 `ws:git` / `ws:artifacts`。

可以同时注册多个后端，按稳定 id 路由（默认 `worker-shell` / `container-shell` / `worker-javascript`），后端**懒连接**（首次 exec/push/pull/ready 才拨号）。也可完全不配后端，只要文件系统。

## 3. 安装与最小示例

```bash
npm install @cloudflare/computer
```

Worker 需要 `nodejs_compat` flag；worker-shell / worker-javascript 后端还需要 `experimental` flag 和 Worker Loader 绑定（`wrangler.jsonc` 里 `"worker_loaders": [{ "binding": "LOADER" }]`）。

最小可用：纯文件系统，无执行后端。

```ts
import { withWorkspace, getWorkspace } from "@cloudflare/computer";
import { DurableObject } from "cloudflare:workers";

export class Agent extends withWorkspace(
  class extends DurableObject<Env> {},
  (self) => ({ storage: self.ctx.storage }),
) {}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const id = env.Agent.idFromName("user-123");
    using ws = await getWorkspace(env.Agent.get(id));
    await ws.fs.writeFile("/notes.md", "- [ ] ship it\n");
    const notes = await ws.fs.readFile("/notes.md", "utf8");
    return new Response(notes);
  },
} satisfies ExportedHandler<Env>;
```

`wrangler.jsonc`：

```jsonc
{
  "compatibility_flags": ["nodejs_compat"],
  "durable_objects": { "bindings": [{ "name": "Agent", "class_name": "Agent" }] },
  "migrations": [{ "tag": "v1", "new_sqlite_classes": ["Agent"] }]
}
```

加执行后端（worker-shell，最快，不需要 Docker）：

```ts
import { WorkerShellBackend } from "@cloudflare/computer/backends/worker-shell";
import curlModules from "@cloudflare/computer/shell/curl";

export class Agent extends withWorkspace(
  class extends DurableObject<Env> {},
  (self) => ({
    storage: self.ctx.storage,
    backends: [
      new WorkerShellBackend({
        loader: self.env.LOADER,
        workspace: { binding: "Agent", id: self.ctx.id.toString() },
        ctx: self.ctx,
        commands: [curlModules],
      }),
    ],
  }),
) {}
```

## 4. 文件系统面（workspace.fs）

风格接近 `node:fs/promises`：全异步、路径绝对、跨 DO 重启持久。

```ts
// 写：字符串默认 utf8，也支持 Uint8Array 和 ReadableStream
await ws.fs.writeFile("/notes/todo.md", "- [ ] ship it\n");
await ws.fs.writeFile("/data/blob.bin", new Uint8Array([1, 2, 3]));
await ws.fs.writeFile("/uploads/big.csv", request.body!);

// 读：字符串或流（流可直接 pipe 进 Response）
const todo = await ws.fs.readFile("/notes/todo.md", "utf8");
const stream = await ws.fs.readFile("/uploads/big.csv");

// 目录与删除
await ws.fs.mkdir("/notes/daily", { recursive: true });
for (const entry of await ws.fs.readdir("/notes")) {
  console.log(entry.isDirectory ? `d ${entry.name}` : `f ${entry.name}`);
}
await ws.fs.rm("/notes/daily", { recursive: true });

// 全文搜索
const hits = await ws.fs.grep("TODO", "/", { ignoreCase: true });
for (const hit of hits) console.log(`${hit.path}:${hit.line}: ${hit.text}`);
```

路径约定：

- 全部用**绝对路径**（`/` 开头），相对路径报 `EINVAL`。
- POSIX 风格、正斜杠；`/workspace/foo` 与 `/workspace/foo/` 等价（规范形不带尾斜杠，`/` 例外）。
- `/` 根目录受保护：不能删（`EPERM`）、不能被 writeFile 覆盖（`EISDIR`）、不能被 symlink 遮蔽（`EEXIST`）。
- 用户数据按惯例放 `/workspace`（这是容器 FUSE 的默认挂载点，由 `computerd` 的 `MOUNT_POINT` 环境变量决定）；宿主机侧不会自动创建。

只读挂载：R2 桶可预填进树（挂载点下只读，写入报 `EROFS`）。

```ts
import { R2Bucket } from "@cloudflare/computer";
new Workspace({ storage: ctx.storage, mounts: { "/workspace/r2": R2Bucket(env.Bucket) } });
```

## 5. 运行时面（workspace.runtime）

```ts
interface WorkspaceRuntime {
  exec(source: string, options?): Promise<WorkspaceRuntimeExecHandle>;
  getExec(id: string, options?): Promise<WorkspaceRuntimeExecHandle>;
  killExec(id: string, options?): Promise<void>;
  disposeExec(id: string, options?): Promise<void>;
}
```

- `exec` 选项：`backend`、`cwd`、`encoding: "utf8"`、`input`（结构化输入，仅 callable 后端接受，如 worker-javascript）、`env`、`stdin`、`timeoutMs`、`id`。
- handle 是 `ReadableStream<WorkspaceRuntimeEvent>`，同时也是单消费者：要么 `result()` 要么消费事件流，二选一；重复 `result()` 返回同一 promise。
- `result()` 返回 `{ status, exitCode, stdout, stderr, value?, pushed, pulled, skipped, sync }`。命令后端不设 `value`；模块后端用它返回结构化结果。
- 命令执行的标准同步括号：**push → spawn → events/result → pull**。`worker-shell` 是 `sync: "none"`（共享宿主机存储，push/pull 计数为 0）。

```ts
using run = await ws.runtime.exec("npm test", { encoding: "utf8" });
const { stdout, exitCode } = await run.result();
```

把事件流转成 Server-Sent Events 推给浏览器：

```ts
const sse = run.pipeThrough(new TransformStream({
  transform(event, controller) {
    const frame = `event: ${event.name}\ndata: ${JSON.stringify(event.value)}\n\n`;
    controller.enqueue(new TextEncoder().encode(frame));
  },
}));
return new Response(sse, { headers: { "content-type": "text/event-stream" } });
```

生命周期差异（重要）：

| 后端 | 保留执行记录？ | 可重挂？ | 可 kill？ |
| --- | --- | --- | --- |
| container-shell | 有 computerd 进程日志 | 支持 | 支持（信号） |
| worker-javascript | Workspace 执行日志 | 支持（`getExec(id, { resume })`） | 支持（宿主侧取消） |
| worker-shell | **不保留**（单次调用缓冲结果） | 否 | 只在语句边界协作中止 |

需要脱离执行、保留生命周期时用 Container 或 JavaScript 隔离，别用 worker-shell。

## 6. 同步协议（02）与 wire（08）

- 每侧一个单调递增 rev；DO→容器叫 **push**，容器→DO 叫 **pull**。
- 变更按 path 合并（同一路径多次改写只发一条，最新状态胜出）；字节不内联，只带 chunk hash；发送方先问 `remote.hasObjects(...)`，只补缺失对象。
- `exec` 往返：push（DO→容器）→ 懒挂载补充（mount 相关）→ 执行（FUSE 写入打 rev）→ fetch（容器→DO，`after: fetchCursor`）→ diff（按 `PULL_BATCH_SIZE=256` 分批，缺失对象 `fetchObjects`）→ apply（落 SQLite，每批提交后推进游标，崩溃续传只重做 ≤256 条）。
- 同步线上**没有 rename 操作码**，靠最终态（live entries + tombstone），apply 幂等、不需要操作顺序重放；代价是目录 rename 要 O(子树) 的本地写和线上条目。
- wire 类型与 server/client 助手在兄弟包 `@cloudflare/computer-rpc`（子路径 `./server`、`./client`、`./driver`、`./debug`）。
- `workspace.push()` / `workspace.pull()` 可手动触发；命令跑完但 pull 失败时 `sync.status` 为 `"pending"`，可用 `SyncRetryScheduler` 持久化"每个后端一条合并重试"，配合 DO 自己的 alarm 调用 `retryPendingSync(backend)`（库不接管你的 alarm）。

## 7. 容器侧：computerd 守护进程（07）

- `computerd` = FUSE 虚拟文件系统 + HTTP 服务，跑在沙箱容器里；VFS 由 `@platformatic/vfs` 支撑，FUSE 由 `fuse-native` 提供。
- 环境变量：`PORT`（默认 45678，Cloudflare 容器后端固定为 8080）、`MOUNT_POINT`（默认 `/workspace`）、`FUSE_MOUNT=auto`、`UPSTREAM_URL`（设了就对上游开 SyncClient 后台同步）、`EXEC_LOG_MAX_BYTES`。
- 端点：`GET /health`、`GET /__computerd/info`、`GET /__computerd/stats`、`GET /__computerd/stubs`（调试 stub 泄漏）、`POST /api`（capnweb HTTP 批处理 RPC）、`GET /ws`（capnweb WebSocket，容器主同步通道）。
- **无磁盘持久化**：内存 VFS 每次启动重建，靠同步从上游拉回状态。
- FUSE 写模型：字节归属权在 DOFS，不在 FUSE 驱动；`create` 走 `openWriteBufferForCreateSync` 先开写缓冲，`write`/`truncate` 直接改缓冲，无逐文件暂存。
- 容器镜像：`ghcr.io/cloudflare/computer-computerd-linux-x64`（预编译二进制，镜像才是发布产物）；也可 `npm run build:bin --workspace @cloudflare/computerd` 自建，产物在 `artifacts/computerd/computerd-linux-x64`。见 `examples/container/Dockerfile`。

## 8. 面向 Agent 的电池

### AI SDK 工具（`@cloudflare/computer/tools`）

```ts
import { createAITools } from "@cloudflare/computer/tools";

const tools = createAITools({
  workspace,
  read: { maxBytes: 32 * 1024, maxLines: 800 },
  shell: {
    defaultBackend: "shell",
    backends: {
      shell:    { description: "Fast Worker shell with built-in text commands." },
      container: { description: "Full Linux userland in a Cloudflare Container." },
    },
  },
});
```

默认工具集 `read` / `write` / `edit` / `ls`；`exec` 和 `publish` 配置后启用。模型靠每个后端的 `description` 决定命令跑在哪，描述要写清楚。

### Git（`@cloudflare/computer/git`，opt-in）

`isomorphic-git` 封装，直接操作本地 SQLite VFS，**不需要后端或 shell**。懒打包，并把 `pako` 换成 Workers 的 `node:zlib`，默认包图不包含 git。有 `cli({ argv })` 入口；配置了 git 后 worker-shell 后端还带内置 `git` 命令。

```ts
import { createGitClient } from "@cloudflare/computer/git";

const ws = new Workspace({ storage: ctx.storage, git: createGitClient(),
  defaultGitIdentity: { name: "Agent", email: "agent@example.test" } });

await ws.git.clone({ url: "https://github.com/example/repo.git" });
await ws.git.add({ paths: ["notes.md"] });
await ws.git.commit({ message: "add notes" });
```

### Assets（`@cloudflare/computer/assets`）

`createAssets(...).share` 把 workspace 文件传 R2，返回 presigned URL；挂进 `WorkspaceOptions.assets` 后 shell 里有 `assets publish <path> [<expiry>]` 命令。

### Artifacts（`@cloudflare/computer/artifacts`）

`createArtifact(binding, sessionId)` 是对 Cloudflare Artifacts 绑定的会话级封装：仓库名自动加 session 前缀，一个命名空间隔离多个会话。带 argv CLI（`artifacts.cli({ argv })`），配好 binding 后 worker-shell 也有 `artifacts` 命令。

```ts
const artifacts = createArtifact(env.ARTIFACTS, agentId);
const repo = await artifacts.create("build-cache", { description: "CI artifacts" });
const token = await artifacts.createToken("build-cache", "read", 3600);
```

## 9. 跨 Worker → DO 边界 & stub 释放

DO 持有 Workspace，Worker 通过 stub 访问：`withWorkspace` 装管道，`getWorkspace(stub)` 返回客户端。

**唯一要记住的坑：RPC 层不 GC 远端 stub**，长会话里不释放的 stub 会在对端堆积。规则：

- `getWorkspace(...)` 的返回值 `using`。
- `ws.runtime.exec(...)` 的 handle `using`。
- `ws.fs` / `ws.runtime` / `ws.git` 随父对象走，不用管。
- 纯值返回（readFile 字符串、stat、readdir、`git.cli`）不携带 stub，无需释放。

排查泄漏：`CAPNWEB_TRACK_STUBS=1` 环境变量 + `@cloudflare/computer-rpc/debug` 的 `stubSnapshot()`，或打 computerd 的 `GET /__computerd/stubs`。

## 10. 其他要点

- **可观测性**：`Workspace` 构造时传 `observer`，每个文档化操作一个 span（`workspace.connect`、`workspace.sync.push/pull`、`workspace.runtime.exec.spawn`、`workspace.fs.<op>`），适配 `ctx.tracing` / OpenTelemetry；默认 no-op 零开销。Cloudflare 运行时适配器在 `@cloudflare/computer/observe/cloudflare`。
- **Think 集成**：把 workspace 给 Think agent 时设 `useThink: true`，会追加 Think 的字符串型兼容方法（`readFileBytes`、`glob` 等）。
- **上限**：约 10GB（与 DO 共享存储）；容器侧文件系统在内存里，适合 agent 级工作区，别放整个 monorepo；FUSE 重 I/O（大 `node_modules`、大 tar 解压）比原生盘慢，见 `docs/19_performance.md`。

## 11. Monorepo 布局

```
computer/
├── packages/
│   ├── computer/                      # @cloudflare/computer — DO 侧门面：Workspace、后端、代理
│   ├── dofs/                          # @cloudflare/dofs — SQLite VFS + 同步原语（Database、fs 原语、SQLiteWorkspaceProvider）
│   ├── rpc/                           # @cloudflare/computer-rpc — capnweb wire 类型与 server/client/driver
│   ├── computerd/                     # @cloudflare/computerd — 容器内守护进程（FUSE + HTTP，发布为二进制）
│   └── computer-computerd-linux-x64/  # 私有 Docker 镜像上下文（linux-x64 二进制）
├── examples/                          # 可运行示例
├── docs/                              # 设计规范（19 篇，前瞻性）
└── package.json                       # npm workspaces 根
```

改名历史：`packages/workspace-rpc/` → `packages/rpc/`（包名仍是 `@cloudflare/computer-rpc`）；`packages/workspace-fs/` → `packages/dofs/`（包名 `@cloudflare/computer-fs` → `@cloudflare/dofs`）。旧文档里见到旧路径，指的都是现在的代码。

## 12. 示例走读（examples/）

| 示例 | 说明 |
| --- | --- |
| `container` | Worker + DO 拉起跑 `computerd` 的容器，暴露 `write`/`read`/`exec` HTTP 面；含 Dockerfile（从 GHCR 拷二进制 + fuse3 运行时）。 |
| `worker-shell` | 同一 HTTP 面，但 shell 在 Dynamic Worker 里跑 just-bash（经 `env.LOADER`），无容器。 |
| `worker-javascript` | 同 `worker-shell`，但 `exec` 在 Dynamic Worker 里跑 ES Module。 |
| `think` | `@cloudflare/think` 聊天 Agent，用 workspace 当工作目录，可从终端访问。 |
| `think-compare-runtimes` | Web UI，同一 agent 任务在容器与 worker 运行时并排对比。 |
| `tutorial` | 逐步构建：一个端点 + 一个写 markdown 菜谱卡片的 agent + 容器里 `pandoc` 转 PDF。 |
| `artifacts` | 在 workspace 里生成 Worker 项目并发布到 Cloudflare Artifacts，得到可克隆仓库。 |
| `assets` | 用 Workers AI 把提示词变成图片，写进 workspace，经 `@cloudflare/computer/assets` 返回可分享链接。 |

## 13. 官方文档地图

- 主 README：`README.md`（本笔记即源于此）
- 包 README：`packages/computer/README.md`（最完整的上手文档，含后端选择表、多后端、stub 释放契约）
- 设计规范：`docs/README.md` 起，共 19 篇：
  - 01 VFS 目录结构 / 02 同步协议 / 03 SQLite schema / 04 fs 接口 / 05 runtime 接口 / 06 挂载接口（未实现）/ 07 computerd 注入服务 / 08 capnweb wire / 09 Agent 工具 / 10 项目布局 / 11 生命周期 / 12 worker-shell 后端 / 13 git 接口 / 14 assets / 15 artifacts / 16 执行运行时架构 / 17 isolate JavaScript / 18 运行时迁移（破坏性变更）/ 19 性能基准
- 协作：`CONTRIBUTING.md`（公共贡献路径，**不接受未经请求的 PR**）、`COLLABORATORS.md`（已批准协作者）、`AGENTS.md` + `.agents/skills/`（agent 协作规范）

## 14. 值得跟进的点 / 坑

- [ ] API 处于 preview，`docs/` 是前瞻性文档，**代码与文档冲突时以代码为准**（官方原话）。
- [ ] 容器侧无持久化：容器重启丢本地状态，下一次 push 重新基线。
- [ ] 休眠（hibernation）尚未落地：今天 DO 侧用 `server.accept()` 而非 `ctx.acceptWebSocket()`；1:1 配对是为休眠铺路。
- [ ] 06 挂载接口（R2/Artifacts/GitHub 预填）**尚未实现**；R2 只读挂载已可用。
- [ ] worker-shell 不保留执行记录：需要脱离执行/重挂/信号就选容器或 JS 隔离。
- [ ] 长会话记得 `using` 释放 stub，或用 `CAPNWEB_TRACK_STUBS=1` 查泄漏。
