# LangGraph + DeepSeek Agent Swarm

一个可运行的 Supervisor 多 Agent 最小实践。Supervisor 使用确定性策略调度，Research、Coding、Review Agent 共享图状态；Review 不通过时回到 Coding，并由 `max_steps` 防止无限循环。

```text
START -> Supervisor -> Research -> Supervisor -> Coding
                    ^                         |
                    |                         v
                    +------ Review <----------+
                              |
                    (通过或达到步骤上限)
                              v
                            END
```

## 运行

需要 Python 3.11+：

```bash
cd swarm
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
cp .env.example .env
# 编辑 .env，填入 DEEPSEEK_API_KEY
swarm --trace "设计一个带鉴权和测试的 FastAPI TODO 服务"
```

运行离线单元测试：

```bash
pytest
```

## 设计取舍

- Supervisor 不再调用一次 LLM 只为决定显然的下一步，因此路由稳定、便宜、可测试。
- Worker 通过同一个 `SwarmState` 交换研究、实现和审查结果。
- Review 首行协议用于判断是否通过；生产环境可改成模型结构化输出。
- 当前示例只生成实现文本，不执行生成的代码。若加入 shell、文件写入或网络工具，应增加沙箱、超时、审批和审计。
- `.env.example` 默认使用 `deepseek-v4-flash`。旧的 `deepseek-chat` / `deepseek-reasoner` 名称将于 2026-07-24 停用。

原始架构笔记保留在 [`swarm.md`](./swarm.md)。
