from __future__ import annotations

import json
from typing import Any

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .agent import build_agent_executor
from .schemas import AskRequest, AskResponse


app = FastAPI(title="Shopify AI Agent", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_agent_executor():
    return build_agent_executor()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/ask", response_model=AskResponse)
def ask(request: AskRequest, agent_executor=Depends(get_agent_executor)) -> AskResponse:
    try:
        result = agent_executor.invoke({"input": request.question})
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    output = _coerce_output(result.get("output", ""))
    return AskResponse(
        answer=str(output.get("answer", output if isinstance(output, str) else "")),
        table=_normalize_table(output.get("table")),
        chart=output.get("chart") if isinstance(output, dict) else None,
        warnings=_normalize_warnings(output.get("warnings")),
        raw_output=result.get("output"),
    )


def _coerce_output(raw_output: Any) -> Any:
    if isinstance(raw_output, dict):
        return raw_output

    if isinstance(raw_output, str):
        text = raw_output.strip()
        if text.startswith("{") and text.endswith("}"):
            try:
                parsed = json.loads(text)
                if isinstance(parsed, dict):
                    return parsed
            except json.JSONDecodeError:
                pass
        return {"answer": text}

    return {"answer": str(raw_output)}


def _normalize_table(value: Any) -> list[dict[str, Any]]:
    if isinstance(value, list):
        return [row for row in value if isinstance(row, dict)]
    return []


def _normalize_warnings(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    return []
