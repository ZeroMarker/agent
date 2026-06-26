# Nanobot 消息处理机制

## 概述

Nanobot 采用异步、基于session的消息处理架构，支持并发处理多个session的消息，同时保证同一session内的消息串行处理。

## 核心组件

### 1. Session锁 (`_session_locks`)

```python
_session_locks: dict[str, asyncio.Lock] = {}
```

- 每个session拥有独立的 `asyncio.Lock`
- 确保同一session的消息串行处理
- 防止并发冲突

### 2. Pending Queue (`_pending_queues`)

```python
_pending_queues: dict[str, asyncio.Queue] = {}
```

- 当session有活跃任务时，新消息路由到此队列
- 队列大小: 20条消息
- 支持mid-turn消息注入

### 3. 并发控制 (`_concurrency_gate`)

```python
_concurrency_gate: asyncio.Semaphore | None = asyncio.Semaphore(3)
```

- 环境变量: `NANOBOT_MAX_CONCURRENT_REQUESTS` (默认3)
- 限制全局并发请求数
- 防止资源耗尽

### 4. 活跃任务追踪 (`_active_tasks`)

```python
_active_tasks: dict[str, list[asyncio.Task]] = {}
```

- 记录每个session的活跃任务
- 支持任务取消和状态查询

## 消息处理流程

```
┌─────────────────────────────────────────────────────────────┐
│                     消息入口 (run loop)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  检查session锁  │
                    └─────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │ session空闲     │             │ session忙碌     │
    │ 创建新任务      │             │ 路由到pending   │
    └─────────────────┘             │ queue (最大20)  │
              │                     └─────────────────┘
              ▼                               │
    ┌─────────────────┐                       │
    │ 获取session锁   │                       │
    │ 获取并发信号量   │                       │
    └─────────────────┘                       │
              │                               │
              ▼                               │
    ┌─────────────────┐                       │
    │ 处理消息        │◄──────────────────────┘
    │ (可能多次迭代)  │  (注入等待的消息)
    └─────────────────┘
              │
              ▼
    ┌─────────────────┐
    │ 释放锁和队列    │
    └─────────────────┘
```

## 消息路由逻辑

### 优先级处理

```python
# 1. 优先级命令立即执行
if self.commands.is_priority(raw):
    await self._dispatch_command_inline(msg, effective_key, raw, self.commands.dispatch_priority)
    continue

# 2. 可调度命令直接分派
if self.commands.is_dispatchable_command(raw):
    await self._dispatch_command_inline(msg, effective_key, raw, self.commands.dispatch)
    continue
```

### 队列路由

```python
# 3. 如果session有活跃任务，路由到pending queue
if effective_key in self._pending_queues:
    try:
        self._pending_queues[effective_key].put_nowait(pending_msg)
        logger.info(f"Routed follow-up message to pending queue for session {effective_key}")
    except asyncio.QueueFull:
        logger.warning(f"Pending queue full for session {effective_key}")
else:
    # 4. 创建新任务
    task = asyncio.create_task(self._dispatch(msg))
    self._active_tasks.setdefault(effective_key, []).append(task)
```

## 消息注入机制

### 注入时机

1. **工具执行后** (after tool execution)
2. **最终响应后** (after final response)
3. **错误恢复后** (after error/LLM error)
4. **达到最大迭代后** (after max_iterations)

### 注入逻辑

```python
async def _drain_pending(limit: int = 5) -> list[dict]:
    """从pending queue中取出消息"""
    items = []
    
    # 非阻塞取出
    while len(items) < limit:
        try:
            items.append(pending_queue.get_nowait())
        except asyncio.QueueEmpty:
            break
    
    # 如果没有消息但有运行中的子代理，等待
    if not items and subagents_running > 0:
        try:
            msg = await asyncio.wait_for(pending_queue.get(), timeout=300)
            items.append(msg)
        except asyncio.TimeoutError:
            logger.warning("Timeout waiting for sub-agent completion")
    
    return items
```

### 注入处理

