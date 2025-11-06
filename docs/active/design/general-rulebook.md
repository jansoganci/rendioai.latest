⸻

# 🧱 Rendio AI – General Rulebook

**Version:** 1.0.0

**Platform:** iOS 17+ (SwiftUI)

**Architecture:** MVVM with Service Layer

**Last Updated:** 2025-11-05

---

## 1. Project Architecture

Rendio AI follows a **modular MVVM (Model-View-ViewModel)** architecture with clear separation of concerns.

### Architecture Layers

```
┌─────────────────────────────────────┐
│         View (SwiftUI)              │  ← User Interface
│  (HomeView, ProfileView, etc.)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       ViewModel (Business Logic)    │  ← State & Logic
│  (HomeViewModel, ProfileViewModel)  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Service Layer               │  ← API Integration
│  (VideoService, CreditService)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Models / API Layer          │  ← Data Structures
│  (VideoResult, UserCredits, etc.)   │
└─────────────────────────────────────┘
```

### Key Principles

- **Unidirectional Data Flow:** View → ViewModel → Service → API
- **Separation of Concerns:** Each layer has a single responsibility
- **Testability:** ViewModels and Services are easily mockable
- **Modularity:** Features are self-contained and independent

### Data Flow Example

```swift
// View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        Button("Generate Video") {
            viewModel.generateVideo(prompt: "A sunset over mountains")
        }
    }
}

// ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let videoService = VideoService.shared
    
    func generateVideo(prompt: String) {
        Task {
            isLoading = true
            do {
                let result = try await videoService.generateVideo(prompt: prompt)
                // Handle success
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// Service
class VideoService {
    static let shared = VideoService()
    
    func generateVideo(prompt: String) async throws -> VideoResult {
        // API call implementation
    }
}
```

---

## 2. Folder Structure Guidelines

### Recommended Structure

```
RendioAI/
├── Features/                          # Feature modules (self-contained)
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── ModelCard.swift
│   │       └── FeaturedCarousel.swift
│   ├── ModelDetail/
│   │   ├── ModelDetailView.swift
│   │   ├── ModelDetailViewModel.swift
│   │   └── Components/
│   │       └── PromptInputView.swift
│   ├── Result/
│   │   ├── ResultView.swift
│   │   ├── ResultViewModel.swift
│   │   └── Components/
│   │       └── VideoPlayerView.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift
│   │   └── Components/
│   │       └── HistoryCard.swift
│   └── Profile/
│       ├── ProfileView.swift
│       ├── ProfileViewModel.swift
│       └── Components/
│           ├── CreditBalanceCard.swift
│           └── SettingsRow.swift
│
├── Core/                              # Core functionality
│   ├── Networking/
│   │   ├── ApiService.swift
│   │   ├── VideoGenerationService.swift
│   │   ├── CreditService.swift
│   │   └── SupabaseClient.swift
│   ├── Models/
│   │   ├── VideoResult.swift
│   │   ├── UserCredits.swift
│   │   ├── VideoJob.swift
│   │   └── AppError.swift
│   ├── Utilities/
│   │   ├── Logger.swift
│   │   ├── DeviceCheckManager.swift
│   │   └── KeychainManager.swift
│   └── Constants/
│       └── ApiEndpoints.swift
│
├── Shared/                            # Reusable components
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── SecondaryButton.swift
│   │   ├── CardView.swift
│   │   ├── ToastView.swift
│   │   ├── LoadingView.swift
│   │   └── CreditBadge.swift
│   ├── Extensions/
│   │   ├── Color+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── String+Extensions.swift
│   └── ViewModifiers/
│       ├── CardStyle.swift
│       ├── ShadowModifier.swift
│       └── PrimaryButtonStyle.swift
│
└── Resources/                         # Assets & configurations
    ├── Assets.xcassets/
    ├── Localizations/
    │   ├── en.lproj/
    │   └── tr.lproj/
    └── Config/
        └── AppConfig.swift
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| **Views** | PascalCase | `HomeView.swift`, `ProfileView.swift` |
| **ViewModels** | PascalCase + "ViewModel" | `HomeViewModel.swift` |
| **Services** | PascalCase + "Service" | `VideoService.swift` |
| **Models** | PascalCase | `VideoResult.swift`, `UserCredits.swift` |
| **Components** | PascalCase | `PrimaryButton.swift`, `ModelCard.swift` |
| **Variables** | camelCase | `remainingCredits`, `isLoading` |
| **Functions** | camelCase | `generateVideo()`, `fetchUserCredits()` |
| **Constants** | camelCase (static) | `static let baseURL = "..."` |
| **File Names** | Must match primary type | `HomeView.swift` contains `struct HomeView` |

### Provider & Backend Naming Conventions

**External AI Providers** (FalAI, Runway, Pika) must use consistent naming across different contexts:

| Context | Convention | Example | Purpose |
|---------|------------|---------|----------|
| **UI/Documentation** | PascalCase with proper branding | `FalAI`, `Runway`, `Pika` | Display names in UI, docs, comments |
| **Database `provider` field** | lowercase | `fal`, `runway`, `pika` | Database enum values |
| **Model IDs** | kebab-case (provider format) | `fal-ai/veo3.1`, `runway-gen2` | External API identifiers |
| **Adapter Files** | snake_case + `_adapter.ts` | `fal_adapter.ts`, `runway_adapter.ts` | Backend adapter modules |
| **Swift Enum Cases** | camelCase | `.fal`, `.runway`, `.pika` | iOS provider enum |
| **TypeScript Enums** | SCREAMING_SNAKE_CASE | `Provider.FAL`, `Provider.RUNWAY` | Backend type-safe enums |

**Example Usage:**

```swift
// iOS Swift
enum VideoProvider: String, Codable {
    case fal = "fal"       // Matches database value
    case runway = "runway"
    case pika = "pika"

