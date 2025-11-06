# 📋 Profile Screen Implementation Analysis

**Date:** 2025-11-05
**Blueprint:** `design/blueprints/profile-screen.md`
**Status:** 🔍 **ANALYSIS COMPLETE - READY FOR PLANNING**

---

## 📊 Executive Summary

The Profile Screen is a **complex, high-priority feature** that serves as the central hub for user identity, credit management, authentication, and app settings. This analysis evaluates all requirements against existing infrastructure and identifies gaps.

**Complexity Level:** ⚠️ **HIGH** (9/10)

**Why High Complexity:**
- ✅ Already have: Placeholder ProfileView, some localization, design tokens
- ❌ Missing: ProfileViewModel, all services (Auth, StoreKit, UserSettings), 6 components, 20+ localizations, API integration

**Key Challenges:**
1. Apple Sign-In integration (AuthenticationServices framework)
2. StoreKit 2 for in-app purchases
3. Guest-to-registered account merge logic
4. Language/Theme persistence with Supabase sync
5. Account deletion flow (GDPR compliance)

---

## 🎯 Blueprint Requirements Analysis

### **1. Component Architecture** (Blueprint line 60-72)

| Component | Type | Status | Complexity | Notes |
|-----------|------|--------|------------|-------|
| **ProfileView** | View | ⚠️ Placeholder | Medium | Exists but needs complete rebuild |
| **ProfileHeader** | Component | ❌ Missing | Medium | Avatar + name + email + tier badge |
| **CreditInfoSection** | Component | ❌ Missing | Medium | Credit display + Buy/History buttons |
| **AccountSection** | Component | ❌ Missing | High | Sign in/out, restore, delete account |
| **SettingsSection** | Component | ❌ Missing | Medium | Language + Theme dropdowns |
| **SettingsDropdown** | Component | ❌ Missing | Medium | Reusable picker with animation |
| **ProfileViewModel** | ViewModel | ❌ Missing | High | Core business logic |
| **StoreKitManager** | Service | ❌ Missing | High | IAP handling |
| **AuthService** | Service | ❌ Missing | High | Apple Sign-In integration |
| **UserSettingsService** | Service | ❌ Missing | Medium | Language/Theme persistence |

**Component Count:** 10 total (1 exists as placeholder, 9 need to be created)

---

### **2. State Management Requirements** (Blueprint line 76-88)

```swift
// Required @Published properties in ProfileViewModel
@Published var isGuest: Bool = true
@Published var userName: String = "Guest"
@Published var email: String? = nil
@Published var tier: String = "free"  // "free" | "premium"
@Published var creditsRemaining: Int = 0
@Published var creditsTotal: Int = 10
@Published var isLoading: Bool = false
@Published var selectedLanguage: String = "English"
@Published var selectedTheme: String = "System"
@Published var showingSignInSheet: Bool = false
@Published var showingPurchaseSheet: Bool = false
@Published var showingDeleteAccountAlert: Bool = false
@Published var errorMessage: String?
@Published var showingErrorAlert: Bool = false
```

**State Complexity:** 14 published properties, multiple async operations

---

### **3. User Flow Requirements** (Blueprint line 17-28)

**Critical Flows:**

#### **Flow 1: Guest User → Sign In**
```
ProfileView
  ↓ Tap "Sign in with Apple"
AuthenticationServices.ASAuthorizationController
  ↓ User approves
Obtain apple_sub + (optional) name/email
  ↓ Call Backend
POST /merge-guest-to-user { device_id, apple_sub }
  ↓ Backend merges data
Update UI with user info
  ↓ Refresh
Fetch updated credits/tier
```

**Complexity:** High - Requires AuthenticationServices, Keychain access, backend integration

---

#### **Flow 2: Buy Credits (IAP)**
```
ProfileView
  ↓ Tap "Buy Credits"
Check: Is user signed in?
  ├─ Yes → Show StoreKit purchase sheet
  └─ No → Prompt sign-in first
  ↓ User completes purchase
StoreKit validates transaction
  ↓ Send receipt to backend
POST /validate-receipt { receipt_data }
  ↓ Backend validates with Apple
Credits added to quota_log
  ↓ Refresh
Update creditsRemaining in UI
```

