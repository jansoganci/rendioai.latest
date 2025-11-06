# 🧭 Onboarding Flow - Implementation Analysis

**Date:** 2025-11-05
**Project:** RendioAI
**Blueprint:** onboarding-flow.md
**Status:** Ready for Implementation

---

## 📋 Executive Summary

The onboarding flow is a **silent, automatic system** that:
- Requires **zero user interaction**
- Identifies devices using **DeviceCheck**
- Assigns **10 free credits** to new users
- Shows a **welcome banner** once
- Handles **network errors gracefully** with retries
- Works seamlessly for both **new and returning users**

**Key Feature:** Everything happens in the background during a 2-second splash screen.

---

## 🎯 Core Requirements

### 1. Splash Screen (2 seconds)
- Static logo display
- Background tasks:
  - DeviceCheck token generation
  - API call to `/api/device/check`
  - User data retrieval/creation

### 2. DeviceCheck Integration
- Generate unique device token
- Send to backend for device identification
- No Keychain needed (Apple compliant)
- Prevents credit fraud via device fingerprinting

### 3. Silent Retry Logic
- Max 3 attempts for network failures
- No error messages shown to user
- Splash extends 2-3 seconds if needed
- Graceful degradation

### 4. Initial Credit Assignment
- New users: 10 credits automatically
- `initial_grant_claimed = true` flag set
- Persisted in Supabase to prevent re-grants
- Even if app is deleted and reinstalled

### 5. Welcome Banner
- Shows once on Home screen
- Only for new users
- Dismissible
- Never shows again (UserDefaults flag)

### 6. Low Credit Warning
- Shows when `credits_remaining < 10`
- Persistent until credits purchased
- Links to credit purchase flow

---

## 🏗️ Architecture Design

### Component Hierarchy

```
App Launch
  ↓
SplashView (2s)
  ├─ Logo Animation
  └─ OnboardingManager.performOnboarding()
       ├─ DeviceCheckService.generateToken()
       ├─ OnboardingService.checkDevice(token)
       └─ UserDefaultsManager.updateOnboardingState()
  ↓
ContentView (with NavigationStack)
  ↓
HomeView
  ├─ WelcomeBanner (if new user)
  └─ LowCreditBanner (if credits < 10)
```

---

## 🗂️ Files to Create/Modify

### New Files (8 files)

#### Phase 1: Core Services
1. **`Core/Services/DeviceCheckService.swift`**
   - DeviceCheck token generation
   - Error handling
   - Mock implementation

2. **`Core/Services/OnboardingService.swift`**
   - API call to `/api/device/check`
   - Response handling
   - Retry logic
   - Mock implementation

3. **`Core/Models/OnboardingResponse.swift`**
   - API response model
   - Device check result

#### Phase 2: UI Components
4. **`Features/Splash/SplashView.swift`**
   - 2-second splash screen
   - Logo animation
   - Background onboarding task

5. **`Features/Home/Components/WelcomeBanner.swift`**
   - "You've received 10 free credits!"
   - Dismissible
   - Only shows once

6. **`Features/Home/Components/LowCreditBanner.swift`**
   - Warning message
   - "Buy Credits" CTA
   - Conditional visibility

#### Phase 3: State Management
7. **`Core/ViewModels/OnboardingViewModel.swift`**
   - Orchestrates onboarding flow
   - Manages state
   - Handles retries

8. **`Core/Services/OnboardingStateManager.swift`**
   - UserDefaults persistence
   - Banner state tracking
   - Onboarding completion flag

### Files to Modify (4 files)

1. **`RendioAIApp.swift`**
   - Add splash screen as initial view
   - Conditional navigation to ContentView

2. **`Core/Services/UserDefaultsManager.swift`**
   - Add onboarding state properties
   - Add banner tracking

3. **`Features/Home/HomeView.swift`**
   - Add WelcomeBanner
   - Add LowCreditBanner
   - Conditional rendering

4. **`Core/Models/User.swift`**
   - May need to add `initialGrantClaimed` if not present

---

## 📊 Data Flow

### New User Flow
```
1. App Launch
   ↓
2. SplashView appears
   ↓
3. DeviceCheck generates token → "ABC123"
   ↓
4. API Call: POST /api/device/check
   Body: { device_token: "ABC123" }
   ↓
5. Backend Response:
   {
     device_id: "uuid-123",
     is_existing_user: false,
     credits_remaining: 10,
     initial_grant_claimed: true,
     show_welcome_banner: true
   }
   ↓
6. Save to UserDefaults:
   - device_id
   - credits_remaining
   - hasSeenWelcomeBanner = false
   ↓
7. Navigate to HomeView
   ↓
8. WelcomeBanner appears: "🎉 You've received 10 free credits!"
   ↓
9. User dismisses banner
   ↓
10. UserDefaults.hasSeenWelcomeBanner = true
```

