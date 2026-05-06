# Simplified agent that uses Gemini's native tool calling
import json
import logging
from typing import Any

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.tools import tool

from .config import load_settings
from .shopify_client import ShopifyClient, ShopifyResponseError
from .schemas import AskResponse

logger = logging.getLogger(__name__)

# Initialize Shopify client once
_shopify_client = None

def get_shopify_client():
    global _shopify_client
    if _shopify_client is None:
        settings = load_settings()
        _shopify_client = ShopifyClient(
            shop_name=settings.shop_name,
            api_version=settings.api_version,
            access_token=settings.access_token,
            request_timeout_seconds=settings.request_timeout_seconds,
        )
    return _shopify_client


def build_agent_v2() -> ChatGoogleGenerativeAI:
    """Build simplified agent that uses Gemini's native tool calling."""
    settings = load_settings()
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is required")

    # Define tools for Gemini
    @tool
    def get_shopify_data(resource: str, params: dict = None, max_pages: int = 5) -> str:
        """Fetch data from Shopify.
        
        Args:
            resource: One of 'orders', 'products', 'customers'
            params: Optional query parameters
            max_pages: Maximum number of pages to fetch
            
        Returns:
            JSON string with the data
        """
        if params is None:
            params = {}
        
        try:
            client = get_shopify_client()
            result = client.get_shopify_data(
                resource=resource,
                params=params,
                max_pages=max_pages,
            )
            return json.dumps(result)
        except ShopifyResponseError as e:
            return json.dumps({"error": str(e)})
        except Exception as e:
            logger.error(f"Shopify error: {e}")
            return json.dumps({"error": f"Failed to fetch {resource}: {str(e)}"})

    # Create LLM with tool binding
    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_model,
        temperature=0,
        google_api_key=settings.gemini_api_key,
    )
    
    # Bind tools to LLM
    tools = [get_shopify_data]
    llm_with_tools = llm.bind_tools(tools)
    
    return llm_with_tools


def invoke_agent(question: str) -> AskResponse:
    """Invoke the agent to answer a question.
    
    Args:
        question: User question about Shopify data
        
    Returns:
        AskResponse with answer, table, chart, warnings
    """
    llm_with_tools = build_agent_v2()
    
    system_prompt = """You are an expert Shopify analytics assistant. 

When answering questions:
1. Fetch data using the get_shopify_data tool if needed
2. Analyze the data using Python code if needed
3. Return ONLY a valid JSON object with these fields:
   - answer: str (natural language summary)
   - table: list[dict] (rows of data, empty if no table needed)
   - chart: dict with type/title/series or null
   - warnings: list[str] (any warnings or notes)

Example response structure:
{
  "answer": "There were 145 orders in the last 7 days...",
  "table": [{"date": "2024-01-01", "orders": 20}],
  "chart": {"type": "line", "title": "Orders", "x_label": "Date", "y_label": "Orders", "series": [{"name": "Orders", "points": []}]},
  "warnings": []
}

ALWAYS respond with ONLY the JSON object, nothing else."""

    try:
        # Send question to LLM
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=question),
        ]
        
        response = llm_with_tools.invoke(messages)
        
        # Extract response content
        answer_text = response.content if hasattr(response, 'content') else str(response)
        
        # Try to parse as JSON
        try:
            # Remove markdown code blocks if present
            if answer_text.startswith("```"):
                answer_text = answer_text.split("```")[1]
                if answer_text.startswith("json"):
                    answer_text = answer_text[4:]
                answer_text = answer_text.strip()
            
            parsed = json.loads(answer_text)
            
            return AskResponse(
                answer=parsed.get("answer", ""),
                table=parsed.get("table", []),
                chart=parsed.get("chart"),
                warnings=parsed.get("warnings", []),
                raw_output=answer_text,
            )
        except json.JSONDecodeError:
            # If JSON parsing fails, create a structured response
            return AskResponse(
                answer=answer_text[:500],
                table=[],
                chart=None,
                warnings=["Response could not be parsed as structured data"],
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
