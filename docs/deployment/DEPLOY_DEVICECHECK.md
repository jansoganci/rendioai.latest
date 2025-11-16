# DeviceCheck Deployment Guide

## ✅ Files Created

All code files have been created:

1. ✅ `supabase/migrations/20250116000000_device_check_hardening.sql` - Database schema
2. ✅ `supabase/functions/device-check/apple_devicecheck.ts` - Apple API helper
3. ✅ `supabase/functions/device-check/index.ts` - Main Edge Function (updated)
4. ✅ `supabase/functions/device-check/README.md` - Documentation

## 🔐 Step 1: Set Supabase Secrets

You have 3 secrets from Apple. Set them now:

### Option A: Via Supabase CLI (Recommended)

```bash
cd /Users/jans./Downloads/RendioAI/RendioAI

# Set Team ID
supabase secrets set APPLE_TEAM_ID=YOUR_TEAM_ID_HERE

# Set Key ID
supabase secrets set APPLE_KEY_ID=YOUR_KEY_ID_HERE

# Set Private Key (from .p8 file)
supabase secrets set APPLE_DEVICECHECK_KEY_P8="$(cat /path/to/your/AuthKey_XXXXX.p8)"

# Set Environment (production)
supabase secrets set APP_ENV=production
```

### Option B: Via Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **Project Settings** (gear icon, bottom left)
4. Click **Edge Functions**
5. Scroll to **Secrets** section
6. Click **Add Secret** for each:
   - Name: `APPLE_TEAM_ID`, Value: `YOUR_TEAM_ID`
   - Name: `APPLE_KEY_ID`, Value: `YOUR_KEY_ID`
   - Name: `APPLE_DEVICECHECK_KEY_P8`, Value: `Paste entire .p8 file contents`
   - Name: `APP_ENV`, Value: `production`

### Verify Secrets Are Set

```bash
supabase secrets list
```

Should show all 4 secrets (values will be hidden).

---

## 🗄️ Step 2: Deploy Database Migration

```bash
cd /Users/jans./Downloads/RendioAI/RendioAI

supabase db push
```

**Expected output:**
```
Applying migration 20250116000000_device_check_hardening.sql...
Migration applied successfully
```

This creates:
- `device_check_devices` table
- `upsert_device_check_state()` function
- `check_device_rate_limit()` function
- RLS policies

---

## 🚀 Step 3: Deploy Edge Function

```bash
supabase functions deploy device-check
```

**Expected output:**
```
Deploying function device-check...
Function deployed successfully
URL: https://your-project.supabase.co/functions/v1/device-check
```

---

## ✅ Step 4: Verify Deployment

### 4.1 Check Function Logs

```bash
supabase functions logs device-check --tail
```

Leave this running in a terminal.

### 4.2 Test from iOS App

1. **Delete app** from simulator/device (fresh install)
2. **Run app** from Xcode
3. **Watch logs** in terminal (from step 4.1)

**Expected logs:**
```
DeviceCheck request started
Verifying device with Apple DeviceCheck
📡 Querying Apple DeviceCheck API (env: production)
✅ Apple DeviceCheck query succeeded (bit0: 0, bit1: 0)
Apple DeviceCheck verification succeeded
Device state updated
New user created with initial credits
```

### 4.3 Check Database

In Supabase Dashboard → SQL Editor:

```sql
-- Check device_check_devices table
SELECT * FROM device_check_devices ORDER BY created_at DESC LIMIT 5;

-- Should show your device with:
-- - device_id (StableID)
-- - dc_bit0, dc_bit1 (from Apple)
-- - risk_score (should be 0)
-- - dc_query_success_count (should be 1)
```

---

## 🎯 Success Criteria

✅ **Secrets set** - `supabase secrets list` shows 4 secrets
✅ **Migration applied** - `device_check_devices` table exists
✅ **Function deployed** - No errors in deployment
✅ **Apple verification works** - Logs show "Apple DeviceCheck query succeeded"
✅ **Database updated** - Device appears in `device_check_devices` table
✅ **User created** - App works normally, user gets 10 credits

---

## 🐛 Troubleshooting

### Error: "Missing Apple DeviceCheck credentials"

**Fix**: Secrets not set. Go back to Step 1.

```bash
supabase secrets list
```

Should show:
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_DEVICECHECK_KEY_P8`
- `APP_ENV`

### Error: "Apple DeviceCheck API error: 401"

**Cause**: Wrong credentials or key not enabled

**Fix**:
1. Verify `APPLE_TEAM_ID` and `APPLE_KEY_ID` are correct
2. Check `.p8` file contents include `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
3. Verify key has DeviceCheck enabled in Apple Developer portal

### Error: "relation 'device_check_devices' does not exist"

**Cause**: Migration not applied

**Fix**:
```bash
supabase db push
```

### App still works but logs show "Apple DeviceCheck verification failed"

**Behavior**: This is **degraded mode** - app continues but flags device as suspicious

**Check**:
1. Look at actual error in logs
2. Verify secrets are correct
3. Check Apple Developer portal - key might be disabled

**Note**: App will still create user and grant credits, but device is marked with fraud flags.

---

## 📊 Monitoring

### Daily Check

```sql
-- Verification success rate
SELECT
  COUNT(*) FILTER (WHERE dc_query_success_count > 0) * 100.0 / COUNT(*) as success_rate,
  COUNT(*) as total_devices
FROM device_check_devices;

-- High-risk devices (should be rare)
SELECT COUNT(*) as high_risk_count
FROM device_check_devices
WHERE risk_score >= 50;
```

### Weekly Review

```sql
-- Fraud signals breakdown
SELECT
  unnest(fraud_flags) as flag,
  COUNT(*) as count
FROM device_check_devices
WHERE fraud_flags IS NOT NULL
GROUP BY flag
ORDER BY count DESC;
```

---

## 🎉 What's Different Now?

### Before (Placeholder):
```
iOS → Backend: "Here's my token"
Backend: "Token length > 10? OK, come in!" ❌
```

### After (Production):
```
iOS → Backend: "Here's my token"
Backend → Apple: "Is this token valid?"
Apple → Backend: "Yes, bit0=0, bit1=0"
Backend: "OK, risk_score=0, come in!" ✅
```

---

## 🔒 Security Checklist

- ✅ Private key never logged
- ✅ Device tokens not logged
- ✅ Secrets stored securely in Supabase Vault
- ✅ Rate limiting (10 requests/hour per device)
- ✅ Fraud detection (multi-account, fail spike, bit flapping)
- ✅ RLS enforced (users can only see their own devices)
- ✅ Correlation IDs for debugging

---

## 📞 Need Help?

Check:
1. `supabase/functions/device-check/README.md` - Detailed docs
2. `supabase functions logs device-check --tail` - Live logs
3. Supabase Dashboard → Edge Functions → device-check → Logs

---

## 🚀 Ready to Deploy?

Run these commands in order:

```bash
cd /Users/jans./Downloads/RendioAI/RendioAI

# 1. Set secrets (do this first!)
supabase secrets set APPLE_TEAM_ID=YOUR_VALUE
supabase secrets set APPLE_KEY_ID=YOUR_VALUE
supabase secrets set APPLE_DEVICECHECK_KEY_P8="$(cat /path/to/key.p8)"
supabase secrets set APP_ENV=production

# 2. Deploy migration
supabase db push

# 3. Deploy function
supabase functions deploy device-check

# 4. Watch logs
supabase functions logs device-check --tail
```

Then test with your iOS app!
