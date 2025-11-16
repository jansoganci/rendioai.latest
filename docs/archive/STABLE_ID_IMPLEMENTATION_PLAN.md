# 📋 StableID Implementation Plan

**Date:** 2025-01-27  
**Purpose:** Replace `identifierForVendor` with StableID for persistent device identification

---

## 🎯 Problem Statement

**Current Issue:**
- App uses `identifierForVendor` which changes when:
  - App is deleted and reinstalled
  - Simulator is reset
  - All apps from vendor are deleted
- This causes users to lose their account/data when reinstalling

**Evidence from Logs:**
```
⚠️ identifierForVendor changed!
   - Stored deviceId: 907c2698-8289-4ac8-be9b-5a2a092a0044
   - Current identifierForVendor: 94ECE36E-ED90-46FC-A29A-AD02FE0BDB95
```

**Solution:**
- Use StableID package (https://github.com/codykerns/StableID)
- Provides persistent identifier that survives app reinstalls
- Stored in Keychain (survives app deletion)

---

## 📊 Implementation Scope

### Phase 1: Add StableID Package (30 min)
- [ ] Add StableID Swift Package dependency
- [ ] Verify package resolves correctly
- [ ] Test basic functionality

### Phase 2: Create StableID Service (1 hour)
- [ ] Create `StableIDService.swift`
- [ ] Wrap StableID package
- [ ] Provide migration from `identifierForVendor`
- [ ] Handle edge cases (first launch, Keychain access)

### Phase 3: Update Device Identification (2 hours)
- [ ] Update `OnboardingService` to use StableID
- [ ] Update `OnboardingViewModel` device check logic
- [ ] Remove `identifierForVendor` checks
- [ ] Update all places that use device_id

### Phase 4: Migration Logic (1 hour)
- [ ] Handle existing users with old `identifierForVendor`
- [ ] Map old device_id to new stable_id
- [ ] Update backend if needed (check if device_id lookup works)

### Phase 5: Testing (1 hour)
- [ ] Test fresh install
- [ ] Test app reinstall (simulator reset)
- [ ] Test migration from old to new ID
- [ ] Verify backend recognizes user

### Phase 6: Backend Verification (30 min)
- [ ] Verify backend can handle stable_id format
- [ ] Check if device_id column accepts new format
- [ ] Test device-check endpoint with stable_id

---

## ⏱️ Time Estimate

**Total: 5-6 hours**

Breakdown:
- Package integration: 30 min
- Service creation: 1 hour
- Code updates: 2 hours
- Migration logic: 1 hour
- Testing: 1 hour
- Backend verification: 30 min

**Complexity:** Medium
- Straightforward implementation
- Well-documented package
- Minimal backend changes needed

---

## 🔧 Technical Details

### Current Flow:
```swift
// OnboardingService.swift line 51
let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
```

### New Flow:
```swift
// StableIDService.swift
let deviceId = StableIDService.shared.getStableID()
```

### Migration Strategy:
1. Check if stable_id exists in Keychain
2. If not, generate new one and store
3. For existing users: try to map old device_id to stable_id
4. Backend lookup by device_id should still work (no backend changes needed)

---

## 📝 Files to Modify

1. **Add Package:**
   - Xcode project → Package Dependencies
   - Add: `https://github.com/codykerns/StableID`

2. **New Files:**
   - `RendioAI/RendioAI/Core/Services/StableIDService.swift`

3. **Update Files:**
   - `RendioAI/RendioAI/Core/Services/OnboardingService.swift` (line 51)
   - `RendioAI/RendioAI/Core/ViewModels/OnboardingViewModel.swift` (line 62-77)
   - Any other files using `identifierForVendor`

---

## ✅ Benefits

1. **User Retention:** Users keep their account after reinstall
2. **Better UX:** No need to re-onboard after app reinstall
3. **Data Persistence:** Credits, history, etc. persist
4. **Privacy:** Still device-based (no personal info)

---

## ⚠️ Considerations

1. **Backend Compatibility:**
   - Backend uses `device_id` column
   - Should work with any UUID format
   - No backend changes needed (verify)

2. **Migration:**
   - Existing users will get new stable_id
   - May create duplicate accounts if not handled
   - Need migration strategy

3. **Testing:**
   - Test on real device (simulator resets are expected)
   - Test app reinstall scenario
   - Test Keychain access permissions

---

## 🚀 Should We Proceed?

**Recommendation:** ✅ **YES**

**Reasons:**
- High impact (user retention)
- Low risk (well-tested package)
- Reasonable effort (5-6 hours)
- No backend changes needed (likely)

**Priority:** Medium-High
- Not blocking current features
- Important for production readiness
- Better user experience

---

**Ready to start?** Let me know and I'll begin with Phase 1!

