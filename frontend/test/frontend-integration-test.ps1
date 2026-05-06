# Shopify AI Agent - Frontend Integration Test
# Validates React app can fetch from backend and render responses correctly

$API_URL = "http://127.0.0.1:8000"
$FRONTEND_URL = "http://localhost:5173"

Write-Host "`n=== SHOPIFY AI AGENT - FRONTEND INTEGRATION TEST ===" -ForegroundColor Yellow
Write-Host "Backend: $API_URL" -ForegroundColor Gray
Write-Host "Frontend: $FRONTEND_URL`n" -ForegroundColor Gray

# 1. Verify Backend is Running
Write-Host "1. Checking Backend Availability" -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "$API_URL/health" -ErrorAction Stop
    Write-Host "  ✓ Backend is running on $API_URL" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Backend is not available at $API_URL" -ForegroundColor Red
    Write-Host "  Please start the backend: uvicorn backend.app.main:app --reload --port 8000" -ForegroundColor Yellow
    exit 1
}

# 2. Test API Response Shape (What Frontend Expects)
Write-Host "`n2. Validating API Response Contract" -ForegroundColor Cyan

$testQuestion = "How many orders were placed in the last 7 days?"
$testBody = @{
    question = $testQuestion
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest `
        -Uri "$API_URL/api/ask" `
        -Method POST `
        -Headers @{ 'Content-Type' = 'application/json' } `
        -Body $testBody `
        -SkipHttpErrorCheck `
        -TimeoutSec 60
    
    if ($response.StatusCode -eq 200) {
        $data = $response.Content | ConvertFrom-Json
        
        # Validate required fields
        $requiredFields = @('answer', 'table', 'chart', 'warnings')
        $missingFields = @()
        
        foreach ($field in $requiredFields) {
            if (-not ($data | Get-Member -Name $field)) {
                $missingFields += $field
            }
        }
        
        if ($missingFields.Count -eq 0) {
            Write-Host "  ✓ Response has all required fields: answer, table, chart, warnings" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Response missing fields: $($missingFields -join ', ')" -ForegroundColor Red
        }
        
        # Validate field types
        Write-Host "  Field Types:" -ForegroundColor Gray
        Write-Host "    - answer: $($data.answer.GetType().Name)" -ForegroundColor Gray
        Write-Host "    - table: $($data.table.GetType().Name) (count: $($data.table.Count))" -ForegroundColor Gray
        Write-Host "    - chart: $($data.chart.GetType().Name)" -ForegroundColor Gray
        Write-Host "    - warnings: $($data.warnings.GetType().Name) (count: $($data.warnings.Count))" -ForegroundColor Gray
        
        # Test Table Structure
        if ($data.table -and $data.table.Count -gt 0) {
            Write-Host "  ✓ Table has rows (first row keys: $($data.table[0].PSObject.Properties.Name -join ', '))" -ForegroundColor Green
        } else {
            Write-Host "  ℹ Table is empty (valid for questions without tabular results)" -ForegroundColor Gray
        }
        
        # Test Chart Structure
        if ($data.chart) {
            $chartKeys = $data.chart.PSObject.Properties.Name
            Write-Host "  ✓ Chart present (type: $($data.chart.type), keys: $($chartKeys -join ', '))" -ForegroundColor Green
        } else {
            Write-Host "  ℹ Chart is null (valid for questions without visual results)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ API returned status $($response.StatusCode)" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ✗ API request failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Test Error Handling
Write-Host "`n3. Testing Error Handling (Invalid Question)" -ForegroundColor Cyan
try {
    $errorBody = @{ question = "" } | ConvertTo-Json
    $response = Invoke-WebRequest `
        -Uri "$API_URL/api/ask" `
        -Method POST `
        -Headers @{ 'Content-Type' = 'application/json' } `
        -Body $errorBody `
        -SkipHttpErrorCheck
    
    if ($response.StatusCode -eq 422) {
        Write-Host "  ✓ Backend correctly rejects empty questions (422)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Expected 422, got $($response.StatusCode)" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ✗ Error test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test Frontend Can Build
Write-Host "`n4. Testing Frontend Build" -ForegroundColor Cyan
if (Test-Path "frontend\package.json") {
    try {
        Push-Location frontend
        $buildOutput = npm run build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Frontend production build succeeds" -ForegroundColor Green
            Write-Host "  Build output: dist/" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ Frontend build failed" -ForegroundColor Red
            Write-Host "  Error: $($buildOutput[-5..-1] -join "`n")" -ForegroundColor Red
        }
        Pop-Location
    }
    catch {
        Write-Host "  ✗ Build test error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ frontend/package.json not found" -ForegroundColor Red
}

# 5. List Sample Questions for Testing
Write-Host "`n5. Sample Questions for Manual Testing" -ForegroundColor Cyan
$sampleQuestions = @(
    "How many orders were placed in the last 7 days?",
    "Which products sold the most last month?",
    "Show a table of revenue by city.",
    "Who are my repeat customers?",
    "What is the AOV (Average Order Value) trend this month?",
    "Can you recommend what product to promote based on sales?",
    "Plot a graph of order volume over the past 4 weeks."
)

foreach ($q in $sampleQuestions) {
    Write-Host "  - $q" -ForegroundColor Gray
}

# 6. CORS Verification
Write-Host "`n6. CORS Configuration Check" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest `
        -Uri "$API_URL/api/ask" `
        -Method OPTIONS `
        -Headers @{
            'Origin' = 'http://localhost:5173'
            'Access-Control-Request-Method' = 'POST'
            'Access-Control-Request-Headers' = 'content-type'
        } `
        -SkipHttpErrorCheck
    
    $corsOrigin = $response.Headers['Access-Control-Allow-Origin']
    if ($corsOrigin -contains 'localhost:5173' -or $corsOrigin -eq 'http://localhost:5173') {
        Write-Host "  ✓ CORS is configured for frontend origin" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ CORS Allow-Origin: $corsOrigin" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ✗ CORS check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== INTEGRATION TEST COMPLETE ===" -ForegroundColor Yellow
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Start backend:   uvicorn backend.app.main:app --reload --port 8000" -ForegroundColor Gray
Write-Host "  2. Start frontend:  cd frontend && npm run dev" -ForegroundColor Gray
Write-Host "  3. Open browser:    http://localhost:5173" -ForegroundColor Gray
Write-Host "  4. Ask questions and verify results render correctly" -ForegroundColor Gray
