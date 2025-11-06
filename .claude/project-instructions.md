# Rendio AI – Claude Code Project Instructions

**Version:** 1.0.0
**Platform:** iOS 17+ (SwiftUI + Supabase + FalAI)
**Architecture:** MVVM with Service Layer
**Philosophy:** "Minimal friction, maximum fun"

---

## 🎯 Project Identity

Rendio AI is an iOS video generation app that turns text prompts into AI-generated videos using FalAI Veo 3.1 and Sora 2. Users get 10 free credits, then purchase via IAP.

**Core Tech Stack:**
- Frontend: SwiftUI (iOS 17+), MVVM architecture
- Backend: Supabase (Auth, Storage, Database, Edge Functions)
- AI: FalAI Veo 3.1 (text-to-video), Sora 2 (image-to-video)
- Security: DeviceCheck, RLS policies, private storage buckets

---

## 🏗️ Architecture Rules

### Folder Structure
```
RendioAI/
├── Features/              # Self-contained MVVM modules
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   ├── ModelDetail/
│   ├── Result/
│   ├── History/
│   └── Profile/
├── Core/                  # Business logic
│   ├── Networking/        # API services
│   ├── Models/            # Data models
│   └── Utilities/         # DeviceCheck, Keychain
├── Shared/                # Reusable UI
│   ├── Components/        # PrimaryButton, CardView, etc.
│   ├── Extensions/
│   └── ViewModifiers/
└── Resources/
    ├── Assets.xcassets/
    ├── Localizations/
    └── Config/
```

### Key Patterns
- **MVVM:** View → ViewModel → Service → API (unidirectional)
- **No cross-imports between features** — use `Shared/` for common code
- **Adapter pattern** for AI providers (provider-agnostic)
- **Dependency injection** in ViewModels for testability

---

## 🎨 Design System

### Colors (Use semantic names)
```swift
Color("BrandPrimary")    // #6B4FFF (Light) / #8B7CFF (Dark)
Color("SurfaceBase")     // #F8FAFC (Light) / #0D0D0F (Dark)
Color("SurfaceCard")     // #F1F5F9 (Light) / #1E293B (Dark)
Color("TextPrimary")     // #1E1E1E (Light) / #FFFFFF (Dark)
Color("TextSecondary")   // #525252 (Light) / #9CA3AF (Dark)
Color("AccentWarning")   // #F59E0B (Light) / #FBBF24 (Dark)
Color("AccentSuccess")   // #10B981 (Light) / #34D399 (Dark)
```

### Typography
```swift
.largeTitle    // 34pt Bold (Page titles)
.title2        // 22pt Semibold (Section headers)
.headline      // 17pt Semibold (Subsections)
.body          // 17pt Regular (General text)
.caption       // 12pt Regular (Metadata)
```

### Layout
- **Grid:** 8pt base unit
- **Padding:** 16pt content, 24pt sections
- **Corner radius:** 12pt cards, 8pt buttons
- **Shadows:** `.shadow(color: .black.opacity(0.1), radius: 4, y: 2)`

### Animation
```swift
withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
    // 0.2-0.3s for micro-transitions
    // 0.3-0.4s for screen transitions
}
```

---

## 💻 Coding Standards

### Naming Conventions
- **Views:** `HomeView.swift` (PascalCase)
- **ViewModels:** `HomeViewModel.swift`
- **Services:** `VideoService.swift`
- **Variables:** `remainingCredits` (camelCase)
- **Functions:** `generateVideo()` (camelCase)

### Safety Rules
❌ **Never:**
- Force unwrap (`!`)
- Hardcode colors/strings
- Put business logic in Views
- Use completion handlers (use `async/await`)

✅ **Always:**
- Use `guard let`, `if let`, `??` for optionals
- Use design tokens (`Color("BrandPrimary")`)
- Use i18n keys for user-facing text
- Use `@MainActor` for UI updates
- Inject dependencies in ViewModels

### State Management
```swift
@State private var showingSheet = false        // Local UI state
@StateObject private var viewModel = HomeViewModel()  // Owned ViewModel
@ObservedObject var viewModel: HomeViewModel   // Passed from parent
@Published var isLoading = false              // In ViewModels
```

---

## 🔌 Backend Integration

