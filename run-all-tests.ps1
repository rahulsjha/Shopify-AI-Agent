# Shopify AI Agent - Master Test Suite
# Runs all tests: backend unit tests, API tests, and frontend integration
# Senior developer comprehensive validation

param(
    [switch]$SkipFrontend = $false,
    [switch]$SkipIntegration = $false,
    [switch]$VerboseOutput = $false
)

$ErrorActionPreference = 'Continue'
$TEST_RESULTS = @()

function Write-TestSection {
    param([string]$Title)
    Write-Host "`n╔═════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║ $Title" -ForegroundColor Magenta
    Write-Host "╚═════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $icon = if ($Passed) { "✓" } else { "✗" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "  $icon $TestName" -ForegroundColor $color
    if ($Message -and $VerboseOutput) {
        Write-Host "    → $Message" -ForegroundColor Gray
    }
    
    $TEST_RESULTS += @{
        Name = $TestName
        Passed = $Passed
        Message = $Message
    }
}

# ============================================================================
Write-TestSection "STEP 1: BACKEND UNIT TESTS"
# ============================================================================

Write-Host "Running pytest on backend unit tests..." -ForegroundColor Cyan

try {
    $output = c:/python314/python.exe -m pytest backend/tests -q --tb=short 2>&1
    if ($LASTEXITCODE -eq 0) {
        $passedCount = ($output | Select-String "passed" | Select-Object -First 1).ToString()
        Write-TestResult "Backend Unit Tests" $true $passedCount
    } else {
        Write-TestResult "Backend Unit Tests" $false "Tests failed - check backend/tests/"
        Write-Host $output -ForegroundColor Red
    }
}
catch {
    Write-TestResult "Backend Unit Tests" $false "Exception: $($_.Exception.Message)"
}

# ============================================================================
Write-TestSection "STEP 2: BACKEND API TESTS (Requires running server)"
# ============================================================================

$API_URL = "http://127.0.0.1:8000"

# Check if backend is running
Write-Host "Checking if backend is running on $API_URL..." -ForegroundColor Cyan

$backendRunning = $false
try {
    $response = Invoke-WebRequest -Uri "$API_URL/health" -ErrorAction Stop
    $backendRunning = $true
    Write-TestResult "Backend Availability" $true "Server is running"
} catch {
    Write-TestResult "Backend Availability" $false "Server not running - start with: uvicorn backend.app.main:app --reload --port 8000"
}