    var displayName: String {
        switch self {
        case .fal: return "FalAI"      // UI display
        case .runway: return "Runway"
        case .pika: return "Pika"
        }
    }
}
```

```typescript
// Backend TypeScript
const providerAdapters = {
    'fal': falAdapter,       // Database value → adapter mapping
    'runway': runwayAdapter,
    'pika': pikaAdapter
};

// Documentation comment
// Call FalAI API to generate video using fal-ai/veo3.1 model
```

**API Endpoint Naming:**

| Context | Convention | Example |
|---------|------------|---------|
| **Edge Function Names** | kebab-case | `device-check`, `generate-video`, `get-video-status` |
| **Function File Paths** | kebab-case | `supabase/functions/device-check/index.ts` |
| **API Calls (iOS)** | kebab-case without prefix | `APIClient.request(endpoint: "generate-video")` |
| **Documentation** | kebab-case without `/api` | `POST /generate-video` (NOT `/api/generate-video`) |

**Rationale:** Supabase Edge Functions use kebab-case directory names without `/api` prefix. Keeping consistent naming prevents integration confusion.

### Folder Rules

- **Each feature folder is self-contained** — contains View, ViewModel, and feature-specific components
- **No cross-imports between features** — use Shared/ for common code
- **Core/** contains business logic, networking, and utilities
- **Shared/** is for UI components and extensions used across features
- **Resources/** contains assets, localizations, and configuration

---

## 3. Coding Conventions

### Swift Style Guide

- **Line Length:** Maximum 120 characters
- **Indentation:** 4 spaces (no tabs)
- **Spacing:** Use trailing commas in multi-line arrays/dictionaries
- **Comments:** Minimal — code should be self-documenting

### Code Organization

```swift
// 1. Imports (alphabetically ordered)
import SwiftUI
import Foundation

// 2. Type Declaration
struct HomeView: View {
    // 3. Properties (published first, then private)
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSheet = false
    
    // 4. Body
    var body: some View {
        // Implementation
    }
    
    // 5. Private Methods
    private func handleAction() {
        // Implementation
    }
}

// 6. Extensions (in same file if closely related)
extension HomeView {
    private var headerView: some View {
        // Implementation
    }
}
```

### Safety Guidelines

- **No Force Unwraps:** Use `if let`, `guard let`, or `??` operator
- **Avoid Implicit Optionals:** Only use `!` when absolutely necessary
- **Safe Async:** Always handle errors in async functions
- **Thread Safety:** Use `@MainActor` for UI updates

### Anti-Patterns to Avoid

```swift
// ❌ DON'T: Force unwrap
let url = URL(string: apiURL)!

// ✅ DO: Safe unwrap
guard let url = URL(string: apiURL) else {
    throw AppError.invalidURL
}

// ❌ DON'T: Business logic in View
struct HomeView: View {
    var body: some View {
        Button("Generate") {
            // API call directly in View
            URLSession.shared.dataTask(...)
        }
    }
}

// ✅ DO: Logic in ViewModel
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        Button("Generate") {
            viewModel.generateVideo()
        }
    }
}
```

---

## 4. Components & Reusability

### Component Structure

All reusable UI components live in `/Shared/Components/` and follow these principles:

- **Stateless by default** — components receive data via parameters
- **Single responsibility** — each component has one clear purpose
- **Design token aware** — use semantic colors and typography from Design Rulebook

### Example: PrimaryButton

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color("BrandPrimary"))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.6)
    }
}
```

