# Shopify AI Agent - Backend E2E Test Suite
# Senior Developer Test Script
# Validates all API endpoints, request validation, CORS, and agent integration

$API_URL = "http://127.0.0.1:8000"
$RESULTS = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Headers = @{},
        [string]$Body = "",
        [int[]]$ExpectedStatus = @(200)
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Cyan
    
    try {
        $params = @{
            Uri = "$API_URL$Endpoint"
            Method = $Method
            Headers = $Headers
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params['Body'] = $Body
            $params['ContentType'] = 'application/json'
        }
        
        $response = Invoke-WebRequest @params -SkipHttpErrorCheck
        
        $passed = $ExpectedStatus -contains $response.StatusCode
        $status = if ($passed) { "✓ PASS" } else { "✗ FAIL" }
        
        Write-Host "  Status: $($response.StatusCode) - $status" -ForegroundColor $(if ($passed) { 'Green' } else { 'Red' })
        
        if ($response.Content) {
            $content = $response.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            Write-Host "  Response: $($response.Content.Substring(0, [Math]::Min(120, $response.Content.Length)))..." -ForegroundColor Gray
        }
        
        $RESULTS += @{
            Test = $Name
            Status = $status
            Code = $response.StatusCode
            Expected = $ExpectedStatus
        }
        
        return $response
    }
    catch {
        Write-Host "  ✗ FAIL - Error: $($_.Exception.Message)" -ForegroundColor Red
        $RESULTS += @{
            Test = $Name
            Status = "✗ FAIL"
            Code = "ERR"
            Expected = $ExpectedStatus
        }
        return $null
    }
}

Write-Host "`n=== SHOPIFY AI AGENT - BACKEND E2E TEST SUITE ===" -ForegroundColor Yellow
Write-Host "Testing: $API_URL`n" -ForegroundColor Gray

# 1. Health Check
Test-Endpoint -Name "1. Health Check" -Method GET -Endpoint "/health" -ExpectedStatus @(200) | Out-Null

# 2. OpenAPI Schema Discovery
$openapi = Test-Endpoint -Name "2. OpenAPI Schema" -Method GET -Endpoint "/openapi.json" -ExpectedStatus @(200)

# 3. Request Validation - Missing Question Field
Test-Endpoint -Name "3. Request Validation (Missing Field)" `
    -Method POST `
    -Endpoint "/api/ask" `
    -Headers @{ 'Content-Type' = 'application/json' } `
    -Body '{}' `
    -ExpectedStatus @(422) | Out-Null

# 4. Request Validation - Empty Question
Test-Endpoint -Name "4. Request Validation (Empty Question)" `
    -Method POST `
    -Endpoint "/api/ask" `
    -Headers @{ 'Content-Type' = 'application/json' } `
    -Body '{"question":""}' `
    -ExpectedStatus @(422) | Out-Null

# 5. CORS Preflight for Frontend
Test-Endpoint -Name "5. CORS Preflight (React Frontend)" `
    -Method OPTIONS `
    -Endpoint "/api/ask" `
    -Headers @{
        'Origin' = 'http://localhost:5173'
        'Access-Control-Request-Method' = 'POST'
        'Access-Control-Request-Headers' = 'content-type'
    } `
    -ExpectedStatus @(200) | Out-Null