**Complexity:** Very High - Requires StoreKit 2, receipt validation, backend integration

---

#### **Flow 3: Language/Theme Selection**
```
ProfileView → SettingsSection
  ↓ Tap Language dropdown
Show picker: [English, Türkçe, Español]
  ↓ User selects
Update local state
  ↓ Persist
If logged in: POST to Supabase users.language
If guest: Save to UserDefaults
  ↓ Apply
Update app-wide locale
Reload UI with new language
```

**Complexity:** Medium - Requires locale management, persistence logic

---

#### **Flow 4: Account Deletion**
```
ProfileView → AccountSection
  ↓ Tap "Delete Account"
Show confirmation alert (double-check)
  ↓ User confirms
Call DELETE /user { user_id }
  ↓ Backend deletes
- Remove from users table
- Cascade delete video_jobs, quota_log
- Mark videos for deletion
  ↓ Local cleanup
Clear Keychain device_id
Reset app to initial state
  ↓ Navigate
Return to HomeView as new guest
```

**Complexity:** High - GDPR compliance, data cleanup, error handling

---

### **4. API Integration Requirements** (Blueprint line 153-162)

| Endpoint | Method | Purpose | Status | Implementation Needed |
|----------|--------|---------|--------|----------------------|
| `/api/profile` | GET | Fetch user details + credits | ❓ Unknown | Check if exists, create if not |
| `/api/merge-guest-to-user` | POST | Merge guest → registered | ❌ Not exist | Create Supabase Edge Function |
| `/api/validate-receipt` | POST | Validate IAP receipt | ❌ Not exist | Create Supabase Edge Function |
| `/api/logout` | POST | Clear session tokens | ❌ Not exist | Create Supabase Edge Function |
| `/api/user` | DELETE | Account deletion | ❌ Not exist | Create Supabase Edge Function |
| `/api/update-user-settings` | PATCH | Update language/theme | ❌ Not exist | Create Supabase Edge Function |

**API Complexity:** 6 endpoints needed (likely 3-4 new ones to create)

---

## 🎨 Design System Compliance Analysis

### **Color Tokens Required** (Design Rulebook line 23-68)

| Use Case | Token | Verified in Assets? |
|----------|-------|---------------------|
| Avatar background | `BrandPrimary` | ✅ Yes |
| Card backgrounds | `SurfaceCard` | ✅ Yes |
| Main background | `SurfaceBase` | ✅ Yes |
| Primary text | `TextPrimary` | ✅ Yes |
| Secondary text | `TextSecondary` | ✅ Yes |
| Warning states | `AccentWarning` | ✅ Yes |
| Success states | `AccentSuccess` | ✅ Yes |
| Error states | `AccentError` | ✅ Yes |
| Accent color | `Accent` | ✅ Yes |

**Design Token Status:** ✅ All required colors exist

---

### **Typography Requirements** (Design Rulebook line 74-104)

```swift
// Profile Header
.largeTitle          // "Profile" (34pt Bold)
.title2              // User name (22pt Semibold)
.body                // Email, tier (17pt Regular)

// Section Headers
.headline            // "Account", "Settings" (17pt Semibold)

// Labels & Values
.body                // All text fields (17pt Regular)
.caption             // Version info (12pt Regular)

// Buttons
.headline            // Button text (17pt Semibold)
```

**Typography Status:** ✅ All SF Pro styles available

---

### **Layout Requirements** (Design Rulebook line 107-128)

```swift
// Spacing
.padding(16)         // Content padding
.padding(24)         // Section spacing
.spacing(12)         // VStack spacing
.spacing(16)         // Section groups

// Corner Radius
.cornerRadius(12)    // Cards
.cornerRadius(8)     // Buttons

// Shadows
.shadow(color: .black.opacity(0.1), radius: 4, y: 2)
```

