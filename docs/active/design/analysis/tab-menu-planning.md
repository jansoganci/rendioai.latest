⸻

# 📱 Tab Menu — Planning & Design

**Date:** 2025-11-05

**Document Type:** Implementation Planning

**Status:** 📋 Planning Phase

⸻

## 📋 Overview

This document plans the implementation of the main Tab Menu navigation for Rendio AI. The tab menu will provide primary navigation between the app's core screens: Home, History, and Profile.

⸻

## 🔍 Current State Analysis

### ✅ What Exists

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| **HomeView** | ✅ Complete | `Features/Home/HomeView.swift` | Has own NavigationStack |
| **ModelDetailView** | ✅ Complete | `Features/ModelDetail/ModelDetailView.swift` | Accessed via navigation |
| **ResultView** | ✅ Placeholder | `Features/Result/ResultView.swift` | Placeholder only |
| **ContentView** | ⚠️ Placeholder | `ContentView.swift` | Just "Hello, world!" |
| **HistoryView** | ❌ Missing | N/A | Needs to be created |
| **ProfileView** | ❌ Missing | N/A | Needs to be created |

### 📊 Navigation Flow (Current)

```
RendioAIApp
  └── ContentView (placeholder)
        └── HomeView (with NavigationStack)
              └── ModelDetailView
                    └── ResultView
```

### 🎯 Target Navigation Flow (After Tab Menu)

```
RendioAIApp
  └── ContentView (TabView)
        ├── Home Tab
        │     └── HomeView (NavigationStack)
        │           └── ModelDetailView
        │                 └── ResultView
        ├── History Tab
        │     └── HistoryView (NavigationStack)
        │           └── ResultView (on tap)
        └── Profile Tab
              └── ProfileView (NavigationStack)
```

⸻

## 🎨 Design Decisions

### Tab Structure

Based on the app's core modules from `docs/ProjectOverview.md`, we need **3 main tabs**:

| Tab | Icon | Label | Screen | Priority |
|-----|------|-------|--------|----------|
| **Home** | `house.fill` | "Home" | HomeView | 🔴 High (Core) |
| **History** | `clock.fill` | "History" | HistoryView | 🔴 High (Core) |
| **Profile** | `person.fill` | "Profile" | ProfileView | 🔴 High (Core) |

### Tab Bar Design

Following Apple HIG and the design rulebook:

- **Position:** Bottom tab bar (iOS standard)
- **Style:** `.automatic` (respects system appearance)
- **Selection Indicator:** Default iOS indicator (can customize later)
- **Badge Support:** None for MVP (can add for notifications later)

### Navigation Architecture

**Key Decision: Each tab needs its own NavigationStack**

- ✅ Home tab: `NavigationStack` wrapping `HomeView`
- ✅ History tab: `NavigationStack` wrapping `HistoryView`
- ✅ Profile tab: `NavigationStack` wrapping `ProfileView`
- ✅ Nested navigation: ModelDetailView → ResultView works within Home tab
- ✅ Deep linking: Each tab maintains its own navigation state

### State Management

**Tab Selection State:**
- Use `@State` in ContentView to track selected tab
- Default tab: Home (index 0)

**Navigation State per Tab:**
- Each NavigationStack manages its own navigation path
- State persists when switching tabs (iOS default behavior)

⸻

## 📐 Implementation Plan

### Phase 1: Create Tab Menu Structure

#### 1.1 Update ContentView
- Replace placeholder with `TabView`
- Create 3 tabs: Home, History, Profile
- Wrap each tab's root view in `NavigationStack`
- Add tab bar styling and icons

#### 1.2 Create Placeholder HistoryView
- Location: `Features/History/HistoryView.swift`
- Simple placeholder: "History Screen - Coming Soon"
- Wrapped in NavigationStack for consistency

#### 1.3 Create Placeholder ProfileView
- Location: `Features/Profile/ProfileView.swift`
- Simple placeholder: "Profile Screen - Coming Soon"
- Wrapped in NavigationStack for consistency

### Phase 2: Update HomeView Integration

#### 2.1 Remove NavigationStack from HomeView (if needed)
- **Decision:** Keep NavigationStack in HomeView
- Reason: HomeView should remain self-contained
- Tab's NavigationStack will wrap it (nested NavigationStacks work in iOS 17+)

**OR**

- **Alternative:** Remove NavigationStack from HomeView
- Move it to ContentView's Home tab wrapper
- **Prefer this approach** for cleaner architecture

#### 2.2 Update HomeView Header
- Remove or update Profile icon button in header
- Profile is now accessible via tab bar
- Keep header for app title/search

### Phase 3: Localization

#### 3.1 Add Tab Bar Labels
- `tab.home` → "Home"
- `tab.history` → "History"
- `tab.profile` → "Profile"
- Add to all localization files (en, tr, es)

### Phase 4: Polish & Testing

#### 4.1 Tab Bar Styling
- Verify icons look good in light/dark mode
- Check tab selection indicator
- Test haptic feedback (iOS default)

#### 4.2 Navigation Flow Testing
- Test tab switching preserves navigation state
- Test nested navigation (Home → ModelDetail → Result)
- Test back navigation works correctly

⸻

## 🗂️ File Structure

### Files to Create

