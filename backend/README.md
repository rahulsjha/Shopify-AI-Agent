# Backend

FastAPI service for the Shopify AI agent.

## What it does

- Fetches Shopify data through a single read-only `get_shopify_data` tool.
- Uses a LangChain ReAct agent with Gemini for question planning.
- Uses `PythonAstREPLTool` for the actual data analysis.
- Returns structured JSON so the frontend can render text, tables, and charts.

## Run

1. Install dependencies: `python -m pip install -r backend/requirements.txt`
2. Start the API: `uvicorn backend.app.main:app --reload --port 8000`
3. Open `http://localhost:8000/docs` for the OpenAPI docs.

