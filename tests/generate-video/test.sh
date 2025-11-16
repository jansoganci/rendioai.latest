#!/bin/bash

# Quick Test Script for Generate Video Endpoint
# Usage: ./test.sh [test-case-number]
# Example: ./test.sh 1

# Configuration
SUPABASE_URL="https://ojcnjxzctnwbmupggoxq.supabase.co"
FUNCTION_URL="${SUPABASE_URL}/functions/v1/generate-video"
ANON_KEY="YOUR_ANON_KEY_HERE"  # Replace with your actual anon key

# Test data (replace with actual values from your database)
USER_ID="YOUR_USER_ID_HERE"
THEME_ID="YOUR_THEME_ID_HERE"

# Image URL options (use one of these - all are publicly accessible):
# Option 1: Unsplash (real photos)
IMAGE_URL="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop"

# Option 2: Lorem Picsum (random images)
# IMAGE_URL="https://picsum.photos/800/600"

# Option 3: Placekitten (placeholder)
# IMAGE_URL="https://placekitten.com/800/600"

# Option 4: Your Supabase Storage URL (if you uploaded an image)
# IMAGE_URL="https://ojcnjxzctnwbmupggoxq.supabase.co/storage/v1/object/public/thumbnails/your-image.jpg"

# Generate unique idempotency key
IDEMPOTENCY_KEY=$(uuidgen)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧪 Generate Video Endpoint Test Script${NC}\n"

# Test Case 1: Successful Request
test_case_1() {
  echo -e "${GREEN}Test Case 1: Successful Request${NC}"
  echo "Idempotency Key: $IDEMPOTENCY_KEY"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $IDEMPOTENCY_KEY" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"A beautiful sunset over the ocean with waves crashing\",
      \"image_url\": \"$IMAGE_URL\",
      \"settings\": {
        \"duration\": 4,
        \"resolution\": \"auto\",
        \"aspect_ratio\": \"auto\"
      }
    }" | jq '.'
  
  echo -e "\n${YELLOW}📸 Using image URL: $IMAGE_URL${NC}"
  
  echo -e "\n${YELLOW}✅ Check response for: job_id, status: pending, credits_used: 4${NC}\n"
}

# Test Case 2: Missing user_id
test_case_2() {
  echo -e "${GREEN}Test Case 2: Missing user_id (Validation Error)${NC}"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d "{
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\"
    }" | jq '.'
  
  echo -e "\n${YELLOW}✅ Expected: 400 Bad Request - Missing required fields${NC}\n"
}

# Test Case 3: Missing image_url (required by model)
test_case_3() {
  echo -e "${GREEN}Test Case 3: Missing image_url (Model Requirement Error)${NC}"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\"
    }" | jq '.'
  
  echo -e "\n${YELLOW}✅ Expected: 400 Bad Request - image_url is required${NC}\n"
}

# Test Case 4: Invalid duration
test_case_4() {
  echo -e "${GREEN}Test Case 4: Invalid duration (Settings Validation Error)${NC}"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\",
      \"settings\": {
        \"duration\": 10
      }
    }" | jq '.'
  
  echo -e "\n${YELLOW}✅ Expected: 400 Bad Request - Invalid duration${NC}\n"
}

# Test Case 5: Missing Idempotency-Key
test_case_5() {
  echo -e "${GREEN}Test Case 5: Missing Idempotency-Key Header${NC}"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\"
    }" | jq '.'
  
  echo -e "\n${YELLOW}✅ Expected: 400 Bad Request - Idempotency-Key header required${NC}\n"
}

# Test Case 6: Cost Calculation (8 seconds)
test_case_6() {
  echo -e "${GREEN}Test Case 6: Cost Calculation - 8 seconds${NC}"
  echo "Idempotency Key: $(uuidgen)"
  echo ""
  
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $(uuidgen)" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\",
      \"settings\": {
        \"duration\": 8
      }
    }" | jq '.'
  
  echo -e "\n${YELLOW}📸 Using image URL: $IMAGE_URL${NC}"
  
  echo -e "\n${YELLOW}✅ Expected: credits_used: 8 (8 seconds × $0.1 = 8 credits)${NC}\n"
}

# Test Case 7: Idempotency (duplicate request)
test_case_7() {
  echo -e "${GREEN}Test Case 7: Idempotency Test${NC}"
  local test_key=$(uuidgen)
  echo "Using same Idempotency Key: $test_key"
  echo ""
  
  echo "First request:"
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $test_key" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\"
    }" | jq '.'
  
  echo -e "\n${YELLOW}Second request (same key):${NC}"
  curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "Idempotency-Key: $test_key" \
    -d "{
      \"user_id\": \"$USER_ID\",
      \"theme_id\": \"$THEME_ID\",
      \"prompt\": \"Test prompt\",
      \"image_url\": \"$IMAGE_URL\"
    }" | jq '.'
  
  echo -e "\n${YELLOW}📸 Using image URL: $IMAGE_URL${NC}"
  echo -e "\n${YELLOW}✅ Expected: Second request returns cached response with X-Idempotent-Replay header${NC}\n"
}

# Main menu
if [ -z "$1" ]; then
  echo "Usage: ./test.sh [test-case-number]"
  echo ""
  echo "Available test cases:"
  echo "  1 - Successful Request"
  echo "  2 - Missing user_id"
  echo "  3 - Missing image_url"
  echo "  4 - Invalid duration"
  echo "  5 - Missing Idempotency-Key"
  echo "  6 - Cost Calculation (8 seconds)"
  echo "  7 - Idempotency Test"
  echo ""
  echo "Or run all tests: ./test.sh all"
  exit 1
fi

case "$1" in
  1)
    test_case_1
    ;;
  2)
    test_case_2
    ;;
  3)
    test_case_3
    ;;
  4)
    test_case_4
    ;;
  5)
    test_case_5
    ;;
  6)
    test_case_6
    ;;
  7)
    test_case_7
    ;;
  all)
    test_case_1
    test_case_2
    test_case_3
    test_case_4
    test_case_5
    test_case_6
    test_case_7
    ;;
  *)
    echo -e "${RED}Invalid test case number: $1${NC}"
    exit 1
    ;;
esac