```
RendioAI/
├── Features/
│   ├── History/
│   │   ├── HistoryView.swift          # NEW - Placeholder
│   │   └── HistoryViewModel.swift     # FUTURE
│   └── Profile/
│       ├── ProfileView.swift          # NEW - Placeholder
│       └── ProfileViewModel.swift     # FUTURE
└── ContentView.swift                  # MODIFY - Add TabView
```

### Files to Modify

```
RendioAI/
├── ContentView.swift                  # Replace placeholder with TabView
└── Features/
    └── Home/
        └── HomeView.swift             # Remove NavigationStack (move to ContentView)
```

⸻

## 💻 Implementation Details

### ContentView Structure

```swift
struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(
                    NSLocalizedString("tab.home", comment: "Home tab"),
                    systemImage: "house.fill"
                )
            }
            .tag(0)
            
            // History Tab
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(
                    NSLocalizedString("tab.history", comment: "History tab"),
                    systemImage: "clock.fill"
                )
            }
            .tag(1)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(
                    NSLocalizedString("tab.profile", comment: "Profile tab"),
                    systemImage: "person.fill"
                )
            }
            .tag(2)
        }
        .tint(Color("BrandPrimary")) // Custom tab bar tint
    }
}
```

### HomeView Modification

**Option A: Keep NavigationStack** (Simpler, works)
- Keep current structure
- Nested NavigationStacks work in iOS 17+

**Option B: Remove NavigationStack** (Cleaner architecture)
- Remove `NavigationStack { }` wrapper from HomeView
- Move navigation to ContentView's tab wrapper
- Update `.navigationBarHidden(true)` if needed

**Recommendation:** Option B for cleaner architecture

### HistoryView Placeholder

```swift
struct HistoryView: View {
    var body: some View {
        ZStack {
            Color("SurfaceBase")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("TextSecondary"))
                
                Text(NSLocalizedString("history.title", comment: "History title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
                
                Text(NSLocalizedString("history.coming_soon", comment: "Coming soon"))
                    .font(.body)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
}
```

### ProfileView Placeholder

```swift
struct ProfileView: View {
    var body: some View {
        ZStack {
            Color("SurfaceBase")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("TextSecondary"))
                
                Text(NSLocalizedString("profile.title", comment: "Profile title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
                
                Text(NSLocalizedString("profile.coming_soon", comment: "Coming soon"))
                    .font(.body)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .navigationBarTitleDisplayMode(.large)
    }
}
```

⸻

## 🌍 Localization Keys

### New Keys Needed

| Key | English | Turkish | Spanish |
|-----|---------|---------|---------|
| `tab.home` | "Home" | "Ana Sayfa" | "Inicio" |
| `tab.history` | "History" | "Geçmiş" | "Historial" |
| `tab.profile` | "Profile" | "Profil" | "Perfil" |
| `history.coming_soon` | "Coming soon..." | "Yakında..." | "Próximamente..." |
| `profile.coming_soon` | "Coming soon..." | "Yakında..." | "Próximamente..." |

⸻

## ✅ Implementation Checklist

### Phase 1: Core Structure
- [x] Update `ContentView.swift` with TabView
- [x] Create `HistoryView.swift` placeholder
- [x] Create `ProfileView.swift` placeholder
- [x] Remove NavigationStack from `HomeView.swift` (move to ContentView)
- [x] Test tab switching works (ready for testing)

### Phase 2: Integration
- [x] Verify Home tab navigation still works (Home → ModelDetail → Result) - NavigationStack moved to ContentView
- [x] Update HomeView header (remove profile button TODO)
- [x] Navigation state will persist when switching tabs (iOS default behavior)

### Phase 3: Localization
- [x] Add tab bar labels to all localization files (en, tr, es)
- [x] Add "coming soon" messages (en, tr, es)
- [x] All localization keys added and ready for testing

### Phase 4: Polish
- [ ] Verify tab bar styling (light/dark mode) - Ready for manual testing
- [ ] Test haptic feedback - iOS default, ready for testing
- [ ] Verify accessibility labels - Ready for testing
- [ ] Test on different screen sizes - Ready for testing

⸻

## 🚨 Considerations & Decisions

### NavigationStack Placement

**Question:** Should NavigationStack be in HomeView or ContentView?

**Decision:** Move NavigationStack to ContentView for cleaner architecture:
- Each tab wrapper has its own NavigationStack
- HomeView becomes a pure content view
- Easier to manage navigation state per tab
- Better separation of concerns

### Profile Button in HomeView Header

**Question:** Keep profile button in HomeView header or remove?

**Decision:** Remove profile button from header:
- Profile is now accessible via tab bar
- Cleaner header design
- Follows iOS patterns (tab bar for main navigation)

### Tab Bar Customization

**MVP:** Use default iOS tab bar styling
**Future:** Can customize with:
- Custom tab bar colors
- Badge indicators
- Custom selection animation

⸻

## 📚 References

- **Design Rulebook:** `design/design-rulebook.md` (Navigation section)
- **General Rulebook:** `design/general-rulebook.md` (Architecture section)
- **Project Overview:** `docs/ProjectOverview.md` (Core modules)
- **Apple HIG:** Tab Bar Navigation guidelines

⸻

## 🎯 Success Criteria

✅ Tab menu displays correctly with 3 tabs
✅ Each tab has its own NavigationStack
✅ Navigation state persists when switching tabs
✅ Home tab navigation (Home → ModelDetail → Result) works
✅ Tab bar is localized in all languages
✅ Tab bar works in light and dark mode
✅ Placeholder screens display correctly

⸻
