# Render Deployment Guide

## Setup Overview
Deploy as **two separate services** on Render:
1. **Frontend**: Static Site (React/Vite)
2. **Backend**: Web Service (FastAPI)

## Backend Service Setup

### Configuration
- **Root Directory**: `backend`
- **Build Command**: `pip install -r requirements.txt`
- **Start Command**: (Leave empty - Procfile auto-detected)
- **Python Version**: 3.11.9 (via `backend/runtime.txt`)

### Required Environment Variables
- `SHOPIFY_SHOP_NAME` - Your Shopify store domain (e.g., `clevrr-test.myshopify.com`)
- `SHOPIFY_API_VERSION` - API version (e.g., `2025-04`)
- `SHOPIFY_ACCESS_TOKEN` - Your Shopify access token
- `GEMINI_API_KEY` - (Optional) Google Gemini API key for LLM features
- `GEMINI_MODEL` - (Optional) Gemini model name

## Frontend Service Setup

### Configuration
- **Root Directory**: `frontend`
- **Build Command**: `npm ci && npm run build`
- **Publish Directory**: `dist`

### Required Environment Variables
- `VITE_API_BASE_URL` - Set to your backend service URL
  - Example: `https://shopify-agent-backend.onrender.com`
  - The frontend will append `/api` to this URL

## Local Testing

```bash
# Terminal 1: Backend
npm run start:backend

# Terminal 2: Frontend (in another terminal)
npm run dev:frontend
```

## Important Notes
- The backend's `Procfile` handles the start command automatically
- Frontend CORS is configured for both `localhost:5173` and `127.0.0.1:5173`
- The frontend uses Vite's dev server proxy in development to reach the backend
- In production, use the `VITE_API_BASE_URL` environment variable to point to your backend service URL
