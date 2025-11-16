#!/bin/bash
# Test with existing user to verify fix

SUPABASE_URL="https://ojcnjxzctnwbmupggoxq.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"

# Use the device_id from your logs: 907c2698-8289-4ac8-be9b-5a2a092a0044
EXISTING_DEVICE_ID="907c2698-8289-4ac8-be9b-5a2a092a0044"

echo "🧪 Testing device-check with EXISTING user..."
echo "Device ID: $EXISTING_DEVICE_ID"
echo ""

RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/device-check" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "apikey: ${ANON_KEY}" \
  -d "{
    \"device_id\": \"${EXISTING_DEVICE_ID}\",
    \"device_token\": \"test-token-$(date +%s)\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.'
echo ""

# Critical check: Does existing user get tokens?
if echo "$RESPONSE" | jq -e '.access_token != null and .access_token != ""' > /dev/null 2>&1; then
  ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
  echo "✅ SUCCESS: Existing user got access_token!"
  echo "   Token length: ${#ACCESS_TOKEN}"
  echo "   Token preview: ${ACCESS_TOKEN:0:50}..."
else
  echo "❌ FAILED: Existing user did NOT get access_token"
  echo "   This means the fix didn't work!"
fi

if echo "$RESPONSE" | jq -e '.refresh_token != null and .refresh_token != ""' > /dev/null 2>&1; then
  REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token')
  echo "✅ SUCCESS: Existing user got refresh_token!"
  echo "   Token length: ${#REFRESH_TOKEN}"
else
  echo "❌ FAILED: Existing user did NOT get refresh_token"
fi

echo ""
echo "=================================="
echo "Test Summary:"
if echo "$RESPONSE" | jq -e '.access_token != null and .access_token != ""' > /dev/null 2>&1; then
  echo "✅ FIX VERIFIED: Backend is returning tokens for existing users!"
else
  echo "❌ FIX FAILED: Backend still returning null tokens"
fi