### ViewModifiers for Design Tokens

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage
VStack {
    Text("Content")
}
.cardStyle()
```

### Component Reuse Rules

- **Extract if used in ≥2 screens** — if a component appears in multiple features, move it to `/Shared/Components/`
- **Keep feature-specific components local** — if only used in one feature, keep it in that feature's `Components/` folder
- **Use ViewBuilders for flexible layouts** — allow customization via closures

---

## 5. Networking & Data Layer

### Service Layer Architecture

All network calls are centralized in `/Core/Networking/` and follow these patterns:

```swift
// ApiService.swift - Base networking layer
protocol ApiServiceProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> T
}

// VideoGenerationService.swift - Domain-specific service
class VideoGenerationService: ObservableObject {
    static let shared = VideoGenerationService()
    private let apiService: ApiServiceProtocol
    
    init(apiService: ApiServiceProtocol = ApiService.shared) {
        self.apiService = apiService
    }
    
    func generateVideo(
        prompt: String,
        modelId: String
    ) async throws -> VideoResult {
        let request = VideoGenerationRequest(
            prompt: prompt,
            modelId: modelId
        )
        
        return try await apiService.request(
            endpoint: ApiEndpoints.generateVideo,
            method: .POST,
            body: request
        )
    }
}
```

### Async/Await Pattern

Always use `async/await` for network calls:

```swift
// ✅ DO: Use async/await
func fetchUserCredits() async throws -> UserCredits {
    let url = URL(string: ApiEndpoints.userCredits)!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(UserCredits.self, from: data)
}

// ❌ DON'T: Use completion handlers
func fetchUserCredits(completion: @escaping (Result<UserCredits, Error>) -> Void) {
    // Old pattern - avoid
}
```

### Error Handling

Use unified error enum from `/Core/Models/AppError.swift`:

```swift
enum AppError: LocalizedError {
    case networkFailure
    case invalidResponse
    case insufficientCredits
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return LocalizedStringKey("error.networkFailure")
        case .insufficientCredits:
            return LocalizedStringKey("error.credit.insufficient")
        // ... other cases
        }
    }
}
```

### JSON Decoding

All API responses are decoded using Codable models in `/Core/Models/`:

```swift
struct VideoResult: Codable {
    let id: String
    let videoURL: URL
    let status: VideoStatus
    let createdAt: Date
    
    enum VideoStatus: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }
}

// Safe decoding with error handling
extension JSONDecoder {
    static func rendioDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

---

## 6. State Management

### State Types

- **`@State`** — Local UI state (e.g., `@State private var showingSheet = false`)
- **`@StateObject`** — ViewModel instances owned by the view
- **`@ObservedObject`** — ViewModel passed from parent
- **`@Published`** — Properties in ObservableObject that trigger UI updates

### ViewModel Pattern

```swift
@MainActor
class HomeViewModel: ObservableObject {
    // Published properties trigger UI updates
    @Published var models: [VideoModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dependencies injected via initializer
    private let videoService: VideoGenerationService
    private let creditService: CreditService
    
    init(
        videoService: VideoGenerationService = .shared,
        creditService: CreditService = .shared
    ) {
        self.videoService = videoService
        self.creditService = creditService
    }
    
    // Business logic methods
    func loadModels() {
        Task {
            isLoading = true
            do {
                models = try await videoService.fetchAvailableModels()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### Dependency Injection

Avoid global singletons when possible. Use dependency injection for testability:

```swift
// ✅ DO: Inject dependencies
class ProfileViewModel: ObservableObject {
    private let creditService: CreditService
    
    init(creditService: CreditService = .shared) {
        self.creditService = creditService
    }
}

// ❌ DON'T: Hard-code dependencies
class ProfileViewModel: ObservableObject {
    private let creditService = CreditService.shared // Hard to test
}
```

### Data Flow

```
User Action (View)
    ↓
ViewModel Method
    ↓
Service Call
    ↓
API Request
    ↓
API Response
    ↓
Service Parses Response
    ↓
ViewModel Updates @Published Property
    ↓
View Automatically Updates (SwiftUI)
```

---

## 7. Configuration & Environment

### AppConfig.swift

All configuration values are centralized in `/Resources/Config/AppConfig.swift`:

```swift
enum AppConfig {
    // API Configuration
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    
    // API Endpoints
    static let apiBaseURL = "\(supabaseURL)/functions/v1"
    
