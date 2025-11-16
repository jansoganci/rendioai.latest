# 🔧 Xcode Configuration Setup Guide

**Purpose:** Link `.xcconfig` files to Xcode project and configure build settings  
**Estimated Time:** 5-10 minutes  
**Difficulty:** Easy (step-by-step instructions)

---

## ✅ What's Already Done

- ✅ Created `.xcconfig` files (Development, Staging, Production)
- ✅ Created `AppConfig.swift` with fallback values
- ✅ Updated all 9 service files to use `AppConfig`

---

## 📋 Step-by-Step Xcode Setup

### Step 1: Add `.xcconfig` Files to Xcode Project

1. **Open Xcode** and open your `RendioAI.xcodeproj` project

2. **Right-click** on the project root in the Project Navigator (left sidebar)
   - Or click the project name at the top of the file list

3. **Select "Add Files to 'RendioAI'..."**
   - Or press `⌘ + Option + A`

4. **Navigate to** `RendioAI/Configuration/` folder

5. **Select all 3 `.xcconfig` files:**
   - `Development.xcconfig`
   - `Staging.xcconfig`
   - `Production.xcconfig`

6. **Important Options:**
   - ✅ Check "Copy items if needed" (if files aren't already in project folder)
   - ✅ Check "Create groups" (not "Create folder references")
   - ✅ Make sure "Add to targets: RendioAI" is checked

7. **Click "Add"**

---
BURDA KALDIM BURADA !!!!!!!!!!!!!!!!!!!!!
### Step 2: Link `.xcconfig` Files to Build Configurations

1. **Select the project** in Project Navigator (blue icon at top)

2. **Select the "RendioAI" target** (under TARGETS, not PROJECT)

3. **Click "Build Settings" tab** at the top

4. **In the search bar**, type: `base configuration`

5. **Find "Base Configuration File"** setting

6. **For Debug configuration:**
   - Click the dropdown next to "Base Configuration File" under Debug
   - Select `Development.xcconfig`

7. **For Release configuration:**
   - Click the dropdown next to "Base Configuration File" under Release
   - Select `Production.xcconfig`

**Note:** If you want Staging, you'll need to create a Staging build configuration first (see Step 3).

---

### Step 3: Add Info.plist Keys (If Needed)

Since your project uses `GENERATE_INFOPLIST_FILE = YES`, the Info.plist is auto-generated. The `.xcconfig` values will be injected automatically via build settings.

**However, to make them accessible via `Bundle.main.object(forInfoDictionaryKey:)`, add these build settings:**

1. **Select the project** → **Select "RendioAI" target** → **Build Settings**

2. **Search for:** `info.plist`

3. **Find "Info.plist Values"** or **"INFOPLIST_KEY_*"** settings

4. **Add these User-Defined Settings** (click "+" button):
   - `INFOPLIST_KEY_SUPABASE_URL` = `$(SUPABASE_URL)`
   - `INFOPLIST_KEY_SUPABASE_ANON_KEY` = `$(SUPABASE_ANON_KEY)`
   - `INFOPLIST_KEY_ENVIRONMENT_NAME` = `$(ENVIRONMENT_NAME)`

**Alternative (Simpler):** The `.xcconfig` files already define these. Just make sure they're being read correctly.

---

### Step 4: Verify Configuration

1. **Build the project** (`⌘ + B`)

2. **Check if it compiles** - If you see errors about `AppConfig`, make sure:
   - `AppConfig.swift` is added to the target
   - All service files can import/access `AppConfig`

3. **Add a test print** in `RendioAIApp.swift` to verify:
   ```swift
   init() {
       print("🌍 Environment: \(AppConfig.environmentName)")
       print("🔗 Supabase URL: \(AppConfig.supabaseURL)")
   }
   ```

4. **Run the app** and check console output

---

### Step 5: (Optional) Create Staging Build Configuration

If you want a separate Staging environment:

1. **Select the project** → **Info** tab

2. **Under "Configurations"**, click "+" → **Duplicate "Debug" Configuration**

3. **Rename** the new configuration to "Staging"

4. **Go back to Build Settings** → **Base Configuration File**

5. **For Staging configuration**, select `Staging.xcconfig`

6. **Create a new Scheme:**
   - Product → Scheme → Manage Schemes...
   - Click "+" to add new scheme
   - Name it "RendioAI Staging"
   - Set Build Configuration to "Staging"

---

## 🧪 Testing

### Test Development Configuration:

1. **Select "RendioAI" scheme** (should use Debug → Development.xcconfig)
2. **Run the app** (`⌘ + R`)
3. **Check console** for environment name: Should print "development"

### Test Production Configuration:

1. **Change scheme** to use Release build configuration
2. **Or** create a Release scheme
3. **Run the app**
4. **Check console** for environment name: Should print "production"

---

## 🔍 Troubleshooting

### Problem: "Cannot find 'AppConfig' in scope"

**Solution:**
- Make sure `AppConfig.swift` is added to the RendioAI target
- Check File Inspector (right sidebar) → Target Membership → ✅ RendioAI

### Problem: Values are still hardcoded (fallback values used)

**Solution:**
- Verify `.xcconfig` files are linked correctly (Step 2)
- Check Build Settings → Base Configuration File is set
- Clean build folder (`⌘ + Shift + K`) and rebuild

### Problem: Info.plist keys not accessible

**Solution:**
- Add User-Defined Build Settings (Step 3)
- Or use `Bundle.main.object(forInfoDictionaryKey:)` with the exact key name from `.xcconfig`

### Problem: Build fails after adding `.xcconfig`

**Solution:**
- Check `.xcconfig` file syntax (no typos, proper format)
- Make sure all variables are defined
- Check Xcode console for specific error messages

---

## ✅ Verification Checklist

- [ ] All 3 `.xcconfig` files added to Xcode project
- [ ] Debug configuration linked to `Development.xcconfig`
- [ ] Release configuration linked to `Production.xcconfig`
- [ ] Project builds successfully (`⌘ + B`)
- [ ] App runs and prints correct environment name
- [ ] All services use `AppConfig` (no hardcoded values)

---

## 📝 Next Steps After Setup

1. **Update Production.xcconfig** with your actual production Supabase URL/key
2. **Add Production.xcconfig to .gitignore** (if you don't want to commit production keys)
3. **Set up CI/CD** to inject production keys via environment variables
4. **Test switching between environments**

---

## 🎯 Success Criteria

✅ App builds without errors  
✅ Console shows correct environment name  
✅ All API calls use values from `AppConfig`  
✅ No hardcoded URLs/keys in service files  

---

**Need Help?** Check Xcode's build log for specific errors, or verify each step was completed correctly.

