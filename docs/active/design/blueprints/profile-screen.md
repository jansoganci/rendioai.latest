⸻

# 👤 Profile Screen Blueprint – Video App

**Date:** 2025-11-04

**Author:** [You]

**Purpose:**

Provide a centralized screen for user identity, credit balance, and app settings.

Support both guest and logged-in states with contextual actions (Sign in, Buy Credits, Logout).

⸻

## 🧭 User Flow Overview

```
HomeView
   ↓
ProfileView
   ↓
 ├─ Sign in with Apple → Merge guest account
 ├─ View Credits / Buy Credits
 ├─ View History
 └─ Log Out
```

⸻

## 🧱 Layout Overview (Simplified Skeletal Wireframe)

```
┌──────────────────────────────────────────────┐
│ ← Back                 👤 Profile            │  ← Header
├──────────────────────────────────────────────┤
│ [Avatar / User Icon]                         │
│ Name: "Guest User" or Apple ID Name          │
│ Email: "—" or "hidden@privaterelay.apple.com"│
│ Tier: Free / Premium                         │
├──────────────────────────────────────────────┤
│ 💳 Credits: 8 / 10                           │
│ [⚡ Buy Credits] [📜 View History]            │
├──────────────────────────────────────────────┤
│ 🧾 Account                                   │
│ ├─ Sign in with Apple / Log Out              │
│ ├─ Restore Purchases                         │
│ ├─ Delete Account                            │
├──────────────────────────────────────────────┤
│ ⚙️ App Settings                              │
│ ├─ Language ▾ [English]                      │
│ ├─ Theme ▾ [System]                          │
│ └─ Version: 1.0.0                            │
└──────────────────────────────────────────────┘
```

⸻

## 🧩 Component Architecture

| Component | Type | Description |
|-----------|------|-------------|
| ProfileView | View | Screen container |
| ProfileHeader | Component | Avatar, name, email, tier |
| CreditInfoSection | Component | Shows credit count and CTA to buy more |
| AccountSection | Component | Sign in/out, restore purchases, delete account |
| SettingsSection | Component | Language, theme, app version |
| SettingsDropdown | Component | Reusable dropdown for Language and Theme selection |
| ProfileViewModel | ViewModel | Manages user state, credit data, and sign-in logic |
| StoreKitManager | Service | Handles in-app purchases |
| SupabaseService | Service | Fetches user data, merges guest accounts |

⸻

## ⚙️ State Management

| Property | Type | Description |
|----------|------|-------------|
| isGuest | Bool | Whether user is anonymous |
| userName | String | Apple account name or "Guest" |
| email | String | Email address (if available) |
| tier | String | free / premium |
| creditsRemaining | Int | Current available credits |
| creditsTotal | Int | Maximum or purchased total |
| isLoading | Bool | Fetching state |
| selectedLanguage | String | Current language ("English", "Türkçe", "Español") |
| selectedTheme | String | Current theme ("System", "Light", "Dark") |

⸻

## 🔑 Login / Merge Logic

1. **If user is guest**, show "Sign in with Apple" button.

2. **On sign-in success:**
   - Obtain Apple userIdentifier (apple_sub).
   - Call `/api/merge-guest-to-user` with `{ device_id, apple_sub }`.
   - Backend merges guest → registered account and returns merged user.

3. **UI updates immediately:**
   - Show Apple ID name/email.
   - Refresh credit balance and tier.

4. **Logged-in users** see "Log Out" instead of "Sign In".

⸻

## 💰 Credit Purchase Flow

- **Trigger:** "Buy Credits" button → `StoreKitManager.startPurchase()`
- **After purchase:**
  - StoreKit receipt validated on backend (`/api/validate-receipt`)
  - Credits added to `quota_log`
  - ViewModel refreshes `creditsRemaining`

| UI | Behavior |
|----|----------|
| Free user | Opens paywall modal |
| Premium user | Disabled / info only |
| Guest | Prompts sign-in before purchase |