```python
async def _try_drain_injections(spec, messages, assistant_message, injection_cycles, phase):
    """尝试注入等待的消息"""
    injections = await self._drain_injections(spec)
    
    if injections and injection_cycles < _MAX_INJECTION_CYCLES:
        # 合并到当前消息列表
        self._append_injected_messages(messages, injections)
        logger.info(f"Injected {len(injections)} follow-up message(s) {phase}")
        return True, injection_cycles + 1
    
    return False, injection_cycles
```

## Session管理

### Session键计算

```python
def _effective_session_key(self, msg: InboundMessage) -> str:
    """返回用于任务路由和mid-turn注入的session键"""
    if self._unified_session and not msg.session_key_override:
        return UNIFIED_SESSION_KEY  # 统一session模式
    return msg.session_key  # 默认使用消息的session键
```

### Session锁获取

```python
async def _dispatch(self, msg: InboundMessage) -> None:
    """处理消息: session内串行，session间并发"""
    session_key = self._effective_session_key(msg)
    lock = self._session_locks.setdefault(session_key, asyncio.Lock())
    gate = self._concurrency_gate or nullcontext()
    
    async with lock, gate:
        # 创建pending queue
        pending = asyncio.Queue(maxsize=20)
        self._pending_queues[session_key] = pending
        
        try:
            # 处理消息
            response = await self._process_message(msg, pending_queue=pending)
            if response:
                await self.bus.publish_outbound(response)
        finally:
            # 清理pending queue
            del self._pending_queues[session_key]
```

## 并发控制

### 信号量机制

```python
# 环境变量配置
_max = int(os.environ.get("NANOBOT_MAX_CONCURRENT_REQUESTS", "3"))
self._concurrency_gate = asyncio.Semaphore(_max) if _max > 0 else None

# 使用方式
async with lock, gate:  # 同时获取session锁和并发信号量
    # 处理消息
```

### 配置建议

| 场景 | `NANOBOT_MAX_CONCURRENT_REQUESTS` | 说明 |
|------|-----------------------------------|------|
| 低内存 | 1-2 | 减少并发，防止OOM |
| 标准 | 3 | 默认值，平衡性能和资源 |
| 高性能 | 5-10 | 增加并发，提高吞吐量 |

## 子代理集成

### 子代理结果路由

```python
# 子代理完成时，结果注入到pending queue
async def _announce_result(self, origin, task_id, result):
    msg = InboundMessage(
        channel="system",
        sender_id="subagent",
        content=result,
        session_key_override=override,  # 使用主代理的session键
    )
    await self.bus.publish_inbound(msg)
```

### 超时处理

```python
# 等待子代理完成时的超时处理
try:
    msg = await asyncio.wait_for(pending_queue.get(), timeout=300)
except asyncio.TimeoutError:
    logger.warning(f"Timeout waiting for sub-agent completion in session {session_key}")
    return items  # 返回已收集的消息
```

## 日志监控

### 关键日志

```bash
# 消息路由
grep "Routed follow-up message to pending queue" nanobot.log

# 消息注入
grep "Injected.*follow-up message" nanobot.log

# 超时警告
grep "Timeout waiting for sub-agent" nanobot.log

# 队列满
grep "Pending queue full" nanobot.log
```

### 监控脚本

```bash
#!/bin/bash
# 监控pending queue状态
tail -f /root/.nanobot/nanobot.log | grep -E "pending queue|injected|timeout"
```

## 最佳实践

1. **合理设置并发数**: 根据系统内存和CPU调整 `NANOBOT_MAX_CONCURRENT_REQUESTS`
2. **监控队列长度**: 定期检查pending queue是否满
3. **设置合理超时**: 子代理超时默认300秒，可根据任务调整
4. **避免长时间任务**: 长时间任务应使用子代理，避免阻塞主session
5. **清理临时消息**: 处理完成后及时清理pending queue

## 相关文件

- `nanobot/agent/loop.py` - 主循环和消息处理
- `nanobot/agent/runner.py` - LLM执行器
- `nanobot/agent/subagent.py` - 子代理管理
- `nanobot/agent/tools/self.py` - 运行时状态管理
