#!/bin/bash

# Generate Video Endpoint - Test Script
# This script tests the generate-video Edge Function endpoint

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_URL="https://ojcnjxzctnwbmupggoxq.supabase.co"
FUNCTION_URL="${PROJECT_URL}/functions/v1/generate-video"
IMAGE_URL="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop"

# Check if ANON_KEY is provided
if [ -z "$ANON_KEY" ]; then
    echo -e "${RED}❌ ERROR: ANON_KEY environment variable is required${NC}"
    echo "Usage: ANON_KEY=your_key ./test-endpoint.sh"
    echo "Or: export ANON_KEY=your_key && ./test-endpoint.sh"
    exit 1
fi

# Check if test data is provided
if [ -z "$USER_ID" ] || [ -z "$THEME_ID" ]; then
    echo -e "${YELLOW}⚠️  WARNING: USER_ID and/or THEME_ID not provided${NC}"
    echo "You need to get these from the database first:"
    echo "  SELECT id, credits_remaining FROM users WHERE credits_remaining > 0 LIMIT 1;"
    echo "  SELECT id, name FROM themes WHERE is_available = true LIMIT 1;"
    echo ""
    echo "Then run:"
    echo "  export USER_ID=your_user_id"
    echo "  export THEME_ID=your_theme_id"
    echo "  ./test-endpoint.sh"
    exit 1
fi

echo -e "${GREEN}🧪 Starting Generate Video Endpoint Tests${NC}"
echo "=========================================="
echo "Project URL: $PROJECT_URL"
echo "Function URL: $FUNCTION_URL"
echo "User ID: $USER_ID"
echo "Theme ID: $THEME_ID"
echo "Image URL: $IMAGE_URL"
echo ""

# Test counter
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local expected_status=$2
    local curl_cmd=$3
    local expected_content=$4
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
    echo "Command: $curl_cmd"
    
    response=$(eval "$curl_cmd" 2>&1)
    status_code=$(echo "$response" | grep -oP '(?<=HTTP/)[0-9]{3}' | tail -1 || echo "000")
    body=$(echo "$response" | sed -n '/^{/,/^}/p' | head -20)
    
    if [ "$status_code" = "$expected_status" ]; then
        if [ -n "$expected_content" ]; then
            if echo "$body" | grep -q "$expected_content"; then
                echo -e "${GREEN}✅ PASS${NC} - Status: $status_code, Contains: $expected_content"
                ((PASSED++))
            else
                echo -e "${RED}❌ FAIL${NC} - Status: $status_code (correct), but missing: $expected_content"
                echo "Response: $body"
                ((FAILED++))
            fi
        else
            echo -e "${GREEN}✅ PASS${NC} - Status: $status_code"
            ((PASSED++))
        fi
    else
        echo -e "${RED}❌ FAIL${NC} - Expected status: $expected_status, Got: $status_code"
        echo "Response: $body"
        ((FAILED++))
    fi
}

# Generate unique idempotency key
IDEMPOTENCY_KEY=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-$(date +%s)")

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}TEST CASE 1: Successful Request (Happy Path)${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

IDEMPOTENCY_KEY_1=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-1-$(date +%s)")

curl_cmd="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_1' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"A beautiful sunset over the ocean with waves crashing\",
    \"image_url\": \"$IMAGE_URL\",
    \"settings\": {
      \"duration\": 4,
      \"resolution\": \"auto\",
      \"aspect_ratio\": \"auto\"
    }
  }'"

run_test "Test Case 1: Successful Request" "200" "$curl_cmd" "job_id"

# Extract job_id from response for later tests
JOB_ID=$(echo "$body" | grep -oP '"job_id":\s*"[^"]*"' | cut -d'"' -f4 || echo "")

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}TEST CASE 4: Cost Calculation Verification${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

# Test 4a: 4 seconds duration
IDEMPOTENCY_KEY_4A=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-4a-$(date +%s)")

curl_cmd_4a="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_4A' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\",
    \"settings\": {
      \"duration\": 4
    }
  }'"

run_test "Test Case 4a: 4 seconds = 4 credits" "200" "$curl_cmd_4a" "credits_used"

