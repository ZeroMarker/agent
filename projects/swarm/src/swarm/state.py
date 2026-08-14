from typing import Literal, TypedDict

AgentName = Literal["research", "coding", "review", "finish"]


class SwarmState(TypedDict, total=False):
    task: str
    research: str
    implementation: str
    review: str
    approved: bool
    next: AgentName
    steps: int
    max_steps: int
    trace: list[str]
    final: str
