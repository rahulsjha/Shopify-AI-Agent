Quick Render setup

1) Backend (Web Service)
- Root: `.` or `backend`
- Build Command: `pip install -r backend/requirements.txt`
- Start Command: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
- Environment variables: `SHOPIFY_SHOP_NAME`, `SHOPIFY_ACCESS_TOKEN`, `SHOPIFY_API_VERSION`, `GEMINI_API_KEY`

2) Frontend (Static Site)
- Root: `frontend`
- Build Command: `npm ci && npm run build`
- Publish Directory: `frontend/dist`
- Set `VITE_API_BASE_URL` to your backend public URL

Optional: If deploying as two services, you can point the frontend's `VITE_API_BASE_URL` environment variable to the backend service URL.