# 6. Real Ask Request - Sample Question
Write-Host "`nTesting: 6. Real Ask Request (Agent Integration)" -ForegroundColor Cyan
try {
    $body = @{
        question = "How many orders were placed in the last 7 days?"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest `
        -Uri "$API_URL/api/ask" `
        -Method POST `
        -Headers @{ 'Content-Type' = 'application/json' } `
        -Body $body `
        -SkipHttpErrorCheck
    
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor $(if ($response.StatusCode -eq 200) { 'Green' } else { 'Red' })
    
    if ($response.StatusCode -eq 200) {
        $data = $response.Content | ConvertFrom-Json
        
        Write-Host "  Response Schema:" -ForegroundColor Gray
        Write-Host "    - answer: $($data.answer.Length) chars" -ForegroundColor Gray
        Write-Host "    - table rows: $($data.table.Count)" -ForegroundColor Gray
        Write-Host "    - chart: $(if ($data.chart) { $data.chart.type } else { 'null' })" -ForegroundColor Gray
        Write-Host "    - warnings: $($data.warnings.Count)" -ForegroundColor Gray
        
        if ($data.answer -and $data.answer.Length -gt 0) {
            Write-Host "  ✓ PASS" -ForegroundColor Green
            $RESULTS += @{
                Test = "6. Real Ask Request"
                Status = "✓ PASS"
                Code = 200
                Expected = @(200)
            }
        } else {
            Write-Host "  ✗ FAIL - Empty answer" -ForegroundColor Red
            $RESULTS += @{
                Test = "6. Real Ask Request"
                Status = "✗ FAIL"
                Code = 200
                Expected = @(200)
            }
        }
    } else {
        Write-Host "  ✗ FAIL - Status $($response.StatusCode)" -ForegroundColor Red
        Write-Host "  Error: $($response.Content)" -ForegroundColor Gray
        $RESULTS += @{
            Test = "6. Real Ask Request"
            Status = "✗ FAIL"
            Code = $response.StatusCode
            Expected = @(200)
        }
    }
}
catch {
    Write-Host "  ✗ FAIL - Exception: $($_.Exception.Message)" -ForegroundColor Red
    $RESULTS += @{
        Test = "6. Real Ask Request"
        Status = "✗ FAIL"
        Code = "ERR"
        Expected = @(200)
    }
}

# 7. Multiple Concurrent Requests (Concurrency Test)
Write-Host "`nTesting: 7. Concurrent Requests" -ForegroundColor Cyan
$jobs = @()
$questions = @(
    "What is the AOV trend this month?",
    "Who are my repeat customers?",
    "Which products sold the most last month?"
)

foreach ($q in $questions) {
    $job = Start-Job -ScriptBlock {
        param($url, $question)
        try {
            $body = @{ question = $question } | ConvertTo-Json
            $response = Invoke-WebRequest `
                -Uri "$url/api/ask" `
                -Method POST `
                -Headers @{ 'Content-Type' = 'application/json' } `
                -Body $body `
                -SkipHttpErrorCheck `
                -TimeoutSec 120
            
            return @{ Status = $response.StatusCode; Success = $response.StatusCode -eq 200 }
        }
        catch {
            return @{ Status = "Error"; Success = $false }
        }
    } -ArgumentList $API_URL, $q
    $jobs += $job
}

$results = $jobs | Wait-Job | Receive-Job
$passed = ($results | Where-Object { $_.Success }).Count
Write-Host "  Concurrent requests: $passed/$($results.Count) succeeded" -ForegroundColor $(if ($passed -eq $results.Count) { 'Green' } else { 'Yellow' })

$RESULTS += @{
    Test = "7. Concurrent Requests"
    Status = $(if ($passed -eq $results.Count) { "✓ PASS" } else { "⚠ PARTIAL" })
    Code = $passed
    Expected = "3/3"
}

# Summary Report
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
$passed_count = ($RESULTS | Where-Object { $_.Status -eq "✓ PASS" }).Count
$total_count = $RESULTS.Count

foreach ($result in $RESULTS) {
    Write-Host "$($result.Status) $($result.Test) (Status: $($result.Code))" -ForegroundColor $(if ($result.Status -like "✓*") { 'Green' } else { 'Red' })
}

Write-Host "`nTotal: $passed_count/$total_count tests passed" -ForegroundColor $(if ($passed_count -eq $total_count) { 'Green' } else { 'Yellow' })

if ($passed_count -eq $total_count) {
    Write-Host "`n✓ ALL TESTS PASSED - Backend is ready for production" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠ Some tests failed - Review the output above" -ForegroundColor Yellow
    exit 1
}
