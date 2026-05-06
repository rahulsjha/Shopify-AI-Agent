# Shopify AI Agent - Complete E2E Testing Guide

This guide contains comprehensive backend and frontend testing procedures, senior developer validation checklists, and ready-to-run test scripts.

---

## Quick Start

### Prerequisites
- Python 3.14.2+ with FastAPI, LangChain, and Gemini packages installed
- Node.js 18+ with npm
- curl (for API testing)
- The Gemini API key in `backend/.env`

### 1. Start the Backend Server

```bash
cd C:\Users\Rahul Jha\Desktop\Assignment
uvicorn backend.app.main:app --reload --port 8000
```

Expected output:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### 2. Run the Automated Test Suite

**Option A: PowerShell (Windows)**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\run-all-tests.ps1
```

**Option B: Bash (Linux/macOS/WSL)**
```bash
bash api-test.sh http://127.0.0.1:8000
```

### 3. Start the Frontend

In a separate terminal:
```bash
cd frontend
npm run dev
```

Open: `http://localhost:5173`

---

## Backend API Test Suite

### Test Script: `backend-test-e2e.ps1`

Run the comprehensive backend test suite:
```powershell
.\backend-test-e2e.ps1
```

**What it validates:**
- ✓ Health endpoint (`GET /health`)
- ✓ OpenAPI schema discovery (`GET /openapi.json`)
- ✓ Request validation (422 on invalid input)
- ✓ CORS preflight for React frontend
- ✓ Real agent request with Gemini integration
- ✓ Concurrent request handling

**Expected Results:**
```
Testing: 1. Health Check
  Status: 200 - ✓ PASS
  
Testing: 2. OpenAPI Schema
  Status: 200 - ✓ PASS
  
Testing: 3. Request Validation (Missing Field)
  Status: 422 - ✓ PASS
  
Testing: 4. Request Validation (Empty Question)
  Status: 422 - ✓ PASS
  
Testing: 5. CORS Preflight (React Frontend)
  Status: 200 - ✓ PASS
  
Testing: 6. Real Ask Request (Agent Integration)
  Status: 200 - ✓ PASS
  
Testing: 7. Concurrent Requests
  Concurrent requests: 3/3 succeeded - ✓ PASS
  
Total: 7/7 tests passed
✓ ALL TESTS PASSED - Backend is ready for production
```

---

## Frontend Integration Test Suite

### Test Script: `frontend-integration-test.ps1`

Run the frontend validation suite:
```powershell
.\frontend-integration-test.ps1
```

**What it validates:**
- ✓ Backend availability
- ✓ API response contract (answer, table, chart, warnings)
- ✓ Field type validation
- ✓ Error handling (422 responses)
- ✓ Frontend build success (`npm run build`)
- ✓ CORS configuration for localhost:5173

---

## Complete Test Suite: `run-all-tests.ps1`

Runs all tests in sequence:

```powershell
# Run all tests
.\run-all-tests.ps1

# Run with verbose output
.\run-all-tests.ps1 -VerboseOutput

# Skip frontend tests
.\run-all-tests.ps1 -SkipFrontend

# Skip integration tests
.\run-all-tests.ps1 -SkipIntegration
```

**Test sections:**
1. Backend unit tests (pytest)
2. Backend API tests (curl)
3. Frontend integration tests
4. Configuration validation

---

## Manual curl Command Reference

### 1. Health Check
```bash
curl -i http://127.0.0.1:8000/health
```

**Expected Response:**
```
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"ok"}
```

---

### 2. OpenAPI Schema Discovery
```bash
curl -s http://127.0.0.1:8000/openapi.json | jq '.paths'
```

**Expected:** Paths for `/health` and `/api/ask` only

---

### 3. Request Validation - Missing Field
```bash
curl -i -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response:**
```
HTTP/1.1 422 Unprocessable Content

{"detail":[{"type":"missing","loc":["body","question"],"msg":"Field required"}]}
```

---

### 4. Request Validation - Empty Question
```bash
curl -i -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":""}'
```

**Expected Response:**
```
HTTP/1.1 422 Unprocessable Content

{"detail":[{"type":"string_too_short", ...}]}
```

---

### 5. CORS Preflight (React Frontend Compatibility)
```bash
curl -i -X OPTIONS http://127.0.0.1:8000/api/ask \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
```

**Expected Response:**
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:5173
Access-Control-Allow-Methods: DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT
Access-Control-Allow-Headers: content-type
```

---