**Layout Status:** ✅ Follows 8pt grid system

---

## 🧩 Component Breakdown

### **1. ProfileHeader Component**

**Purpose:** Display user identity with avatar, name, email, tier

```
┌─────────────────────────────────┐
│   [👤 Avatar - 96x96]           │
│   Name: "Guest User"            │
│   Email: "—"                    │
│   Tier: 🎁 Free Tier            │
└─────────────────────────────────┘
```

**Props:**
```swift
struct ProfileHeader: View {
    let userName: String
    let email: String?
    let tier: String
    let isGuest: Bool
}
```

**Design Details:**
- Avatar: 96×96 circular, uses SF Symbol "person.circle.fill"
- Tier badge: Color-coded (Gray for free, Purple for premium)
- Guest users show "—" for email

**Complexity:** Medium (conditional rendering, tier badge logic)

---

### **2. CreditInfoSection Component**

**Purpose:** Display credit balance with action buttons

```
┌─────────────────────────────────┐
│ 💳 Credits: 8 / 10              │
│ [⚡ Buy Credits] [📜 History]   │
└─────────────────────────────────┘
```

**Props:**
```swift
struct CreditInfoSection: View {
    let creditsRemaining: Int
    let creditsTotal: Int
    let onBuyCredits: () -> Void
    let onViewHistory: () -> Void
    let canBuyCredits: Bool  // False for guests
}
```

**Design Details:**
- Credit display: Large text with icon
- Buttons: `.borderedProminent` style
- Disabled state for guests (show tooltip)

**Complexity:** Medium (button states, conditional disabling)

---

### **3. AccountSection Component**

**Purpose:** Authentication actions and account management

```
┌─────────────────────────────────┐
│ 🧾 Account                      │
│ ├─ Sign in with Apple / Logout │
│ ├─ Restore Purchases            │
│ ├─ Delete Account               │
└─────────────────────────────────┘
```

**Props:**
```swift
struct AccountSection: View {
    let isGuest: Bool
    let onSignIn: () -> Void
    let onSignOut: () -> Void
    let onRestorePurchases: () -> Void
    let onDeleteAccount: () -> Void
}
```

**Design Details:**
- Conditional button: "Sign in" vs "Sign Out"
- Restore only visible for logged-in users
- Delete account: Red text, confirmation alert
- Sign in button uses SignInWithAppleButton

**Complexity:** High (authentication logic, multiple actions)

---

### **4. SettingsSection Component**

**Purpose:** App settings with dropdowns

```
┌─────────────────────────────────┐
│ ⚙️ App Settings                 │
│ ├─ Language ▾ [English]         │
│ ├─ Theme ▾ [System]             │
│ └─ Version: 1.0.0               │
└─────────────────────────────────┘
```

**Props:**
```swift
struct SettingsSection: View {
    @Binding var selectedLanguage: String
    @Binding var selectedTheme: String
    let appVersion: String
    let onLanguageChange: (String) -> Void
    let onThemeChange: (String) -> Void
}
```

**Design Details:**
- Uses SettingsDropdown for language/theme
- Version is read-only text
- Dropdowns expand/collapse with animation

**Complexity:** Medium (dropdown state, persistence)

---

### **5. SettingsDropdown Component**

**Purpose:** Reusable dropdown picker with animation

```
Language ▾ [English]
  ↓ Tapped
┌──────────────┐
│ English   ✓  │
│ Türkçe       │
│ Español      │
└──────────────┘
```

**Props:**
```swift
struct SettingsDropdown: View {
    let label: String
    @Binding var selectedValue: String
    let options: [String]
    let onSelect: (String) -> Void
}
```

**Design Details:**
- Picker style: `.menu`
- Animation: 0.3s ease-in-out
- Checkmark on selected item
- Background: `SurfaceCard`

**Complexity:** Medium (Picker binding, animation)

---

## 🔌 Service Layer Requirements

### **1. AuthService**

**Purpose:** Handle Apple Sign-In flow

