from __future__ import annotations

from functools import lru_cache

from langchain_core.prompts import PromptTemplate
from langchain_experimental.tools.python.tool import PythonAstREPLTool
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_classic.agents import AgentExecutor, create_react_agent

from .config import load_settings
from .tools import get_shopify_data_tool


PROMPT = PromptTemplate.from_template(
    """You are a senior Shopify analytics assistant.

Rules:
- Use only the get_shopify_data tool for data retrieval.
- Never suggest or perform POST, PUT, PATCH, or DELETE requests.
- Use python_repl_ast for all calculations, aggregations, grouping, parsing, and chart/table preparation.
- Ask for only the resource and fields you need.
- Return a single JSON object and nothing else. Omit keys that are not useful.

Available tools:
{tools}

Use these tool names exactly:
{tool_names}

Output schema:
{{
  "answer": "concise natural-language answer",
  "table": [{{}}],
  "chart": {{
    "type": "line" | "bar",
    "title": "string",
    "x_label": "string",
    "y_label": "string",
    "series": [{{"name": "string", "points": [{{"x": "string", "y": 0}}]}}]
  }},
  "warnings": ["string"]
}}

Question: {input}

{agent_scratchpad}
"""
)


@lru_cache(maxsize=1)
def build_agent_executor() -> AgentExecutor:
    settings = load_settings()
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is required to run the agent")

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0,
        google_api_key=settings.gemini_api_key,
    )

    python_tool = PythonAstREPLTool()
    tools = [get_shopify_data_tool, python_tool]
    agent = create_react_agent(llm=llm, tools=tools, prompt=PROMPT)

    return AgentExecutor(
        agent=agent,
        tools=tools,
        verbose=False,
        handle_parsing_errors=True,
        max_iterations=6,
    )
