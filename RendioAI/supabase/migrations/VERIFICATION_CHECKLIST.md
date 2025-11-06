# ✅ Phase 0 Verification Checklist

**Purpose:** Verify all Phase 0 setup is correct before moving to Phase 1

**Date:** 2025-11-05

---

## 📋 How to Run Verification Scripts

### **Step 1: Open Supabase SQL Editor**
Go to: https://ojcnjxzctnwbmupggoxq.supabase.co/project/ojcnjxzctnwbmupggoxq/sql/new

### **Step 2: Run Each Script**
Copy the content of each file below and run in SQL Editor:

---

## ✅ **Script 1: Fix Users Constraint** (ALREADY DONE!)

**File:** `20251105000005_fix_users_constraints.sql`

**Status:** ✅ You already ran this!

**What it does:** Adds CHECK constraint to ensure users have email OR device_id

---

## 🔍 **Script 2: Verify Foreign Keys**

**File:** `verify_foreign_keys.sql`

**How to run:**
1. Open the file: `supabase/migrations/verify_foreign_keys.sql`
2. Copy ALL the SQL
3. Paste into Supabase SQL Editor
4. Click "Run" (or Cmd/Ctrl + Enter)

**Expected Output:**
```
✅ CORRECT: model_id has ON DELETE RESTRICT
✅ CORRECT: user_id has ON DELETE CASCADE
```

**What to check:**
- [ ] `model_id` → models(id) has `ON DELETE RESTRICT` ✅
- [ ] `user_id` → users(id) has `ON DELETE CASCADE` ✅

**If you see ❌:**
- Let me know the exact output
- I'll create a fix migration

---

## 🔍 **Script 3: Verify Storage Policies**

**File:** `verify_storage_policies.sql`

**How to run:**
1. Open the file: `supabase/migrations/verify_storage_policies.sql`
2. Copy ALL the SQL
3. Paste into Supabase SQL Editor
4. Click "Run" (or Cmd/Ctrl + Enter)

**Expected Output:**

**Summary:**
```
Total Policies: 8
Videos Bucket Policies: 4
Thumbnails Bucket Policies: 4
Status: ✅ ALL POLICIES CORRECT (8 total: 4 per bucket)
```

**Per-Operation Check:**
```
Bucket      | SELECT | INSERT | UPDATE | DELETE
------------|--------|--------|--------|--------
videos      |   ✅   |   ✅   |   ✅   |   ✅
thumbnails  |   ✅   |   ✅   |   ✅   |   ✅
```

**What to check:**
- [ ] Total 8 policies exist ✅
- [ ] Videos bucket has 4 policies (SELECT, INSERT, UPDATE, DELETE) ✅
- [ ] Thumbnails bucket has 4 policies (SELECT, INSERT, UPDATE, DELETE) ✅
- [ ] Both buckets are public ✅
- [ ] Videos bucket: 500MB limit ✅
- [ ] Thumbnails bucket: 10MB limit ✅

**If you see ❌ or missing policies:**
- Let me know which policies are missing
- I'll create a fix script

---

## 📊 **Quick Verification Summary**

### **What We're Checking:**

| Item | Check | Expected Result |
|------|-------|-----------------|
| **Users Constraint** | email OR device_id required | ✅ Constraint exists |
| **video_jobs → models FK** | ON DELETE RESTRICT | ✅ Protects models from deletion |
| **video_jobs → users FK** | ON DELETE CASCADE | ✅ Deletes jobs when user deleted |
| **Storage Policies** | 8 policies (4 per bucket) | ✅ All CRUD operations covered |
| **Bucket Configuration** | Correct size limits & MIME types | ✅ videos: 500MB, thumbnails: 10MB |

---

## 🎯 **After Running All Scripts**

**Tell me one of these:**

✅ **"All green! Everything looks good!"**
- All checks show ✅
- No ❌ symbols
- Ready to proceed to Phase 1!

⚠️ **"I see some ❌ symbols"**
- Copy the output
- Paste it here
- I'll create fix migrations immediately

❓ **"I got an error running a script"**
- Copy the error message
- Paste it here
- I'll help troubleshoot

---

## 📁 **Files Created for Verification**

```
RendioAI/supabase/migrations/
├── 20251105000005_fix_users_constraints.sql    ✅ Already run
├── verify_foreign_keys.sql                      🔍 Run this
├── verify_storage_policies.sql                  🔍 Run this
└── VERIFICATION_CHECKLIST.md                    📋 This file
```

---

## 💡 **Tips**

1. **These verification scripts are safe** - they only SELECT data, they don't modify anything
2. **Run them in any order** - they're independent
3. **You can run them multiple times** - no harm in re-checking
4. **Copy the full output** - if something is wrong, I need to see all the details

---

## 🚀 **Once Everything is ✅**

We'll be ready to start **Phase 1: Core APIs!**

Next steps will be:
1. Create first Edge Function: `device-check`
2. Create `get-user-credits` function
3. Create `get-models` function
4. Test with iOS app!

---

**Status:** ⏳ Waiting for verification results

**Next:** Run the 2 verification scripts and report back! 😊
