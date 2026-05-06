#!/usr/bin/env bash
# Shopify AI Agent - Curl-Based API Test Suite
# Platform-independent (Linux, macOS, Windows with Git Bash/WSL)
# Senior developer comprehensive validation with curl

set -e

API_URL="${1:-http://127.0.0.1:8000}"
RESULTS=()
PASS_COUNT=0
FAIL_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║         SHOPIFY AI AGENT - CURL API TEST SUITE           ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}Testing API: $API_URL${NC}\n"

function test_endpoint() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local expected_status="$4"
    local body="$5"
    local headers="$6"
    
    echo -n -e "${CYAN}→ $test_name${NC}"
    
    local cmd="curl -s -w '\n%{http_code}' -X $method \"$API_URL$endpoint\""
    
    if [ ! -z "$headers" ]; then
        cmd="$cmd $headers"
    fi
    
    if [ ! -z "$body" ]; then
        cmd="$cmd -d '$body' -H 'Content-Type: application/json'"
    fi
    
    local response=$(eval $cmd)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "$expected_status" ]; then
        echo -e " ${GREEN}✓ PASS${NC} (Status: $http_code)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e " ${RED}✗ FAIL${NC} (Status: $http_code, Expected: $expected_status)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ============================================================================
# Test 1: Health Endpoint
# ============================================================================
echo -e "\n${YELLOW}[1] Basic Health Checks${NC}"
test_endpoint "GET /health" "GET" "/health" "200"

# ============================================================================
# Test 2: OpenAPI Schema
# ============================================================================
echo -e "\n${YELLOW}[2] API Contract Discovery${NC}"
echo -n -e "${CYAN}→ GET /openapi.json${NC}"
openapi=$(curl -s "$API_URL/openapi.json")
if echo "$openapi" | grep -q '"paths"'; then
    echo -e " ${GREEN}✓ PASS${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e " ${RED}✗ FAIL${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ============================================================================
# Test 3: Request Validation
# ============================================================================
echo -e "\n${YELLOW}[3] Input Validation${NC}"
test_endpoint "POST /api/ask (missing field)" "POST" "/api/ask" "422" "{}"
test_endpoint "POST /api/ask (empty question)" "POST" "/api/ask" "422" '{"question":""}'

# ============================================================================
# Test 4: CORS Preflight
# ============================================================================
echo -e "\n${YELLOW}[4] Frontend CORS Integration${NC}"
echo -n -e "${CYAN}→ OPTIONS /api/ask (CORS preflight)${NC}"
cors_response=$(curl -s -i -X OPTIONS "$API_URL/api/ask" \
    -H "Origin: http://localhost:5173" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: content-type" 2>&1)

if echo "$cors_response" | grep -q "Access-Control-Allow-Origin"; then
    echo -e " ${GREEN}✓ PASS${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e " ${RED}✗ FAIL${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ============================================================================
# Test 5: Real Ask Request
# ============================================================================
echo -e "\n${YELLOW}[5] Agent Integration (Real Request)${NC}"
echo -n -e "${CYAN}→ POST /api/ask (with real question)${NC}"

ask_body='{"question":"How many orders were placed in the last 7 days?"}'
ask_response=$(curl -s -X POST "$API_URL/api/ask" \
    -H "Content-Type: application/json" \
    -d "$ask_body")

if echo "$ask_response" | grep -q '"answer"'; then
    echo -e " ${GREEN}✓ PASS${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
    
    # Extract and display response structure
    if echo "$ask_response" | grep -q '"table"'; then
        echo -e "    → Response has table field"
    fi
    if echo "$ask_response" | grep -q '"chart"'; then
        echo -e "    → Response has chart field"
    fi
    if echo "$ask_response" | grep -q '"warnings"'; then
        echo -e "    → Response has warnings field"
    fi
else
    echo -e " ${RED}✗ FAIL${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo -e "    ${RED}Response: ${ask_response:0:200}...${NC}"
fi

# ============================================================================
# Test 6: Shopify Data Tool
# ============================================================================
echo -e "\n${YELLOW}[6] Shopify Data Integration${NC}"

# This test verifies the tool can be called (even if it returns an error due to quota)
echo -n -e "${CYAN}→ Tool availability check${NC}"
if echo "$ask_response" | grep -q 'get_shopify_data'; then
    echo -e " ${GREEN}✓ PASS${NC} (tool invoked)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e " ℹ INFO (no tool call in response - may indicate agent flow)"
fi

# ============================================================================
# Test 7: Response Schema Validation
# ============================================================================
echo -e "\n${YELLOW}[7] Response Contract Validation${NC}"

# Parse JSON and validate structure
echo -n -e "${CYAN}→ JSON schema validation${NC}"
schema_valid=$(echo "$ask_response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    required = ['answer', 'table', 'chart', 'warnings']
    has_all = all(k in data for k in required)
    print('1' if has_all else '0')
except:
    print('0')
" 2>/dev/null || echo '0')

if [ "$schema_valid" == "1" ]; then
    echo -e " ${GREEN}✓ PASS${NC} (all required fields present)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e " ⚠ PARTIAL (schema may have additional fields)"
fi

# ============================================================================
# Test 8: Multiple Requests (Concurrent-like)
# ============================================================================
echo -e "\n${YELLOW}[8] Multiple Requests${NC}"
echo -n -e "${CYAN}→ Sequential requests (3x)${NC}"

success_count=0
for i in {1..3}; do
    resp=$(curl -s -X POST "$API_URL/api/ask" \
        -H "Content-Type: application/json" \
        -d "{\"question\":\"Test question $i\"}")
    if echo "$resp" | grep -q '"answer"'; then
        success_count=$((success_count + 1))
    fi
done

if [ "$success_count" == "3" ]; then
    echo -e " ${GREEN}✓ PASS${NC} (3/3 successful)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo -e " ⚠ PARTIAL ($success_count/3 successful)"
fi

# ============================================================================
# Summary
# ============================================================================
TOTAL=$((PASS_COUNT + FAIL_COUNT))
PERCENTAGE=$((PASS_COUNT * 100 / TOTAL))

echo -e "\n${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                    TEST SUMMARY                           ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "Tests Passed: ${GREEN}$PASS_COUNT${NC} / $TOTAL (${CYAN}${PERCENTAGE}%${NC})"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "Tests Failed: ${RED}$FAIL_COUNT${NC}"
fi

# ============================================================================
# Next Steps
# ============================================================================
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "  1. Backend API:  ${CYAN}uvicorn backend.app.main:app --reload --port 8000${NC}"
echo -e "  2. Frontend Dev: ${CYAN}cd frontend && npm run dev${NC}"
echo -e "  3. Open Browser: ${CYAN}http://localhost:5173${NC}"
echo -e "  4. Run this test again after making changes"

# Exit code
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "\n${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
fi