```swift
import AuthenticationServices

protocol AuthServiceProtocol {
    func signInWithApple() async throws -> AppleAuthResult
    func signOut() async throws
    func getCurrentUser() async throws -> User?
}

class AuthService: NSObject, AuthServiceProtocol, ASAuthorizationControllerDelegate {
    static let shared = AuthService()

    func signInWithApple() async throws -> AppleAuthResult {
        // 1. Create ASAuthorizationAppleIDProvider
        // 2. Create request with .fullName and .email scopes
        // 3. Present ASAuthorizationController
        // 4. Handle delegate callbacks
        // 5. Extract apple_sub, name, email
        // 6. Return AppleAuthResult
    }
}

struct AppleAuthResult {
    let appleSub: String
    let fullName: PersonNameComponents?
    let email: String?
}
```

**Dependencies:**
- `AuthenticationServices` framework
- `ASAuthorizationControllerDelegate` conformance
- Keychain for device_id retrieval

**Complexity:** High (delegate pattern, async bridging)

---

### **2. StoreKitManager**

**Purpose:** Handle in-app purchases

```swift
import StoreKit

protocol StoreKitManagerProtocol {
    func fetchProducts() async throws -> [Product]
    func purchase(product: Product) async throws -> Transaction?
    func restorePurchases() async throws -> [Transaction]
}

class StoreKitManager: StoreKitManagerProtocol {
    static let shared = StoreKitManager()

    // Product IDs
    enum ProductID: String, CaseIterable {
        case credits_10 = "com.rendio.credits.10"
        case credits_50 = "com.rendio.credits.50"
        case credits_100 = "com.rendio.credits.100"
        case premium_monthly = "com.rendio.premium.monthly"
    }

    func purchase(product: Product) async throws -> Transaction? {
        // 1. Start purchase flow
        // 2. Handle purchase result
        // 3. Verify transaction
        // 4. Return transaction for receipt validation
    }
}
```

**Dependencies:**
- StoreKit 2 framework
- App Store Connect configuration
- Receipt validation endpoint

**Complexity:** Very High (StoreKit 2 API, receipt validation)

---

### **3. UserSettingsService**

**Purpose:** Persist and sync user preferences

```swift
protocol UserSettingsServiceProtocol {
    func saveLanguage(_ language: String, userId: String?) async throws
    func saveTheme(_ theme: String, userId: String?) async throws
    func fetchSettings(userId: String?) async throws -> UserSettings
}

class UserSettingsService: UserSettingsServiceProtocol {
    static let shared = UserSettingsService()

    func saveLanguage(_ language: String, userId: String?) async throws {
        // If logged in: Update Supabase users.language
        // If guest: Save to UserDefaults
        // Apply locale change app-wide
    }
}

struct UserSettings: Codable {
    var language: String
    var theme: String
}
```

**Dependencies:**
- Supabase client for logged-in users
- UserDefaults for guests
- Locale management

**Complexity:** Medium (dual persistence strategy)

---

### **4. UserService (New)**

**Purpose:** Fetch and update user profile data

```swift
protocol UserServiceProtocol {
    func fetchUserProfile(userId: String) async throws -> User
    func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User
    func deleteAccount(userId: String) async throws
}

class UserService: UserServiceProtocol {
    static let shared = UserService()

    func fetchUserProfile(userId: String) async throws -> User {
        // GET /api/profile?user_id=x
        // Returns user details + credits
    }

    func mergeGuestToUser(deviceId: String, appleSub: String) async throws -> User {
        // POST /api/merge-guest-to-user
        // Backend merges guest data to registered account
    }
}
```

**Dependencies:**
- Supabase client
- API endpoints (need to be created)

**Complexity:** Medium (HTTP client, error handling)

---

## 🌍 Localization Requirements

### **Existing Strings** (Already in Localizable.strings)