⸻

## 🧾 Account Actions

| Action | Behavior |
|--------|----------|
| Sign in with Apple | Authenticates and merges guest → user |
| Restore Purchases | Validates receipts, restores credits |
| Delete Account | Sends deletion request to backend |
| Log Out | Clears local session, keeps Keychain device_id |
| View History | Navigates to HistoryView |

⸻

## 🎨 Design Tokens & Styling

| Element | Token | Example |
|---------|-------|---------|
| Avatar | Avatar.large | Circular 96×96 |
| Text fields | Typography.body | Gray secondary color |
| Section headers | Typography.subheadline.bold | "Account", "Settings" |
| Primary button | Button.primary | "Buy Credits" |
| Secondary button | Button.secondary | "Sign in / Log out" |
| Background | Surface.primary | Neutral gradient |
| Spacing | Spacing.md | 16pt between sections |
| Dropdown | Select/Picker component | Uses Typography.body, Surface.secondary, Spacing.md padding |
| Dropdown animation | Smooth open/close transition | 0.3s ease-in-out |

⸻

## 🧱 API Dependencies

| Endpoint | Description |
|----------|-------------|
| GET /api/profile?user_id | Fetches user details and credit balance |
| POST /api/merge-guest-to-user | Merges guest into registered account |
| POST /api/validate-receipt | Validates IAP and updates credits |
| POST /api/logout | Clears session tokens |
| DELETE /api/user | Account deletion (if required by law) |

⸻

## 📱 Interactions

| Action | Result |
|--------|--------|
| Tap "Buy Credits" | Opens IAP sheet |
| Tap "View History" | Pushes HistoryView |
| Tap "Sign in" | Opens Apple sign-in sheet |
| Pull to refresh | Reloads user and credit data |
| Long press on credits | Shows quota details (optional tooltip) |
| Tap Language dropdown | Opens language picker, calls `handleLanguageChange(selectedLanguage)` |
| Tap Theme dropdown | Opens theme picker, calls `handleThemeChange(selectedTheme)` |

⸻

## 🔒 Access Control

| User Type | Access |
|-----------|--------|
| Guest | View only, can't buy credits |
| Logged-in | Full access, purchases enabled |
| Premium | Full access + badge |

⸻

## ⚙️ App Settings Details

### Language Selection

- **Label:** "Language"
- **Component:** SettingsDropdown
- **Options:** ["English", "Türkçe", "Español"]
- **Default:** "English"
- **On Selection:** Calls `handleLanguageChange(selectedLanguage)`
- **Persistence:** Saved to user preferences (Supabase `users.language` column or local storage for guests)

### Theme Selection

- **Label:** "Theme"
- **Component:** SettingsDropdown
- **Options:** ["System", "Light", "Dark"]
- **Default:** "System"
- **On Selection:** Calls `handleThemeChange(selectedTheme)`
- **Persistence:** Saved to user preferences (Supabase `users.theme_preference` column or local storage for guests)

### Implementation Notes

- Both dropdowns use the same `SettingsDropdown` component for consistency
- Smooth open/close animations (0.3s ease-in-out)
- Proper padding using `Spacing.md` token
- Typography matches `Typography.body` for labels
- Background uses `Surface.secondary` for dropdown menu
- Values persist immediately on selection
- For logged-in users: sync with Supabase `users` table
- For guest users: store in local storage/UserDefaults

## ✅ Success Criteria

1. User can clearly see who they are (guest / logged-in).
2. Credit balance always accurate and refreshed on screen.
3. Sign in flow merges guest data seamlessly.
4. Purchase flow validated via backend receipts.
5. Layout visually consistent with other screens.
6. Language and Theme settings persist across app launches.
7. Dropdown animations are smooth and responsive.

⸻

**End of Document**

Attach to `/design/blueprints/` as the specification for ProfileView implementation.

⸻