### Returning User Flow
```
1. App Launch
   ↓
2. SplashView appears
   ↓
3. DeviceCheck generates token → "ABC123" (same device)
   ↓
4. API Call: POST /api/device/check
   Body: { device_token: "ABC123" }
   ↓
5. Backend Response:
   {
     device_id: "uuid-123",
     is_existing_user: true,
     credits_remaining: 5,
     initial_grant_claimed: true,
     show_welcome_banner: false
   }
   ↓
6. Save to UserDefaults:
   - device_id
   - credits_remaining
   ↓
7. Navigate to HomeView
   ↓
8. NO WelcomeBanner (already seen)
   ↓
9. LowCreditBanner appears (credits < 10)
```

---

## 🔄 Retry Logic Implementation

```swift
func performDeviceCheckWithRetry(maxAttempts: Int = 3) async throws -> OnboardingResponse {
    var attempts = 0
    var lastError: Error?

    while attempts < maxAttempts {
        do {
            let token = try await DeviceCheckService.generateToken()
            let response = try await OnboardingService.checkDevice(token: token)
            return response // Success!
        } catch {
            lastError = error
            attempts += 1

            if attempts < maxAttempts {
                // Wait 2 seconds before retry
                try await Task.sleep(for: .seconds(2))
            }
        }
    }

    // All retries failed - use fallback
    throw lastError ?? OnboardingError.maxRetriesExceeded
}
```

---

## 🎨 UI Components Design

### WelcomeBanner
```
┌──────────────────────────────────────┐
│ 🎉                                   │
│ You've received 10 free credits!    │
│                                  [X] │
└──────────────────────────────────────┘
```
- Background: Gradient or Brand color
- Position: Top of Home screen
- Animation: Slide down from top
- Dismissible: Tap X or tap banner

### LowCreditBanner
```
┌──────────────────────────────────────┐
│ ⚠️ Your credits are running low.     │
│ [Buy Credits]                        │
└──────────────────────────────────────┘
```
- Background: Warning color (yellow/orange)
- Position: Above content on Home screen
- Persistent until credits purchased
- Action: Opens PurchaseSheet

---

## 🔐 Security & Privacy

