from typing import Any

from langchain_core.language_models import BaseChatModel
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.graph import END, START, StateGraph

from .model import build_model
from .state import AgentName, SwarmState


def next_agent(state: SwarmState) -> AgentName:
    """Deterministic supervisor policy; bounded and easy to test."""
    if state.get("steps", 0) >= state.get("max_steps", 8):
        return "finish"
    if not state.get("research"):
        return "research"
    if not state.get("implementation"):
        return "coding"
    if not state.get("review"):
        return "review"
    if state.get("approved", False):
        return "finish"
    return "coding"


def _text(model: BaseChatModel, system: str, prompt: str) -> str:
    response = model.invoke([SystemMessage(content=system), HumanMessage(content=prompt)])
    content = response.content
    return content if isinstance(content, str) else str(content)


def _append_trace(state: SwarmState, name: str) -> list[str]:
    return [*state.get("trace", []), name]


def build_graph(model: BaseChatModel | None = None) -> Any:
    llm = model or build_model()

    def supervisor(state: SwarmState) -> dict[str, Any]:
        route = next_agent(state)
        return {"next": route, "trace": _append_trace(state, f"supervisor->{route}")}

    def research(state: SwarmState) -> dict[str, Any]:
        result = _text(
            llm,
            "你是研究 Agent。识别需求、约束、风险与可验证的技术方案；不要编造外部事实。",
            f"任务：\n{state['task']}\n\n输出精炼的研究与方案说明。",
        )
        return {"research": result, "steps": state.get("steps", 0) + 1,
                "trace": _append_trace(state, "research")}

    def coding(state: SwarmState) -> dict[str, Any]:
        revision = f"\n审查意见：\n{state['review']}" if state.get("review") else ""
        result = _text(
            llm,
            "你是 Coding Agent。产出可执行、具体的实现；必要时给出文件结构和完整代码。",
            f"任务：\n{state['task']}\n\n研究：\n{state['research']}{revision}",
        )
        # Clear the prior review so a revised implementation is reviewed again.
        return {"implementation": result, "review": "", "approved": False,
                "steps": state.get("steps", 0) + 1,
                "trace": _append_trace(state, "coding")}

    def review(state: SwarmState) -> dict[str, Any]:
        result = _text(
            llm,
            "你是 Review Agent。检查正确性、安全性和可执行性。首行只能是 APPROVED 或 CHANGES_REQUESTED，随后解释。",
            f"任务：\n{state['task']}\n\n研究：\n{state['research']}\n\n实现：\n{state['implementation']}",
        )
        approved = result.lstrip().upper().startswith("APPROVED")
        return {"review": result, "approved": approved,
                "steps": state.get("steps", 0) + 1,
                "trace": _append_trace(state, "review")}

    def finish(state: SwarmState) -> dict[str, Any]:
        status = "已通过审查" if state.get("approved") else "达到步骤上限，结果尚未通过审查"
        final = f"状态：{status}\n\n{state.get('implementation', state.get('research', ''))}"
        if state.get("review"):
            final += f"\n\n审查：\n{state['review']}"
        return {"final": final, "trace": _append_trace(state, "finish")}

    graph = StateGraph(SwarmState)
    for name, node in (("supervisor", supervisor), ("research", research),
                       ("coding", coding), ("review", review), ("finish", finish)):
        graph.add_node(name, node)
    graph.add_edge(START, "supervisor")
    graph.add_conditional_edges("supervisor", lambda state: state["next"], {
        "research": "research", "coding": "coding", "review": "review", "finish": "finish"
    })
    for worker in ("research", "coding", "review"):
        graph.add_edge(worker, "supervisor")
    graph.add_edge("finish", END)
    return graph.compile()


def run(task: str, *, model: BaseChatModel | None = None, max_steps: int = 8) -> SwarmState:
    graph = build_graph(model)
    return graph.invoke({"task": task, "steps": 0, "max_steps": max_steps, "trace": []})