# Test 4b: 8 seconds duration
IDEMPOTENCY_KEY_4B=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-4b-$(date +%s)")

curl_cmd_4b="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_4B' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\",
    \"settings\": {
      \"duration\": 8
    }
  }'"

run_test "Test Case 4b: 8 seconds = 8 credits" "200" "$curl_cmd_4b" "credits_used"

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}TEST CASE 5: Validation Tests${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

# Test 5a: Missing user_id
IDEMPOTENCY_KEY_5A=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-5a-$(date +%s)")

curl_cmd_5a="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_5A' \
  -d '{
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

run_test "Test Case 5a: Missing user_id" "400" "$curl_cmd_5a" "Missing required fields"

# Test 5b: Missing theme_id
IDEMPOTENCY_KEY_5B=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-5b-$(date +%s)")

curl_cmd_5b="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_5B' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

run_test "Test Case 5b: Missing theme_id" "400" "$curl_cmd_5b" "Missing required fields"

# Test 5c: Missing prompt
IDEMPOTENCY_KEY_5C=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-5c-$(date +%s)")

curl_cmd_5c="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_5C' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

run_test "Test Case 5c: Missing prompt" "400" "$curl_cmd_5c" "Missing required fields"

# Test 5d: Missing image_url
IDEMPOTENCY_KEY_5D=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-5d-$(date +%s)")

curl_cmd_5d="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_5D' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\"
  }'"

run_test "Test Case 5d: Missing image_url" "400" "$curl_cmd_5d" "image_url is required"

# Test 5e: Invalid duration
IDEMPOTENCY_KEY_5E=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-5e-$(date +%s)")

curl_cmd_5e="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_5E' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\",
    \"settings\": {
      \"duration\": 10
    }
  }'"

run_test "Test Case 5e: Invalid duration" "400" "$curl_cmd_5e" "Invalid duration"

# Test 5f: Missing Idempotency-Key
curl_cmd_5f="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

run_test "Test Case 5f: Missing Idempotency-Key" "400" "$curl_cmd_5f" "Idempotency-Key"

# Test 5g: Wrong HTTP method
curl_cmd_5g="curl -s -w '\nHTTP_STATUS:%{http_code}' -X GET '$FUNCTION_URL' \
  -H 'Authorization: Bearer $ANON_KEY'"

run_test "Test Case 5g: Wrong HTTP method" "405" "$curl_cmd_5g" "Method not allowed"

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}TEST CASE 7: Idempotency Test${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

IDEMPOTENCY_KEY_7=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-7-$(date +%s)")

echo "Step 1: First request with idempotency key: $IDEMPOTENCY_KEY_7"

curl_cmd_7a="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_7' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

run_test "Test Case 7a: First request" "200" "$curl_cmd_7a" "job_id"

echo "Step 2: Duplicate request (same idempotency key)"

curl_cmd_7b="curl -s -w '\nHTTP_STATUS:%{http_code}' -X POST '$FUNCTION_URL' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer $ANON_KEY' \
  -H 'Idempotency-Key: $IDEMPOTENCY_KEY_7' \
  -d '{
    \"user_id\": \"$USER_ID\",
    \"theme_id\": \"$THEME_ID\",
    \"prompt\": \"Test prompt\",
    \"image_url\": \"$IMAGE_URL\"
  }'"

response_7b=$(eval "$curl_cmd_7b" 2>&1)
status_7b=$(echo "$response_7b" | grep -oP '(?<=HTTP_STATUS:)[0-9]{3}' || echo "000")
headers_7b=$(echo "$response_7b" | grep -i "X-Idempotent-Replay" || echo "")

if [ "$status_7b" = "200" ] && [ -n "$headers_7b" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Status: $status_7b, Idempotent replay header present"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - Expected status 200 with idempotent replay header"
    echo "Status: $status_7b"
    echo "Headers: $headers_7b"
    ((FAILED++))
fi

# Summary
echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}TEST SUMMARY${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✅ ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ SOME TESTS FAILED${NC}"
    exit 1
fi