### DeviceCheck Benefits
- ✅ Apple-approved device identification
- ✅ No personal data collected
- ✅ Fraud prevention (can't get free credits twice)
- ✅ Works across app reinstalls
- ✅ Privacy-preserving (anonymous token)

### Best Practices
- Never store DeviceCheck token locally
- Generate new token on each launch
- Backend validates token with Apple
- No tracking beyond credit assignment

---

## 📱 Backend API Requirements

### Endpoint: POST /api/device/check

**Request:**
```json
{
  "device_token": "base64-encoded-token"
}
```

**Response (New User):**
```json
{
  "device_id": "uuid-v4",
  "is_existing_user": false,
  "credits_remaining": 10,
  "initial_grant_claimed": true,
  "show_welcome_banner": true,
  "user": {
    "id": "user-uuid",
    "email": null,
    "is_guest": true,
    "tier": "free",
    "created_at": "2025-11-05T12:00:00Z"
  }
}
```

**Response (Existing User):**
```json
{
  "device_id": "uuid-v4",
  "is_existing_user": true,
  "credits_remaining": 5,
  "initial_grant_claimed": true,
  "show_welcome_banner": false,
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "is_guest": false,
    "tier": "free",
    "created_at": "2025-11-04T10:00:00Z"
  }
}
```

**Backend Logic:**
1. Validate DeviceCheck token with Apple
2. Check if device_id exists in `devices` table
3. If new → Create user, assign 10 credits, set flag
4. If existing → Return current user data
5. Return appropriate response

---

## 🧪 Testing Strategy

### Unit Tests
- DeviceCheckService token generation
- OnboardingService API calls
- Retry logic (mock failures)
- UserDefaults state management

### Integration Tests
- Full onboarding flow (new user)
- Full onboarding flow (returning user)
- Network failure scenarios
- Banner display logic

### Manual Testing Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| First launch | Splash → Welcome banner → 10 credits |
| Second launch | Splash → No banner → Same credits |
| Delete app, reinstall | Splash → No banner → No new credits |
| Network offline | Splash extends, retries, eventual fallback |
| Credits < 10 | Low credit banner shows |
| Purchase credits | Low credit banner disappears |

---

## ⏱️ Implementation Phases

### Phase 1: Core Services (2-3 hours)
**Files:** 3
**Complexity:** Medium

- DeviceCheckService
- OnboardingService
- OnboardingResponse model
- Mock implementations

**Deliverables:**
- ✅ Device token generation working
- ✅ API integration skeleton ready
- ✅ Mock responses for testing

---

### Phase 2: Splash Screen (1-2 hours)
**Files:** 1
**Complexity:** Low

- SplashView with logo
- 2-second timer
- Background task execution
- Navigation to ContentView

**Deliverables:**
- ✅ Splash screen displays
- ✅ Onboarding runs in background
- ✅ Smooth transition to Home

---

### Phase 3: Onboarding Orchestration (2-3 hours)
**Files:** 2
**Complexity:** High

- OnboardingViewModel
- OnboardingStateManager
- Retry logic
- Error handling
- State persistence

**Deliverables:**
- ✅ Full onboarding flow works
- ✅ Retry mechanism functional
- ✅ State persisted correctly

---

### Phase 4: Banner Components (1-2 hours)
**Files:** 2
**Complexity:** Low

- WelcomeBanner
- LowCreditBanner
- Animations
- Dismiss logic

**Deliverables:**
- ✅ Welcome banner appears once
- ✅ Low credit warning works
- ✅ Smooth animations

---

### Phase 5: Integration (2-3 hours)
**Files:** 4 modified
**Complexity:** Medium

- Update RendioAIApp.swift
- Update UserDefaultsManager
- Update HomeView
- Connect all pieces

**Deliverables:**
- ✅ Full flow end-to-end
- ✅ All edge cases handled
- ✅ Smooth user experience

---

### Phase 6: Testing & Polish (1-2 hours)
**Files:** 0 (testing only)
**Complexity:** Low

- Manual testing
- Edge case verification
- Performance optimization
- Final polish

**Deliverables:**
- ✅ All scenarios tested
- ✅ No blocking bugs
- ✅ Production ready

---

## 📈 Total Effort Estimate

| Phase | Files | Hours | Priority |
|-------|-------|-------|----------|
| 1. Core Services | 3 new | 2-3 | High |
| 2. Splash Screen | 1 new | 1-2 | High |
| 3. Orchestration | 2 new | 2-3 | High |
| 4. Banner Components | 2 new | 1-2 | Medium |
| 5. Integration | 4 modified | 2-3 | High |
| 6. Testing & Polish | 0 | 1-2 | Medium |
| **TOTAL** | **8 new, 4 modified** | **9-15 hours** | - |

**Estimated Development Time:** 1-2 days
**Complexity Rating:** 7/10 (High - DeviceCheck integration)

---

## ⚠️ Risks & Mitigations

### Risk 1: DeviceCheck API Failures
**Probability:** Medium
**Impact:** High
**Mitigation:**
- Implement retry logic (3 attempts)
- Extend splash screen duration
- Fallback to UUID if DeviceCheck unavailable
- Log errors for debugging

### Risk 2: Backend Not Ready
**Probability:** High
**Impact:** High
**Mitigation:**
- Use mock service for development
- Implement full API contract
- Add TODO comments for backend team
- Test with mock data extensively

### Risk 3: User Experience Issues
**Probability:** Low
**Impact:** Medium
**Mitigation:**
- Keep splash short (2s max normally)
- No blocking error messages
- Graceful degradation
- Smooth animations

---

## ✅ Success Criteria

### Must Have
- [x] Splash screen displays for 2 seconds
- [x] DeviceCheck token generated successfully
- [x] New users receive 10 credits
- [x] Welcome banner shows once only
- [x] Returning users see correct credit balance
- [x] No user interaction required

### Should Have
- [x] Retry logic handles network failures
- [x] Low credit banner when < 10 credits
- [x] Smooth animations
- [x] Banner dismissal works
- [x] State persists across launches

### Nice to Have
- [ ] Analytics tracking (opt-in)
- [ ] Dynamic credit amount from backend
- [ ] iCloud sync for cross-device
- [ ] Custom splash animations

---

## 🚀 Ready to Implement

**Recommendation:** Start with Phase 1 (Core Services) to establish the foundation, then proceed sequentially through each phase.

**Critical Path:**
1. DeviceCheckService → OnboardingService
2. SplashView → OnboardingViewModel
3. Banner components → HomeView integration

**Blockers:**
- None! All development can happen with mocks
- Backend can be developed in parallel

---

**Status:** ✅ Analysis Complete - Ready for Implementation
**Next Action:** Begin Phase 1 - Core Services

