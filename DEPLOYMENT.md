Render deployment steps

Frontend (Vite):
- Build command: `npm --prefix frontend ci && npm --prefix frontend run build`
- Publish directory: `frontend/dist`
- Environment variables:
  - `VITE_API_BASE_URL` -> set to `https://<your-backend-service>`

Backend (Python/FastAPI):
- Build/Install: `pip install -r backend/requirements.txt`
- Start command: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
- Environment variables required:
  - `SHOPIFY_SHOP_NAME`
  - `SHOPIFY_API_VERSION`
  - `SHOPIFY_ACCESS_TOKEN`
  - `GEMINI_API_KEY` (optional)
  - `GEMINI_MODEL` (optional)

Monorepo Render setup:
- Create two services on Render:
  1. Static Site for frontend
     - Root: `frontend`
     - Build: `npm ci && npm run build`
     - Publish: `dist`
     - Set `VITE_API_BASE_URL` to the backend service URL
  2. Web Service for backend
     - Root: `.` (repo root)
     - Build: `pip install -r backend/requirements.txt`
     - Start: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
     - Add environment variables listed above

Notes:
- For local testing: run backend with `npm run start:backend` (after installing Python deps), and frontend dev server with `npm --prefix frontend run dev`.
- Ensure CORS in `backend/app/main.py` allows your frontend origin(s).