```
✅ profile.title = "Profile"
✅ profile.credits = "Credits"
✅ profile.coming_soon = "Coming soon..."
✅ profile.settings = "Settings"
✅ profile.language = "Language"
✅ profile.theme = "Theme"
✅ profile.sign_in = "Sign in with Apple"
✅ profile.sign_out = "Sign Out"
✅ profile.delete_account = "Delete Account"
```

### **Missing Strings** (Need to be added)

```swift
// Account Section
"profile.account_title" = "Account"
"profile.restore_purchases" = "Restore Purchases"

// Credit Section
"profile.credits_remaining" = "%d / %d credits"
"profile.buy_credits" = "Buy Credits"
"profile.view_history" = "View History"
"profile.guest_cannot_purchase" = "Sign in to purchase credits"

// User Info
"profile.guest_user" = "Guest User"
"profile.tier_free" = "Free Tier"
"profile.tier_premium" = "Premium Tier"
"profile.email_hidden" = "—"

// Theme Options
"profile.theme_system" = "System"
"profile.theme_light" = "Light"
"profile.theme_dark" = "Dark"

// Language Options
"profile.language_english" = "English"
"profile.language_turkish" = "Türkçe"
"profile.language_spanish" = "Español"

// Alerts
"profile.delete_account_title" = "Delete Account?"
"profile.delete_account_message" = "This will permanently delete all your data. This action cannot be undone."
"profile.sign_out_title" = "Sign Out?"
"profile.sign_out_message" = "You will return as a guest user."
"profile.purchase_success" = "Credits purchased successfully!"
"profile.restore_success" = "Purchases restored successfully!"

// Errors
"profile.sign_in_failed" = "Sign in failed. Please try again."
"profile.purchase_failed" = "Purchase failed. Please try again."
"profile.delete_failed" = "Account deletion failed. Please contact support."

// App Version
"profile.app_version" = "Version"
```

**Total New Strings:** 24 keys × 3 languages = **72 new localizations**

---

## 📊 Database Schema Verification

### **Users Table** (From data-schema-final.md)

```sql
CREATE TABLE users (
    id uuid PRIMARY KEY,
    email text,
    device_id text,
    apple_sub text,
    is_guest boolean DEFAULT true,
    tier text DEFAULT 'free',
    credits_remaining integer DEFAULT 10,
    initial_grant_claimed boolean DEFAULT false,
    language text DEFAULT 'en',
    theme_preference text DEFAULT 'system',
    created_at timestamp DEFAULT now(),
    updated_at timestamp DEFAULT now()
);
```

**Status:** ✅ Schema supports all Profile requirements

**Key Columns for Profile:**
- `apple_sub` → Apple Sign-In identifier
- `is_guest` → Determines UI state
- `tier` → Free vs Premium badge
- `credits_remaining` → Credit display
- `language` → Language dropdown
- `theme_preference` → Theme dropdown

---

## 🚨 Gap Analysis

### **What Exists** ✅

| Item | Location | Status |
|------|----------|--------|
| Design Tokens | `Assets.xcassets/` | ✅ Complete |
| Basic ProfileView | `Features/Profile/ProfileView.swift` | ⚠️ Placeholder only |
| Some Localization | `Localizations/*/Localizable.strings` | ⚠️ Partial (9/33 strings) |
| Database Schema | Supabase | ✅ Users table ready |
| Tab Navigation | `ContentView.swift` | ✅ Profile tab exists |
| PrimaryButton | `Shared/Components/` | ✅ Reusable component |

---

### **What's Missing** ❌

| Category | Missing Items | Priority |
|----------|---------------|----------|
| **Components** | ProfileHeader, CreditInfoSection, AccountSection, SettingsSection, SettingsDropdown | 🔴 Critical |
| **ViewModel** | ProfileViewModel | 🔴 Critical |
| **Services** | AuthService, StoreKitManager, UserSettingsService, UserService | 🔴 Critical |
| **Localization** | 24 new keys × 3 languages | 🟡 High |
| **API Endpoints** | 4-6 new Edge Functions | 🔴 Critical |
| **Models** | User model, UserSettings model, AppleAuthResult model | 🟡 High |
| **Utilities** | Keychain helper for device_id | 🟡 High |

