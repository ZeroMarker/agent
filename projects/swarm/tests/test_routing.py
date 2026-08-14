from langchain_core.language_models.fake_chat_models import FakeListChatModel

from swarm.graph import next_agent, run


def test_happy_path_routes_through_all_workers():
    assert next_agent({}) == "research"
    assert next_agent({"research": "r"}) == "coding"
    assert next_agent({"research": "r", "implementation": "i"}) == "review"
    assert next_agent({"research": "r", "implementation": "i", "review": "ok", "approved": True}) == "finish"


def test_rejected_review_returns_to_coding():
    state = {"research": "r", "implementation": "i", "review": "fix it", "approved": False}
    assert next_agent(state) == "coding"


def test_step_limit_always_finishes():
    assert next_agent({"steps": 4, "max_steps": 4}) == "finish"


def test_complete_graph_offline():
    model = FakeListChatModel(responses=["research", "implementation", "APPROVED\nlooks good"])
    result = run("build a service", model=model)
    assert result["approved"] is True
    assert result["steps"] == 3
    assert result["trace"] == [
        "supervisor->research", "research",
        "supervisor->coding", "coding",
        "supervisor->review", "review",
        "supervisor->finish", "finish",
    ]
