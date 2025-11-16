#!/bin/bash
# Test script for device-check endpoint
# Tests that backend returns access_token and refresh_token

SUPABASE_URL="https://ojcnjxzctnwbmupggoxq.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"

echo "🧪 Testing device-check endpoint..."
echo "=================================="
echo ""

# Test 1: New user
echo "📋 Test 1: New user (random device_id)"
DEVICE_ID=$(uuidgen)
DEVICE_TOKEN="test-token-$(date +%s | base64)"

echo "Device ID: $DEVICE_ID"
echo ""

RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/device-check" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "apikey: ${ANON_KEY}" \
  -d "{
    \"device_id\": \"${DEVICE_ID}\",
    \"device_token\": \"${DEVICE_TOKEN}\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if tokens are present
if echo "$RESPONSE" | jq -e '.access_token != null and .access_token != ""' > /dev/null 2>&1; then
  ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
  TOKEN_LENGTH=${#ACCESS_TOKEN}
  echo "✅ access_token: PRESENT (length: $TOKEN_LENGTH)"
  if [[ $ACCESS_TOKEN == eyJ* ]]; then
    echo "   ✅ Valid JWT format (starts with eyJ)"
  else
    echo "   ⚠️  Token doesn't look like JWT"
  fi
else
  echo "❌ access_token: MISSING or NULL"
fi

if echo "$RESPONSE" | jq -e '.refresh_token != null and .refresh_token != ""' > /dev/null 2>&1; then
  REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token')
  TOKEN_LENGTH=${#REFRESH_TOKEN}
  echo "✅ refresh_token: PRESENT (length: $TOKEN_LENGTH)"
  if [[ $REFRESH_TOKEN == eyJ* ]]; then
    echo "   ✅ Valid JWT format (starts with eyJ)"
  else
    echo "   ⚠️  Token doesn't look like JWT"
  fi
else
  echo "❌ refresh_token: MISSING or NULL"
fi

echo ""
echo "=================================="
echo ""

# Test 2: Existing user (if you have one)
echo "📋 Test 2: Existing user"
echo "To test with existing user, run:"
echo "  ./test-device-check.sh EXISTING_DEVICE_ID"
echo ""

if [ ! -z "$1" ]; then
  EXISTING_DEVICE_ID="$1"
  echo "Testing with existing device_id: $EXISTING_DEVICE_ID"
  echo ""
  
  RESPONSE2=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/device-check" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ANON_KEY}" \
    -H "apikey: ${ANON_KEY}" \
    -d "{
      \"device_id\": \"${EXISTING_DEVICE_ID}\",
      \"device_token\": \"test-token-existing\"
    }")
  
  echo "Response:"
  echo "$RESPONSE2" | jq '.' 2>/dev/null || echo "$RESPONSE2"
  echo ""
  
  # Check tokens
  if echo "$RESPONSE2" | jq -e '.access_token != null and .access_token != ""' > /dev/null 2>&1; then
    echo "✅ access_token: PRESENT (existing user)"
  else
    echo "❌ access_token: MISSING (existing user) - THIS IS THE BUG WE FIXED!"
  fi
  
  if echo "$RESPONSE2" | jq -e '.refresh_token != null and .refresh_token != ""' > /dev/null 2>&1; then
    echo "✅ refresh_token: PRESENT (existing user)"
  else
    echo "❌ refresh_token: MISSING (existing user) - THIS IS THE BUG WE FIXED!"
  fi
fi

echo ""
echo "=================================="
echo "✅ Test complete!"
echo ""
echo "Next steps:"
echo "1. If tokens are present: ✅ Backend fix is working!"
echo "2. Test iOS app: Build and run, check logs for token storage"
echo "3. Test image upload: Try uploading an image, verify it works"