---

## 🔢 Implementation Complexity Breakdown

### **Effort Estimation** (Developer Days)

| Task | Complexity | Estimated Days | Dependencies |
|------|------------|----------------|--------------|
| **1. Component Development** | | | |
| ProfileHeader | Medium | 0.5 | Design tokens |
| CreditInfoSection | Medium | 0.5 | Design tokens |
| AccountSection | High | 1.0 | AuthService |
| SettingsSection | Medium | 0.5 | SettingsDropdown |
| SettingsDropdown | Medium | 0.5 | None |
| **2. ViewModel** | | | |
| ProfileViewModel | High | 1.5 | All services |
| **3. Services** | | | |
| AuthService | Very High | 2.0 | AuthenticationServices, Backend |
| StoreKitManager | Very High | 2.5 | StoreKit 2, App Store Connect |
| UserSettingsService | Medium | 1.0 | Supabase, UserDefaults |
| UserService | Medium | 1.0 | Supabase client |
| **4. Backend** | | | |
| API Endpoints | Very High | 3.0 | Supabase Edge Functions |
| **5. Localization** | | | |
| 72 new strings | Low | 0.5 | Translation service |
| **6. Integration** | | | |
| Wire up all flows | High | 2.0 | All components/services |
| **7. Testing** | | | |
| Manual + Edge cases | High | 2.0 | Complete implementation |

**Total Estimated Effort:** ~17 developer days

**Confidence Level:** Medium (complexity with Apple Sign-In and StoreKit)

---

## ⚠️ Risks & Considerations

### **High Risk Areas**

1. **Apple Sign-In Integration** ⚠️
   - **Risk:** Delegate pattern complexity, async bridging
   - **Mitigation:** Use Apple's sample code, extensive testing
   - **Impact:** High - Core authentication feature

2. **StoreKit 2 Receipt Validation** ⚠️
   - **Risk:** Server-side validation errors, refund handling
   - **Mitigation:** Use Supabase Edge Function with Apple's validation API
   - **Impact:** Very High - Revenue critical

3. **Guest-to-User Merge Logic** ⚠️
   - **Risk:** Data loss during merge, race conditions
   - **Mitigation:** Atomic database transactions, thorough testing
   - **Impact:** High - User trust

4. **Account Deletion (GDPR)** ⚠️
   - **Risk:** Incomplete data cleanup, legal compliance
   - **Mitigation:** Cascade deletes, audit trail, legal review
   - **Impact:** Very High - Legal requirement

5. **Language/Theme Hot Reload** ⚠️
   - **Risk:** App restart required vs. instant UI update
   - **Mitigation:** Use SwiftUI environment for theme, locale for language
   - **Impact:** Medium - UX quality

---

### **Medium Risk Areas**

1. **Multi-Language Support**
   - 72 new strings need accurate translation
   - Consider professional translation service

2. **IAP Testing**
   - Requires sandbox environment
   - Need test Apple ID accounts

3. **Keychain Access**
   - Device ID must persist across app reinstalls
   - Proper error handling for access failures

---

## 🔄 Dependencies & Prerequisites

### **Before Starting Implementation:**

1. ✅ **Design System Complete** - All color tokens exist
2. ✅ **Database Schema Ready** - Users table has required columns
3. ✅ **Tab Navigation Working** - Profile tab accessible
4. ⏳ **App Store Connect Setup** - IAP products configured
5. ⏳ **Apple Sign-In Capability** - Enabled in Xcode
6. ⏳ **Backend API Endpoints** - Edge Functions created
7. ⏳ **Keychain Helper** - Utility for device_id

---

### **External Dependencies:**

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| SwiftUI | iOS 17+ | UI framework | ✅ Available |
| AuthenticationServices | iOS 17+ | Apple Sign-In | ✅ Available |
| StoreKit 2 | iOS 17+ | In-app purchases | ✅ Available |
| Supabase Swift SDK | Latest | Backend client | ✅ Installed |
| Keychain Access | iOS SDK | Device ID storage | ✅ Available |