    // App Behavior
    static let defaultCredits = 10
    static let lowCreditThreshold = 10
    
    // Feature Flags
    #if DEBUG
    static let enableVerboseLogging = true
    #else
    static let enableVerboseLogging = false
    #endif
}
```

### Environment Variables

- **Never hardcode secrets** — use Info.plist or Keychain
- **Use build configurations** — Debug vs Release settings
- **Store sensitive data securely** — API keys in Keychain, not UserDefaults

### Secure Storage

```swift
// Keychain for sensitive data
class KeychainManager {
    static func store(key: String, value: String) {
        // Keychain storage implementation
    }
    
    static func retrieve(key: String) -> String? {
        // Keychain retrieval implementation
    }
}

// UserDefaults only for UI preferences
extension UserDefaults {
    static var hasSeenWelcomeBanner: Bool {
        get { standard.bool(forKey: "hasSeenWelcomeBanner") }
        set { standard.set(newValue, forKey: "hasSeenWelcomeBanner") }
    }
}
```

---

## 8. Error & Logging

### Unified Error System

Follow the error handling guide from `design/operations/error-handling-guide.md`:

```swift
// Centralized error mapping
struct ErrorMapper {
    static func map(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return LocalizedStringKey("error.general.unexpected")
    }
}

// ViewModel error handling
func handleError(_ error: Error) {
    let errorKey = ErrorMapper.map(error)
    errorMessage = LocalizedStringKey(errorKey)
    showingErrorAlert = true
}
```

### Logging

Use `Logger` (os_log) for non-sensitive information:

```swift
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let video = Logger(subsystem: subsystem, category: "video")
}

// Usage
Logger.networking.info("Fetching user credits")
Logger.video.error("Video generation failed: \(error.localizedDescription)")
```

### Logging Guidelines

- **Never log sensitive data** — no API keys, user tokens, or personal information
- **Use appropriate log levels** — `.info`, `.debug`, `.error`
- **Include context** — what operation failed and why
- **Respect privacy** — avoid logging user prompts or generated content URLs

---

## 9. Testing & Future Scalability

### Testing Structure

Each feature folder can have a `Tests/` subfolder:

```
Features/
├── Home/
│   ├── HomeView.swift
│   ├── HomeViewModel.swift
│   └── Tests/
│       └── HomeViewModelTests.swift
```

### Unit Testing Example

```swift
import XCTest
@testable import RendioAI

class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockVideoService: MockVideoService!
    
    override func setUp() {
        super.setUp()
        mockVideoService = MockVideoService()
        viewModel = HomeViewModel(videoService: mockVideoService)
    }
    
    func testLoadModels() async {
        // Given
        let expectedModels = [VideoModel(id: "1", name: "Test Model")]
        mockVideoService.modelsToReturn = expectedModels
        
        // When
        await viewModel.loadModels()
        
        // Then
        XCTAssertEqual(viewModel.models.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### Scalability Patterns

- **Adapter Pattern** — For adding new AI video providers (see `design/backend/api-adapter-interface.md`)
- **Feature Flags** — Use Supabase `app_features` table for gradual rollouts
- **Modular Architecture** — New features can be added without affecting existing code
- **Dependency Injection** — Services are easily mockable and swappable

### Future-Proofing

- **Protocol-oriented design** — Use protocols for services to enable easy swapping
- **Separate concerns** — Keep UI, business logic, and networking in separate layers
- **Documentation** — Maintain clear documentation for new developers

---

## 10. Summary Principles

| Category | Rule |
|----------|------|
| **Architecture** | MVVM, unidirectional data flow |
| **Reuse** | Components in `/Shared/`, ViewModifiers for design tokens |
| **Safety** | No force unwraps, safe async/await, proper error handling |
| **Modularity** | Each feature self-contained, no cross-imports |
| **Scalability** | New models/providers via adapter pattern |
| **Clean Code** | One responsibility per file, clear naming, minimal comments |
| **Testing** | Dependency injection enables easy mocking |
| **Configuration** | Centralized in AppConfig, no hardcoded secrets |
| **Logging** | Use Logger, never log sensitive data |

---

## 🧠 References

- [Apple Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [MVVM Pattern in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10022/)
- Design Rulebook (`design/design-rulebook.md`)
- Error Handling Guide (`design/operations/error-handling-guide.md`)

---

## 💡 End Note

Rendio AI's codebase should be **maintainable, testable, and scalable**.

Follow these guidelines to ensure consistency across the codebase and enable smooth collaboration between developers.

**"Write code as if the next developer is a violent psychopath who knows where you live."**

⸻
