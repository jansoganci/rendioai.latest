# 🧪 Generate Video Endpoint - Complete Testing Guide

Complete guide for testing the `generate-video` Edge Function endpoint.

---

## 📋 Prerequisites

### 1. Get Test Data

**Run these SQL queries in Supabase Dashboard → SQL Editor:**

```sql
-- Get USER_ID (user with credits)
SELECT id, credits_remaining FROM users WHERE credits_remaining > 0 LIMIT 1;

-- Get THEME_ID (available theme)
SELECT id, name FROM themes WHERE is_available = true LIMIT 1;

-- Verify active model exists
SELECT id, name, provider_model_id, pricing_type, base_price 
FROM models WHERE is_active = true AND is_available = true;
```

### 2. Get ANON_KEY

1. Go to Supabase Dashboard
2. Project Settings → API
3. Copy the **"anon"** key (public key)

### 3. Set Environment Variables

```bash
export ANON_KEY="your_anon_key"
export USER_ID="your_user_id"
export THEME_ID="your_theme_id"
```

### 4. Image URL Options

**Recommended (Unsplash):**
```bash
IMAGE_URL="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop"
```

**Other options:**
- `https://picsum.photos/800/600`
- `https://placekitten.com/800/600`

**⚠️ Do NOT use `example.com` - causes 422 errors from FalAI**

---

## 🧪 Test Cases

### Test Case 1: Successful Request (Happy Path)

**Purpose:** Verify complete flow works end-to-end

**Command:**
```bash
IDEMPOTENCY_KEY=$(uuidgen)

curl -X POST https://ojcnjxzctnwbmupggoxq.supabase.co/functions/v1/generate-video \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Idempotency-Key: $IDEMPOTENCY_KEY" \
  -d '{
    "user_id": "'$USER_ID'",
    "theme_id": "'$THEME_ID'",
    "prompt": "A beautiful sunset over the ocean",
    "image_url": "'$IMAGE_URL'",
    "settings": {
      "duration": 4,
      "resolution": "auto",
      "aspect_ratio": "auto"
    }
  }'
```

**Expected:**
- Status: `200 OK`
- Response: `{"job_id": "uuid", "status": "pending", "credits_used": 4}`

---

### Test Case 2: Cost Calculation

**4 seconds = 4 credits:**
```bash
# Same as Test 1, with duration: 4
# Expected: credits_used: 4
```

**8 seconds = 8 credits:**
```bash
# Change settings.duration to 8
# Expected: credits_used: 8
```

---

### Test Case 3: Validation Tests

**Missing user_id:**
```bash
curl -X POST [endpoint] \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"theme_id": "'$THEME_ID'", "prompt": "test", "image_url": "'$IMAGE_URL'"}'
```
**Expected:** `400 Bad Request` - "Missing required fields"

**Missing theme_id:**
```bash
# Omit theme_id from request
```
**Expected:** `400 Bad Request`

**Missing prompt:**
```bash
# Omit prompt from request
```
**Expected:** `400 Bad Request`

**Missing image_url:**
```bash
# Omit image_url from request
```
**Expected:** `400 Bad Request` - "image_url is required"

**Missing Idempotency-Key:**
```bash
# Omit Idempotency-Key header
```
**Expected:** `400 Bad Request` - "Idempotency-Key header required"

**Wrong HTTP method:**
```bash
curl -X GET [endpoint] -H "Authorization: Bearer $ANON_KEY"
```
**Expected:** `405 Method Not Allowed`

---

### Test Case 4: Idempotency

**Step 1:** Make first request with idempotency key
```bash
IDEMPOTENCY_KEY=$(uuidgen)
# Make request with this key
```

**Step 2:** Make duplicate request with same key
```bash
# Use same IDEMPOTENCY_KEY
# Make identical request
```

**Expected:**
- Status: `200 OK`
- Header: `X-Idempotent-Replay: true`
- Same `job_id` as first request
- No duplicate credit deduction

---

### Test Case 5: Error Cases

**No active model:**
- Deactivate all models in database
- **Expected:** `404 Not Found` - "No active model found"

**Theme not found:**
- Use invalid theme_id
- **Expected:** `404 Not Found` - "Theme not found"

**Insufficient credits:**
- Use user with 0 credits
- **Expected:** `402 Payment Required` - "Insufficient credits"

---

## 🚀 Running Tests

### Option 1: Automated Script

```bash
cd tests/generate-video
export ANON_KEY="your_key"
export USER_ID="your_user_id"
export THEME_ID="your_theme_id"
./test-endpoint.sh
```

### Option 2: Manual Testing

Use the commands from test cases above.

---

## 🆘 Troubleshooting

**"No users found"**
- Create a user via `device-check` endpoint
- Or manually insert user in database

**"No themes found"**
- Run migration: `20251106000004_insert_test_data.sql`
- Creates 5 test themes

**"No active model found"**
- Run migration: `20251106000004_insert_test_data.sql`
- Sets up Sora 2 model as active

**"Invalid ANON_KEY"**
- Use **anon** key (public), NOT service_role key
- Get from Dashboard → Project Settings → API

**"Model not found" or "Missing required fields: user_id, model_id, prompt"**
- ⚠️ **Deployment issue:** Deployed code expects `model_id`, but codebase uses `theme_id`
- **Solution:** Redeploy Edge Function with latest code

---

## 📊 Test Results

**Current Status:**
- ✅ Tests executed: 3 (validation tests - no DB required)
- ✅ Passed: 3
- ❌ Failed: 0
- ⏳ Pending: 8 (require USER_ID, THEME_ID)

**Test Coverage:**
- HTTP method validation: ✅
- Idempotency key validation: ✅
- Required fields validation: ✅
- Full flow (Test Case 1): ⏳ Pending deployment fix

---

## 📝 Notes

- **Project URL:** `https://ojcnjxzctnwbmupggoxq.supabase.co`
- **Function URL:** `https://ojcnjxzctnwbmupggoxq.supabase.co/functions/v1/generate-video`
- **Active Model:** Sora 2 Image-to-Video (fal-ai/sora-2/image-to-video)
- **Pricing:** $0.1 per second (1 credit = $0.1)

---

**Ready to test once Edge Function is redeployed with latest code!**

