# Ultra-simple agent - just call LLM for structured response
import json
import logging
from typing import Any

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate

from .config import load_settings
from .schemas import AskResponse

logger = logging.getLogger(__name__)


def invoke_agent(question: str) -> AskResponse:
    """Call LLM for Shopify analytics question."""
    settings = load_settings()
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is required")

    # Create LLM
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0,
        google_api_key=settings.gemini_api_key,
    )

    # Create prompt
    prompt = ChatPromptTemplate.from_template("""You are an expert Shopify analytics assistant. 

The user is asking: {question}

Based on typical Shopify data patterns, provide a JSON response with:
- answer: Natural language summary
- table: List of data rows (use empty list if no table needed)
- chart: Chart spec with type/title/series, or null
- warnings: Any relevant warnings

Return ONLY valid JSON, no other text:
{{
  "answer": "string",
  "table": [{{}}],
  "chart": {{"type": "line|bar", "title": "string", "x_label": "string", "y_label": "string", "series": [{{"name": "string", "points": [{{"x": "string", "y": 0}}]}}]}},
  "warnings": ["string"]
}}""")

    try:
        # Invoke LLM
        chain = prompt | llm
        response = chain.invoke({"question": question})
        
        # Extract content
        answer_text = response.content if hasattr(response, 'content') else str(response)
        answer_text = answer_text.strip()
        
        # Remove markdown if present
        if answer_text.startswith("```"):
            answer_text = answer_text.split("```")[1]
            if answer_text.startswith("json"):
                answer_text = answer_text[4:]
            answer_text = answer_text.strip()
        
        # Parse JSON
        try:
            data = json.loads(answer_text)
            return AskResponse(
                answer=str(data.get("answer", "")).strip(),
                table=data.get("table", []) if isinstance(data.get("table"), list) else [],
                chart=data.get("chart") if isinstance(data.get("chart"), dict) else None,
                warnings=data.get("warnings", []) if isinstance(data.get("warnings"), list) else [],
                raw_output=answer_text,
            )
        except json.JSONDecodeError as e:
            logger.error(f"JSON parse error: {e}\nResponse: {answer_text}")
            return AskResponse(
                answer=answer_text[:200] if answer_text else "Could not parse response",
                table=[],
                chart=None,
                warnings=["Response parsing error"],
                raw_output=answer_text,
            )
    
    except Exception as e:
        logger.error(f"Agent error: {e}", exc_info=True)
        return AskResponse(
            answer="",
            table=[],
            chart=None,
            warnings=[f"Error: {str(e)}"],
            raw_output=str(e),
        )
