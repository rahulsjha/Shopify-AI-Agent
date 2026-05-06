# Shopify AI Agent

This workspace contains a FastAPI backend and a React frontend for answering Shopify analytics questions with a read-only agent.

## Layout

- `backend/` FastAPI app, Shopify data tool, LangChain agent, and tests
- `frontend/` React app that sends questions and renders answers, tables, and charts

## Environment

The repository expects Shopify credentials in the root `.env` file.

## Run locally

Backend:

1. `python -m pip install -r backend/requirements.txt`
2. `uvicorn backend.app.main:app --reload --port 8000`

Frontend:

1. `npm install` inside `frontend/`
2. `npm run dev`