---

## 📐 Architectural Decisions

### **1. Authentication Pattern**

**Decision:** Use AuthenticationServices with delegate pattern

**Rationale:**
- Native Apple Sign-In flow
- Secure credential handling
- SwiftUI integration with `SignInWithAppleButton`

**Alternative Considered:** Firebase Auth (Rejected - already using Supabase)

---

### **2. IAP Implementation**

**Decision:** Use StoreKit 2 (async/await API)

**Rationale:**
- Modern Swift concurrency
- Simplified receipt validation
- Better error handling

**Alternative Considered:** StoreKit 1 (Rejected - legacy API)

---

### **3. Settings Persistence**

**Decision:** Dual strategy (Supabase + UserDefaults)

**Rationale:**
- Logged-in users: Sync across devices via Supabase
- Guests: Local only via UserDefaults
- Seamless transition when guest signs in

**Alternative Considered:** Always local (Rejected - no cross-device sync)

---

### **4. Language Switching**

**Decision:** Apply immediately without app restart

**Rationale:**
- Better UX
- Use SwiftUI `.environment(\.locale)`
- Trigger view refresh with state change

**Alternative Considered:** Require restart (Rejected - poor UX)

---

## 🎯 Success Criteria (From Blueprint)

| Criteria | Verification Method | Status |
|----------|-------------------|--------|
| 1. User can see identity (guest/logged-in) | Visual inspection + unit test | ⏳ Pending |
| 2. Credit balance accurate and refreshed | Integration test with backend | ⏳ Pending |
| 3. Sign in merges guest data seamlessly | End-to-end test | ⏳ Pending |
| 4. Purchase flow validated via receipts | IAP sandbox test | ⏳ Pending |
| 5. Layout consistent with other screens | Design review | ⏳ Pending |
| 6. Language/Theme settings persist | Integration test | ⏳ Pending |
| 7. Dropdown animations smooth | Manual UX test | ⏳ Pending |

---

## 📝 Recommended Implementation Sequence

### **Phase 1: Foundation** (Days 1-3)

1. ✅ Create ProfileViewModel with basic state
2. ✅ Create User and UserSettings models
3. ✅ Implement UserService (fetch profile)
4. ✅ Build ProfileHeader component
5. ✅ Build CreditInfoSection component
6. ✅ Add 72 new localization strings (all languages)

---

### **Phase 2: UI Components** (Days 4-5)

7. ✅ Build SettingsDropdown component
8. ✅ Build SettingsSection component
9. ✅ Build AccountSection component (placeholder actions)
10. ✅ Wire up ProfileView with all components
11. ✅ Test UI with mock data

---

### **Phase 3: Authentication** (Days 6-8)

12. ✅ Create AuthService with Apple Sign-In
13. ✅ Implement sign-in flow in ProfileViewModel
14. ✅ Create `/api/merge-guest-to-user` endpoint
15. ✅ Test guest-to-user merge flow
16. ✅ Implement sign-out flow

---

### **Phase 4: In-App Purchases** (Days 9-11)

17. ✅ Create StoreKitManager
18. ✅ Configure IAP products in App Store Connect
19. ✅ Create `/api/validate-receipt` endpoint
20. ✅ Implement purchase flow
21. ✅ Implement restore purchases
22. ✅ Test with sandbox accounts

---

### **Phase 5: Settings & Polish** (Days 12-14)

23. ✅ Implement UserSettingsService
24. ✅ Create settings update endpoint (or use direct Supabase)
25. ✅ Wire up language/theme persistence
26. ✅ Test hot-reload of settings
27. ✅ Implement account deletion flow
28. ✅ Add loading states and error handling

---

### **Phase 6: Testing & Refinement** (Days 15-17)

29. ✅ End-to-end testing of all flows
30. ✅ Edge case testing (network errors, timeouts)
31. ✅ Accessibility review
32. ✅ Performance optimization
33. ✅ Design review and polish
34. ✅ Prepare for TestFlight

