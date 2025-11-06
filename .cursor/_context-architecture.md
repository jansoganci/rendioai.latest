# 🏗️ Architecture Context — Rendio AI

**Purpose:** Quick reference for code generation — MVVM structure, folder conventions, naming rules.

**Sources:** `design/general-rulebook.md`, `design/design-rulebook.md`

---

## 📁 Folder Structure

```
RendioAI/
├── Features/              # Self-contained feature modules
│   ├── Home/             # HomeView.swift + HomeViewModel.swift
│   ├── ModelDetail/      # Each feature = View + ViewModel + Components/
│   ├── Result/
│   ├── History/
│   └── Profile/
├── Core/                  # Business logic, networking, utilities
│   ├── Networking/       # ApiService, VideoGenerationService
│   ├── Models/           # Codable structs (VideoResult, AppError)
│   ├── Utilities/        # Logger, DeviceCheckManager, KeychainManager
│   └── Constants/        # ApiEndpoints
├── Shared/                # Reusable UI components
│   ├── Components/       # PrimaryButton, CardView, ToastView
│   ├── Extensions/       # Color+, View+, String+ extensions
│   └── ViewModifiers/    # CardStyle, ShadowModifier
└── Resources/             # Assets, Localizations, Config (AppConfig.swift)
```

**Rules:**
- Features are self-contained (no cross-imports)
- Shared components used ≥2 times → move to `/Shared/Components/`
- Core contains business logic only

---

## 🏛️ MVVM Pattern

**Data Flow:** `View → ViewModel → Service → API`

```swift
// View (SwiftUI)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var body: some View {
        Button("Generate") { viewModel.generateVideo() }
    }
}

// ViewModel (@MainActor, ObservableObject)
@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let videoService = VideoGenerationService.shared
    
    func generateVideo() {
        Task {
            isLoading = true
            do {
                let result = try await videoService.generateVideo(...)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// Service (async/await, throws)
class VideoGenerationService {
    func generateVideo(...) async throws -> VideoResult { }
}
```

**State Management:**
- `@State` → local UI state
- `@StateObject` → ViewModel owned by view
- `@ObservedObject` → ViewModel passed from parent
- `@Published` → triggers UI updates

---

## 📝 Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Views | PascalCase | `HomeView.swift` |
| ViewModels | PascalCase + "ViewModel" | `HomeViewModel.swift` |
| Services | PascalCase + "Service" | `VideoService.swift` |
| Variables | camelCase | `remainingCredits`, `isLoading` |
| Functions | camelCase | `generateVideo()`, `fetchUserCredits()` |
| File Names | Match primary type | `HomeView.swift` contains `struct HomeView` |

---

## 🔒 Safety & Code Style

- **No force unwraps** → use `guard let`, `if let`, `??`
- **120-char max line length**
- **4 spaces indentation** (no tabs)
- **Use `@MainActor`** for UI updates in ViewModels
- **Dependency injection** → pass services via init, not hardcode singletons

**Anti-patterns:**
- ❌ Business logic in View
- ❌ Force unwraps (`URL(string: "...")!`)
- ❌ Implicit optionals (`var url: URL!`)

---

## 📚 References

- Full details: `design/general-rulebook.md`
- Design system: `design/design-rulebook.md`