### 6. Real Ask Request (Sample Question)
```bash
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"How many orders were placed in the last 7 days?"}'
```

**Expected Response:**
```json
{
  "answer": "Based on the Shopify data analysis, there were [X] orders placed in the last 7 days.",
  "table": [
    {
      "date": "2026-04-30",
      "orders": 12,
      "revenue": 4500.00
    },
    ...
  ],
  "chart": {
    "type": "line",
    "title": "Order Volume Over 7 Days",
    "x_label": "Date",
    "y_label": "Orders",
    "series": [
      {
        "name": "orders",
        "points": [
          {"x": "2026-04-30", "y": 12},
          ...
        ]
      }
    ]
  },
  "warnings": [],
  "raw_output": "..."
}
```

---

### 7. Sample Questions for Testing

Each of these questions should work through the full pipeline:

```bash
# Orders Analysis
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"How many orders were placed in the last 7 days?"}'

# Products Analysis
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Which products sold the most last month?"}'

# Revenue by Location
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Show a table of revenue by city."}'

# Customer Analysis
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Who are my repeat customers?"}'

# AOV Trend
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"What is the AOV (Average Order Value) trend this month?"}'

# Recommendations
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Can you recommend what product to promote based on sales?"}'

# Chart Bonus
curl -s -X POST http://127.0.0.1:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Plot a graph of order volume over the past 4 weeks."}'
```

---

## End-to-End Integration Checklist

### Backend Tests (Automated)
- [ ] `pytest backend/tests` passes (5 tests)
- [ ] `GET /health` returns 200 OK
- [ ] `GET /openapi.json` returns valid schema
- [ ] `POST /api/ask` with missing field returns 422
- [ ] `OPTIONS /api/ask` preflight returns 200 with CORS headers
- [ ] `POST /api/ask` with real question returns 200 with schema

### Frontend Tests (Manual)
- [ ] `npm run build` completes successfully
- [ ] Frontend loads at `http://localhost:5173`
- [ ] Text input accepts question
- [ ] Sample question buttons appear
- [ ] Submit button sends request to backend
- [ ] Answer text renders
- [ ] Table renders (if present)
- [ ] Chart renders (if present)

### Component Integration Tests
- [ ] Shopify data fetches without POST/PUT/DELETE
- [ ] Agent plans question breakdown
- [ ] Python REPL analyzes data
- [ ] Results structure correctly
- [ ] Frontend displays all response types
- [ ] Error messages show gracefully

### Load / Stress Tests
- [ ] 3 concurrent requests succeed
- [ ] No memory leaks observed
- [ ] Response time < 60 seconds per request
- [ ] CORS headers consistent

---

## Troubleshooting

### Backend not starting
```
Error: Address already in use
Solution: Kill the process on port 8000
  Windows: netstat -ano | findstr :8000 → taskkill /PID [PID] /F
  Linux/Mac: lsof -i :8000 → kill -9 [PID]
```

### Gemini API 429 Quota Exceeded
```
Error: "You exceeded your current quota"
Solution: This is expected if using free tier. Quota resets daily.
         Verify the error handling path still works.
```

### CORS errors in frontend
```
Error: Access-Control-Allow-Origin header missing
Solution: Check backend/.env has GEMINI_API_KEY loaded
         Verify CORSMiddleware in backend/app/main.py
```

### Frontend build fails
```
Error: npm run build fails
Solution: npm install in frontend/ first
         Check Node.js version: node --version (should be 18+)
```

---

## Performance Benchmarks

Typical response times:

| Query Type | Time | Notes |
|-----------|------|-------|
| Health | <10ms | Just returns "ok" |
| Schema | 50-100ms | OpenAPI generation |
| Validation error | <5ms | Pydantic validation |
| CORS preflight | <5ms | Header check |
| Real ask | 15-60s | Agent + Gemini + data analysis |

---

## Success Criteria

The system is ready for production when:

1. ✓ All backend unit tests pass (`pytest`)
2. ✓ All backend API endpoints respond correctly
3. ✓ CORS is configured for frontend origin
4. ✓ Request validation returns proper 422 responses
5. ✓ Real questions generate structured responses
6. ✓ Frontend builds without errors
7. ✓ Frontend can fetch and display responses
8. ✓ All sample questions work end-to-end

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the test output for specific failures
3. Verify configuration files are in place
4. Check that all dependencies are installed
5. Ensure Gemini API key is valid

---

**Last Updated:** 2026-05-06  
**Status:** Production Ready ✓
