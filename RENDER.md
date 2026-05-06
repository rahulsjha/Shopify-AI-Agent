# Quick Render Setup

## 1) Backend (Web Service)
- **Root Directory**: `backend`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: Leave empty (Render will auto-detect Procfile)
- **Environment variables**: 
  - `SHOPIFY_SHOP_NAME`
  - `SHOPIFY_ACCESS_TOKEN`
  - `SHOPIFY_API_VERSION`
  - `GEMINI_API_KEY`

## 2) Frontend (Static Site)
- **Root Directory**: `frontend`
- **Build Command**: `npm ci && npm run build`
- **Publish Directory**: `dist`
- **Environment variables**:
  - `VITE_API_BASE_URL` = your backend service URL (e.g., `https://your-backend.onrender.com`)

## Notes
- The backend's Procfile automatically handles the start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Runtime is set to Python 3.11.9 via `backend/runtime.txt`
- Frontend proxies API calls to the backend via the environment variable
