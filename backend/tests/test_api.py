from __future__ import annotations

from fastapi.testclient import TestClient

from backend.app.main import app, get_agent_executor


class FakeExecutor:
    def invoke(self, _: dict[str, str]) -> dict[str, str]:
        return {
            "output": '{"answer":"Orders are up 12% week over week","table":[{"Metric":"Orders","Value":12}],"warnings":[]}'
        }


def test_ask_endpoint_returns_structured_response():
    app.dependency_overrides[get_agent_executor] = lambda: FakeExecutor()
    client = TestClient(app)

    response = client.post("/api/ask", json={"question": "How many orders last week?"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["answer"] == "Orders are up 12% week over week"
    assert payload["table"][0]["Metric"] == "Orders"

    app.dependency_overrides.clear()
