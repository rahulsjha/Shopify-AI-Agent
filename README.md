# Shopify AI Agent

Shopify AI Agent is a read-only analytics product that answers natural-language questions about a Shopify store, fetches live store data, and renders the result as text, tables, and charts.

## What the product does

The app lets a user ask questions such as:

- How many orders were placed in the last 7 days?
- Which products sold the most last month?
- Who are my repeat customers?
- Show revenue by city.

The backend resolves the question against live Shopify Admin API data, computes the analysis, and returns a structured response for the frontend.

## Architecture

```mermaid
flowchart LR
	U[User] --> F[React + Vite Frontend]
	F --> A[FastAPI Backend]
	A --> S[Shopify Admin API]
	A --> G[Gemini / LangChain planning]
	A --> R[Structured JSON response]
	R --> F
```

### Backend

- FastAPI serves the `/health` and `/api/ask` endpoints.
- `ShopifyClient` fetches live orders, products, and customers.
- `agent_production.py` routes a question to the right data fetcher, applies filtering, and shapes the final answer.
- Response payloads contain `answer`, `table`, `chart`, `warnings`, and `raw_output` so the UI can render multiple views of the same result.

### Frontend

- React 19 + Vite powers the UI.
- The app posts questions to the backend and renders the answer, a table, and a chart if the response includes them.
- The deployed frontend uses `https://shopify-ai-agent-h9x5.onrender.com` by default for API calls, while local development can still override this with `VITE_API_BASE_URL`.

## Technology choices

### FastAPI

FastAPI was used because it is lightweight, typed, fast, and ideal for JSON APIs that need predictable schemas and clear validation.

### Shopify Admin API + httpx

The Shopify Admin API provides the source of truth. `httpx` was used because it gives straightforward control over retries, pagination, headers, and error handling.

### Pydantic

Pydantic powers request and response validation so the backend always returns a stable contract to the UI.

### React + Vite

React keeps the UI composable, while Vite keeps local iteration fast and makes the frontend build simple for deployment.

### LangChain + Gemini

These are used for agentic planning and question interpretation, but the final answer is grounded in live Shopify data rather than canned content.

## Approach followed

1. Removed fake sample responses and replaced them with live Shopify data fetches.
2. Added robust pagination and retry handling for the Shopify API.
3. Sliced order data by time window after fetching real records so recent-period questions still work reliably.
4. Standardized backend responses into a UI-friendly schema.
5. Connected the frontend to the backend with a small API client and a Vite dev proxy.
6. Prepared the project for deployment on Render with separate frontend and backend services.
7. Updated the UI to a minimal black-and-white layout with a full-width question composer.

## How the main problems were solved

### Dummy values removed

The earlier hardcoded agent output was replaced with live calls to Shopify so the product now returns actual store data instead of fake counts or fixed revenue values.

### Order windows became reliable

Instead of depending on a narrow API date filter, orders are fetched first and then filtered locally for the requested window. That made last-7-days and last-month queries much more dependable.

### Frontend/backend connectivity

The frontend was changed to use a relative API strategy in development and a deployed backend URL in production. Vite proxying also removed the connection-refused issue during local dev.

### CORS on deployed frontend

The backend now allows the deployed Vercel origin and also supports a `FRONTEND_ORIGINS` environment variable so new preview URLs can be added without code changes.

### Security cleanup

Secrets were removed from docs and history was cleaned so exposed keys are not left in the repository.

## Project structure

- `backend/` FastAPI backend, Shopify client, agent logic, schemas, and tests
- `frontend/` React UI, API client, types, and styling
- `package.json` monorepo helper scripts for build and start flows
- `.env` local secrets only, never committed

## Local development

### Backend

```powershell
cd backend
python -m pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Frontend

```powershell
cd frontend
npm install
npm run dev
```

## Deployment summary

- **Backend**: Render Web Service
- **Frontend**: Render Static Site or another static host such as Vercel
- **Backend start command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- **Frontend API base**: `https://shopify-ai-agent-h9x5.onrender.com`

## If more time were available

- Add caching for repeated Shopify queries.
- Add more charts and richer drill-downs.
- Improve observability with request tracing and structured logs.
- Add automated tests for more question types and response shapes.
- Add a better loading state and skeleton UI for large queries.
- Expand tool routing so the agent can support more business questions with fewer assumptions.

## Environment

The repository expects Shopify credentials and optional Gemini settings in the root `.env` file.