### Database Schema
- **users:** User identity, credits, language, theme preferences
- **video_jobs:** Generation history (prompt, status, video_url)
- **models:** Available AI models (name, cost, provider)
- **quota_log:** Credit transactions

### API Endpoints (Supabase Edge Functions)
- `POST /generate-video` → Returns `job_id`
- `GET /get-video-status?job_id=x` → Returns `video_url`
- `GET /get-video-jobs?user_id=x` → Returns history
- `GET /get-user-credits?user_id=x` → Returns balance
- `POST /update-credits` → Add/deduct credits

### Provider Adapters
```swift
protocol VideoGenerationProvider {
    func generateVideo(input: VideoInput) async throws -> VideoResult
}

// Implementations: FalProvider, SoraProvider
```

---

## 🔐 Security

### Row-Level Security (RLS)
- **users:** `auth.uid() = id`
- **video_jobs:** `auth.uid() = user_id`
- **quota_log:** `auth.uid() = user_id`
- **models:** Public (read-only)

### DeviceCheck
- Generate UUID → Store in Keychain
- Verify with Apple server via backend
- Prevent credit farming (bit0 = initial grant claimed)

### Privacy
- No personal data without Apple Sign-in
- Private storage buckets for videos
- 7-day auto-deletion
- Signed URLs for sharing

---

## ⚙️ Error Handling

### Centralized System
```swift
enum AppError: Error {
    case networkTimeout
    case insufficientCredits
    case invalidDevice
    case unknown
}

struct ErrorMapper {
    static func map(_ error: AppError) -> String {
        switch error {
        case .networkTimeout: return "error.network.timeout"
        case .insufficientCredits: return "error.credit.insufficient"
        // All errors mapped to i18n keys
        }
    }
}
```

### i18n Keys
All user-facing messages use localization keys:
```swift
Text(LocalizationManager.shared.text(for: "error.network.timeout"))
```

---

## 📱 Screen Blueprints

### Home Screen
- Header: Profile icon + app title
- Search bar
- Quota warning banner (conditional)
- Featured carousel (auto-scroll 5s)
- Model grid (2-3 columns)

### Model Detail Screen
- Model name + credit balance
- Prompt input (multi-line)
- Settings panel (collapsible)
- Credit cost display
- Generate button (primary CTA)

### Result Screen
- Video player (AVPlayer, fullscreen support)
- Metadata: prompt, model, cost
- Actions: Save, Share, Regenerate

### History Screen
- Videos grouped by date
- Cards: thumbnail + prompt + status
- Actions: Tap to view, swipe to delete
- 7-day retention

### Profile Screen
- Avatar + name/email + tier
- Credits balance + "Buy Credits"
- Account: Sign in/Log out/Delete
- Settings: Language, Theme dropdowns

---

## 🧩 File Template Examples

### ViewModel
```swift
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var models: [VideoModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let videoService: VideoGenerationService

    init(videoService: VideoGenerationService = .shared) {
        self.videoService = videoService
    }

    func loadModels() {
        Task {
            isLoading = true
            do {
                models = try await videoService.fetchAvailableModels()
            } catch {
                errorMessage = ErrorMapper.map(error)
            }
            isLoading = false
        }
    }
}
```

### View
```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Content
                }
                .padding(.horizontal, 16)
            }
            .background(Color("SurfaceBase"))
            .onAppear {
                viewModel.loadModels()
            }
        }
    }
}
```

---

## ✅ Quality Checklist

Before any code delivery, verify:
- ✅ No force unwraps
- ✅ Design tokens used (no hardcoded colors)
- ✅ i18n keys for user text
- ✅ Error handling via AppError
- ✅ Dependency injection in ViewModels
- ✅ File naming matches type name
- ✅ Proper async/await usage
- ✅ @MainActor for UI updates

---

## 🎯 Development Phases

**Phase 1 (MVP):** Core screens, FalAI Veo 3.1, credit system, TestFlight
**Phase 2:** Image-to-video (Sora 2), dynamic pricing
**Phase 3:** Web dashboard
**Phase 4:** Apple Sign-in, IAP, premium tier
**Phase 5:** AI assistant, personalization

---

**This context is automatically loaded in every session. Follow these rules for consistency and quality.**