---

## 📚 Required Documentation References

### **Already Available:**

- ✅ `design/blueprints/profile-screen.md` - Feature specification
- ✅ `design/design-rulebook.md` - Design system
- ✅ `design/database/data-schema-final.md` - Database schema
- ✅ `.claude/project-instructions.md` - Architecture rules
- ✅ `COLORS_QUICK_REFERENCE.md` - Color tokens
- ✅ `LOCALIZATION_SYSTEM_SETUP_SUMMARY.md` - i18n setup

### **Need to Create:**

- ❌ Apple Sign-In integration guide
- ❌ StoreKit 2 implementation guide
- ❌ IAP testing procedures
- ❌ Account deletion GDPR checklist

---

## 🎓 Learning Resources Needed

### **For Apple Sign-In:**
- Apple Developer: AuthenticationServices documentation
- WWDC: "Sign in with Apple" sessions
- Sample code: Apple's authentication sample

### **For StoreKit 2:**
- Apple Developer: StoreKit 2 documentation
- WWDC: "Meet StoreKit 2" session
- Receipt validation best practices

### **For Supabase Edge Functions:**
- Supabase: Edge Functions documentation
- Deno runtime documentation (Edge Functions use Deno)

---

## 🚦 Ready to Implement?

### **Readiness Checklist:**

| Area | Status | Blocker? |
|------|--------|----------|
| Design System | ✅ Ready | No |
| Database Schema | ✅ Ready | No |
| Localization Infrastructure | ✅ Ready | No |
| Tab Navigation | ✅ Ready | No |
| Backend Infrastructure | ⏳ Partial | Yes - Need Edge Functions |
| Apple Sign-In Setup | ⏳ Pending | Yes - Need capability |
| IAP Configuration | ⏳ Pending | Yes - Need products |
| Developer Knowledge | ⏳ Partial | Yes - Need StoreKit experience |

**Overall Readiness:** 🟡 **60% Ready**

**Blockers:**
1. Backend API endpoints need to be created
2. Apple Sign-In capability needs to be enabled
3. IAP products need to be configured in App Store Connect
4. Team needs StoreKit 2 training

---

## 💡 Final Recommendations

### **1. Start with Foundation**
Begin with ProfileViewModel, models, and basic components. This allows UI development while backend work proceeds in parallel.

### **2. Prioritize Authentication**
Apple Sign-In is critical for IAP and full functionality. Focus on this after foundation is solid.

### **3. Mock Services for Development**
Create mock implementations of AuthService and StoreKitManager for UI development without blocking on backend.

### **4. Incremental Testing**
Test each phase thoroughly before moving to next. Authentication bugs are harder to debug later.

### **5. Consider Phased Rollout**
- Phase 1: UI + mock data
- Phase 2: Authentication only
- Phase 3: Full IAP integration
- Phase 4: Polish + edge cases

---

## 📊 Complexity Comparison

| Screen | Previous Score | Profile Estimated | Reason |
|--------|----------------|-------------------|--------|
| HomeView | 7.5/10 → 9.5/10 | - | Fixed and excellent |
| ModelDetail | 9.2/10 | - | Excellent implementation |
| TabMenu | 9.5/10 | - | Outstanding |
| **ProfileView** | - | **9/10 (Very High)** | Most complex feature yet |

**Profile is the most complex screen in the app** due to:
- External service integrations (Apple, StoreKit)
- Multiple async flows
- Security-critical operations
- GDPR compliance requirements

---

## ✅ Analysis Complete

**Status:** 🎯 **READY FOR PLANNING PHASE**

**Next Steps:**
1. Review this analysis with team
2. Prioritize blockers (Backend, App Store Connect)
3. Create detailed implementation plan
4. Assign tasks to development phases
5. Begin Phase 1: Foundation

**Estimated Timeline:** 17 developer days (~3-4 weeks with testing)

---

**Analyzed by:** Claude Code
**Date:** 2025-11-05
**Confidence:** High (comprehensive analysis with all context)
