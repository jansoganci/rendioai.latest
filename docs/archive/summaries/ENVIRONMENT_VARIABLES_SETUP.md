# 🔐 Environment Variables Setup Guide

**Date:** 2025-11-05  
**Purpose:** Guide for adding environment variables to Supabase Edge Functions

---

## 📋 Required Environment Variables

### Phase 1 Variables

| Variable Name | Description | Required For |
|---------------|-------------|--------------|
| `SUPABASE_URL` | Your Supabase project URL | All functions |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (secret) | All functions |
| `ENVIRONMENT` | Environment name (development/staging/production) | All functions |
| `FALAI_API_KEY` | FalAI API key for video generation | Phase 2 (generate-video) |

---

## 🔑 How to Add Environment Variables to Supabase Edge Functions

### Method 1: Via Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - URL: https://supabase.com/dashboard
   - Select your project: `ojcnjxzctnwbmupggoxq`

2. **Navigate to Edge Functions Settings**
   - Click on **"Project Settings"** (gear icon in left sidebar)
   - Click on **"Edge Functions"** in the settings menu
   - Scroll down to **"Secrets"** section

3. **Add Each Secret**
   - Click **"Add new secret"**
   - Enter the **Name** (e.g., `FALAI_API_KEY`)
   - Enter the **Value** (your actual API key)
   - Click **"Save"**

4. **Repeat for All Variables**
   - Add `SUPABASE_URL`
   - Add `SUPABASE_SERVICE_ROLE_KEY`
   - Add `ENVIRONMENT`
   - Add `FALAI_API_KEY` (when you have it)

---

### Method 2: Via Supabase CLI

```bash
# Set a secret
supabase secrets set FALAI_API_KEY=your-actual-api-key-here

# Set multiple secrets at once
supabase secrets set \
  SUPABASE_URL=https://ojcnjxzctnwbmupggoxq.supabase.co \
  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
  ENVIRONMENT=development \
  FALAI_API_KEY=your-falai-api-key

# List all secrets (names only, not values)
supabase secrets list

# Unset a secret
supabase secrets unset FALAI_API_KEY
```

**Note:** Make sure you're logged in and linked to your project:
```bash
supabase login
supabase link --project-ref ojcnjxzctnwbmupggoxq
```

---

## 🎯 Getting Your FalAI API Key

### Step 1: Sign Up / Log In to FalAI

1. Go to: https://fal.ai/
2. Sign up for an account (or log in if you already have one)

### Step 2: Get Your API Key

1. After logging in, go to your **Dashboard**
2. Navigate to **"API Keys"** or **"Settings"** → **"API Keys"**
3. Click **"Create API Key"** or copy your existing key
4. **Important:** Copy the key immediately - you won't be able to see it again!

### Step 3: Add to Supabase

1. Follow **Method 1** or **Method 2** above
2. Add the secret name: `FALAI_API_KEY`
3. Paste your FalAI API key as the value
4. Save

---

## ✅ Verification

### Check if Variables are Set

**Via Dashboard:**
- Go to Project Settings → Edge Functions → Secrets
- You should see all your secrets listed (values are hidden)

**Via CLI:**
```bash
supabase secrets list
```

**Test in Edge Function:**
```typescript
// In any Edge Function
const falaiKey = Deno.env.get('FALAI_API_KEY')
console.log('FALAI_API_KEY exists:', !!falaiKey)
```

---

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Store secrets in Supabase Dashboard Secrets (not in code)
- ✅ Use different keys for development/staging/production
- ✅ Rotate keys regularly
- ✅ Never commit secrets to git
- ✅ Use service role key only in backend (never in client)

### ❌ DON'T:
- ❌ Hardcode API keys in your code
- ❌ Commit `.env` files to git
- ❌ Share API keys in chat/email
- ❌ Use production keys in development
- ❌ Expose service role key to client apps

---

## 📝 Complete Environment Variables List

### Phase 1 (Current)
```bash
SUPABASE_URL=https://ojcnjxzctnwbmupggoxq.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ENVIRONMENT=development
```

### Phase 2 (Video Generation)
```bash
FALAI_API_KEY=your-falai-api-key
```

### Phase 0.5 (Security - Future)
```bash
APPLE_BUNDLE_ID=com.rendioai.app
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_KEY_ID=YOUR_KEY_ID
APPLE_ISSUER_ID=YOUR_ISSUER_ID
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
APPLE_DEVICECHECK_KEY_ID=YOUR_DEVICECHECK_KEY_ID
APPLE_DEVICECHECK_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

---

## 🚀 Quick Setup Checklist

### Phase 1 Setup:
- [ ] Get Supabase Service Role Key
  - [ ] Go to: Project Settings → API → service_role key
  - [ ] Copy the key
  - [ ] Add to Supabase Secrets as `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Set `SUPABASE_URL` secret
- [ ] Set `ENVIRONMENT` secret (use `development` for now)

### Phase 2 Setup (When Ready):
- [ ] Sign up for FalAI account
- [ ] Get FalAI API key
- [ ] Add to Supabase Secrets as `FALAI_API_KEY`

---

## 📚 References

- **Supabase Secrets Docs:** https://supabase.com/docs/guides/functions/secrets
- **FalAI API Docs:** https://fal.ai/docs
- **Backend Building Plan:** `docs/active/backend/implementation/backend-building-plan.md`

---

## ❓ Troubleshooting

### "Environment variable not found" error

**Problem:** Edge Function can't access environment variable

**Solution:**
1. Check variable name is exact (case-sensitive): `FALAI_API_KEY`
2. Verify secret is saved in Supabase Dashboard
3. Redeploy the Edge Function after adding secrets
4. Check logs for any errors

### "Invalid API key" error from FalAI

**Problem:** FalAI API key is incorrect or expired

**Solution:**
1. Verify key is correct (no extra spaces)
2. Check FalAI dashboard to ensure key is active
3. Generate a new key if needed
4. Update the secret in Supabase

---

**Status:** ✅ Ready for Phase 1 deployment  
**Next:** Add `FALAI_API_KEY` when you reach Phase 2 (video generation)