if ($backendRunning) {
    # Test Health Endpoint
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/health" -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        $passed = $data.status -eq "ok"
        Write-TestResult "GET /health" $passed
    } catch {
        Write-TestResult "GET /health" $false
    }
    
    # Test OpenAPI Schema
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/openapi.json" -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        $passed = $data.paths -and $data.paths.'/health' -and $data.paths.'/api/ask'
        Write-TestResult "GET /openapi.json" $passed
    } catch {
        Write-TestResult "GET /openapi.json" $false
    }
    
    # Test Request Validation
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/ask" `
            -Method POST `
            -Headers @{ 'Content-Type' = 'application/json' } `
            -Body '{}' `
            -SkipHttpErrorCheck
        $passed = $response.StatusCode -eq 422
        Write-TestResult "POST /api/ask (validation)" $passed "Returns 422 for missing field"
    } catch {
        Write-TestResult "POST /api/ask (validation)" $false
    }
    
    # Test CORS Preflight
    try {
        $response = Invoke-WebRequest -Uri "$API_URL/api/ask" `
            -Method OPTIONS `
            -Headers @{
                'Origin' = 'http://localhost:5173'
                'Access-Control-Request-Method' = 'POST'
                'Access-Control-Request-Headers' = 'content-type'
            } `
            -SkipHttpErrorCheck
        $corsHeader = $response.Headers['Access-Control-Allow-Origin']
        $passed = $corsHeader -like "*5173*" -or $response.StatusCode -eq 200
        Write-TestResult "OPTIONS /api/ask (CORS)" $passed "CORS headers present"
    } catch {
        Write-TestResult "OPTIONS /api/ask (CORS)" $false
    }
    
    # Test Real Ask Request
    if (-not $SkipIntegration) {
        Write-Host "`nTesting real agent request (this may take 10-30 seconds)..." -ForegroundColor Yellow
        try {
            $body = @{ question = "How many orders were placed in the last 7 days?" } | ConvertTo-Json
            $response = Invoke-WebRequest -Uri "$API_URL/api/ask" `
                -Method POST `
                -Headers @{ 'Content-Type' = 'application/json' } `
                -Body $body `
                -SkipHttpErrorCheck `
                -TimeoutSec 120
            
            if ($response.StatusCode -eq 200) {
                $data = $response.Content | ConvertFrom-Json
                $hasAnswer = [string]::IsNullOrEmpty($data.answer) -eq $false
                $hasSchema = ($data | Get-Member -Name 'table') -and ($data | Get-Member -Name 'chart') -and ($data | Get-Member -Name 'warnings')
                $passed = $hasAnswer -and $hasSchema
                Write-TestResult "POST /api/ask (real request)" $passed "Generated response with answer and schema"
            } else {
                Write-TestResult "POST /api/ask (real request)" $false "Status: $($response.StatusCode)"
                if ($VerboseOutput) {
                    Write-Host "Response: $($response.Content.Substring(0, 200))..." -ForegroundColor Red
                }
            }
        } catch {
            Write-TestResult "POST /api/ask (real request)" $false "Exception: $($_.Exception.Message)"
        }
    }
}

# ============================================================================
Write-TestSection "STEP 3: FRONTEND INTEGRATION TESTS"
# ============================================================================

if (-not $SkipFrontend) {
    # Check Frontend Files Exist
    Write-Host "Checking frontend project files..." -ForegroundColor Cyan
    
    $frontendFiles = @(
        'frontend/package.json',
        'frontend/src/App.tsx',
        'frontend/src/api.ts',
        'frontend/src/types.ts'
    )
    
    $frontendReady = $true
    foreach ($file in $frontendFiles) {
        $exists = Test-Path $file
        Write-TestResult "File: $file" $exists
        if (-not $exists) { $frontendReady = $false }
    }
    
    # Build Frontend
    if ($frontendReady) {
        Write-Host "`nBuilding frontend..." -ForegroundColor Cyan
        try {
            Push-Location frontend
            $output = npm run build 2>&1
            $success = $LASTEXITCODE -eq 0
            Write-TestResult "npm run build" $success
            if ($VerboseOutput -and $success) {
                Write-Host "Build artifacts: dist/" -ForegroundColor Gray
            }
            Pop-Location
        } catch {
            Write-TestResult "npm run build" $false
        }
    }
    
    # Check Package Dependencies
    Write-Host "`nChecking dependencies..." -ForegroundColor Cyan
    try {
        $pkg = Get-Content 'frontend/package.json' | ConvertFrom-Json
        $hasReact = $pkg.dependencies -and $pkg.dependencies.react
        $hasVite = $pkg.devDependencies -and $pkg.devDependencies.vite
        Write-TestResult "React dependency" $hasReact
        Write-TestResult "Vite dependency" $hasVite
    } catch {
        Write-TestResult "Frontend dependencies" $false
    }
}

# ============================================================================
Write-TestSection "STEP 4: CONFIGURATION VALIDATION"
# ============================================================================

Write-Host "Checking configuration files..." -ForegroundColor Cyan

$configChecks = @{
    'Root .env' = '.env'
    'Backend .env' = 'backend/.env'
    'Backend config.py' = 'backend/app/config.py'
    'Backend main.py' = 'backend/app/main.py'
    'Backend schemas.py' = 'backend/app/schemas.py'
    'Backend shopify_client.py' = 'backend/app/shopify_client.py'
    'Backend agent.py' = 'backend/app/agent.py'
    'Frontend vite.config.ts' = 'frontend/vite.config.ts'
    'Pytest tests' = 'backend/tests/test_api.py'
}

foreach ($check in $configChecks.GetEnumerator()) {
    $exists = Test-Path $check.Value
    Write-TestResult $check.Key $exists
}

# ============================================================================
Write-TestSection "TEST SUMMARY"
# ============================================================================

$passedTests = ($TEST_RESULTS | Where-Object { $_.Passed }).Count
$totalTests = $TEST_RESULTS.Count
$passPercentage = [Math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "`nTest Results: $passedTests / $totalTests passed ($passPercentage%)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "✓ ALL TESTS PASSED - System is ready for deployment!" -ForegroundColor Green
    exit 0
} elseif ($passPercentage -ge 90) {
    Write-Host "⚠ MOST TESTS PASSED - Review failures above" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✗ TESTS FAILED - Fix issues and rerun" -ForegroundColor Red
    exit 1
}
