# iOS Project Structure

## Overview

A well-organized project structure makes code easy to find, maintain, and scale. This guide shows the recommended folder organization for SwiftUI apps using MVVM.

---

## Recommended Structure

```
RendioAI/
├── App/
│   ├── RendioAIApp.swift              # App entry point
│   └── ContentView.swift              # Root view (tab navigation)
│
├── Features/                          # Feature modules
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── FeaturedModelCard.swift
│   │       └── ModelGridItem.swift
│   │
│   ├── ModelDetail/
│   │   ├── ModelDetailView.swift
│   │   ├── ModelDetailViewModel.swift
│   │   └── Components/
│   │       ├── PromptInputField.swift
│   │       └── VideoSettingsPanel.swift
│   │
│   ├── Result/
│   │   ├── ResultView.swift
│   │   ├── ResultViewModel.swift
│   │   └── Components/
│   │       └── VideoPlayerView.swift
│   │
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift
│   │   └── Components/
│   │       └── HistoryCard.swift
│   │
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── ProfileViewModel.swift
│   │   └── Components/
│   │       └── SettingsRow.swift
│   │
│   └── Splash/                        # Onboarding
│       ├── SplashView.swift
│       └── OnboardingViewModel.swift
│
├── Core/                              # Shared business logic
│   ├── Models/                        # Domain models
│   │   ├── User.swift
│   │   ├── VideoJob.swift
│   │   ├── VideoModel.swift
│   │   ├── Theme.swift
│   │   └── VideoSettings.swift
│   │
│   ├── Services/                      # Business services
│   │   ├── OnboardingService.swift
│   │   ├── DeviceCheckService.swift
│   │   ├── KeychainManager.swift
│   │   ├── UserDefaultsManager.swift
│   │   ├── LocalizationManager.swift
│   │   └── StoreKitManager.swift
│   │
│   ├── Networking/                    # API clients
│   │   ├── APIClient.swift            # Base HTTP client
│   │   ├── VideoGenerationService.swift
│   │   ├── ResultService.swift
│   │   ├── CreditService.swift
│   │   ├── HistoryService.swift
│   │   ├── ModelService.swift
│   │   ├── ThemeService.swift
│   │   └── UserService.swift
│   │
│   ├── Configuration/                 # App configuration
│   │   └── AppConfig.swift
│   │
│   └── Utilities/                     # Helper functions
│       ├── ErrorMapper.swift
│       ├── DateFormatter+Extensions.swift
│       └── String+Extensions.swift
│
├── Shared/                            # Reusable UI components
│   ├── Components/
│   │   ├── Buttons/
│   │   │   ├── PrimaryButton.swift
│   │   │   ├── SecondaryButton.swift
│   │   │   └── IconButton.swift
│   │   │
│   │   ├── Cards/
│   │   │   ├── BaseCard.swift
│   │   │   └── VideoCard.swift
│   │   │
│   │   ├── Inputs/
│   │   │   ├── SearchBar.swift
│   │   │   └── TextEditor+Placeholder.swift
│   │   │
│   │   └── States/
│   │       ├── LoadingView.swift
│   │       ├── ErrorView.swift
│   │       └── EmptyStateView.swift
│   │
│   ├── Modifiers/                     # View modifiers
│   │   ├── CardStyle.swift
│   │   └── ShimmerEffect.swift
│   │
│   ├── Extensions/                    # SwiftUI extensions
│   │   ├── Color+Theme.swift
│   │   ├── Font+Theme.swift
│   │   └── View+Extensions.swift
│   │
│   └── DesignSystem/                  # Design tokens
│       ├── AppColors.swift
│       ├── AppFonts.swift
│       ├── AppSpacing.swift
│       └── AppCornerRadius.swift
│
├── Resources/
│   ├── Assets.xcassets/               # Images, colors
│   ├── Localizable.strings            # Translations (en)
│   ├── tr.lproj/
│   │   └── Localizable.strings        # Turkish
│   └── es.lproj/
│       └── Localizable.strings        # Spanish
│
├── Configuration/
│   ├── Development.xcconfig           # Dev environment
│   └── Production.xcconfig            # Prod environment
│
├── Info.plist
└── RendioAI.entitlements
```

---

## Organization Principles

### 1. Feature-Based Organization

**Group by feature, not by type**

✅ **Good - Feature-based:**
```
/Features/Home/
├── HomeView.swift
├── HomeViewModel.swift
└── Components/
    └── FeaturedModelCard.swift
```

❌ **Bad - Type-based:**
```
/Views/
├── HomeView.swift
├── ModelDetailView.swift
└── ResultView.swift

/ViewModels/
├── HomeViewModel.swift
├── ModelDetailViewModel.swift
└── ResultViewModel.swift
```

**Why?** Feature-based organization keeps related code together, making it easier to:
- Find all code for a feature
- Delete a feature (just remove the folder)
- Work on features in isolation

---

### 2. Core vs. Features

| Folder | Purpose | When to Use |
|--------|---------|-------------|
| **Features/** | Screen-specific code | Views, ViewModels unique to one screen |
| **Core/** | Shared business logic | Models, Services used across features |
| **Shared/** | Reusable UI | Components used in multiple screens |

**Example:**

```swift
// ✅ Core - Used by multiple features
class CreditService {
    func getCredits() async throws -> Int
}

// ✅ Features - Specific to Profile screen
class ProfileViewModel: ObservableObject {
    private let creditService: CreditService
}

// ✅ Shared - Used in multiple views
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
}
```

---

### 3. Models Location

**Where to put models?**

```swift
// ✅ Core/Models - Used by multiple features
struct User: Codable {
    let id: String
    let email: String?
}

struct VideoJob: Codable {
    let id: String
    let prompt: String
}

// ✅ Feature-specific Models - Used only in one feature
// Features/ModelDetail/Models/VideoSettings.swift
struct VideoSettings {
    var duration: Duration
    var resolution: Resolution
}
```

**Rule:** If 2+ features use it → `Core/Models/`. If only 1 feature uses it → `Features/FeatureName/Models/`

---

## File Naming Conventions

### Views
```swift
// Main screen views
HomeView.swift
ModelDetailView.swift
ResultView.swift

// Component views
FeaturedModelCard.swift
PrimaryButton.swift
EmptyStateView.swift
```

### ViewModels
```swift
HomeViewModel.swift
ModelDetailViewModel.swift
ResultViewModel.swift

// Always end with "ViewModel"
```

### Services
```swift
// Protocol
protocol VideoGenerationServiceProtocol { }

// Implementation
class VideoGenerationService: VideoGenerationServiceProtocol { }

// Mock for testing
class MockVideoGenerationService: VideoGenerationServiceProtocol { }

// Always end with "Service"
```

### Models
```swift
User.swift
VideoJob.swift
VideoModel.swift

// Descriptive nouns, no suffix needed
```

---

## Example: Adding a New Feature

Let's add a "Video Editor" feature:

### Step 1: Create folder structure
```
/Features/VideoEditor/
├── VideoEditorView.swift
├── VideoEditorViewModel.swift
├── Components/
│   ├── TimelineView.swift
│   └── EffectsPicker.swift
└── Models/
    └── EditingState.swift
```

### Step 2: Create View

```swift
// Features/VideoEditor/VideoEditorView.swift
import SwiftUI

struct VideoEditorView: View {
    @StateObject private var viewModel: VideoEditorViewModel

    init(videoUrl: URL) {
        _viewModel = StateObject(wrappedValue: VideoEditorViewModel(videoUrl: videoUrl))
    }

    var body: some View {
        VStack {
            // UI here
        }
    }
}
```

### Step 3: Create ViewModel

```swift
// Features/VideoEditor/VideoEditorViewModel.swift
import Foundation

@MainActor
class VideoEditorViewModel: ObservableObject {
    @Published private(set) var state: LoadingState<EditingState> = .loading

    private let videoUrl: URL

    init(videoUrl: URL) {
        self.videoUrl = videoUrl
    }

    func loadVideo() {
        // Implementation
    }
}
```

### Step 4: Create Models (if needed)

```swift
// Features/VideoEditor/Models/EditingState.swift
struct EditingState {
    var currentFrame: Int
    var duration: Double
    var selectedEffect: Effect?
}
```

---

## Services Organization

### Protocol-First Design

Every service should have:
1. Protocol (interface)
2. Production implementation
3. Mock implementation (for testing)

```swift
// MARK: - Protocol
protocol CreditServiceProtocol {
    func getCredits() async throws -> Int
    func deductCredits(amount: Int) async throws -> Int
}

// MARK: - Production Implementation
class CreditService: CreditServiceProtocol {
    func getCredits() async throws -> Int {
        // Real API call
    }

    func deductCredits(amount: Int) async throws -> Int {
        // Real API call
    }
}

// MARK: - Mock Implementation
class MockCreditService: CreditServiceProtocol {
    var mockCredits: Int = 10

    func getCredits() async throws -> Int {
        return mockCredits
    }

    func deductCredits(amount: Int) async throws -> Int {
        mockCredits -= amount
        return mockCredits
    }
}
```

---

## Design System Organization

Centralize design tokens for consistency:

```swift
// Shared/DesignSystem/AppColors.swift
import SwiftUI

extension Color {
    // Brand
    static let brandPrimary = Color("BrandPrimary")
    static let accent = Color("Accent")

    // Surface
    static let surfaceBase = Color("SurfaceBase")
    static let surfaceCard = Color("SurfaceCard")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
}

// Shared/DesignSystem/AppSpacing.swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// Shared/DesignSystem/AppCornerRadius.swift
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}
```

**Usage:**
```swift
VStack(spacing: Spacing.md) {
    Text("Title")
        .foregroundColor(.textPrimary)

    Text("Subtitle")
        .foregroundColor(.textSecondary)
}
.padding(Spacing.lg)
.background(Color.surfaceCard)
.cornerRadius(CornerRadius.md)
```

---

## Configuration Files

### Environment-Specific Configs

```
/Configuration/
├── Development.xcconfig
└── Production.xcconfig
```

**Development.xcconfig:**
```
SUPABASE_URL = https://dev.supabase.co
SUPABASE_ANON_KEY = dev_key_here
ENVIRONMENT_NAME = Development
ENABLE_LOGGING = YES
```

**Production.xcconfig:**
```
SUPABASE_URL = https://prod.supabase.co
SUPABASE_ANON_KEY = prod_key_here
ENVIRONMENT_NAME = Production
ENABLE_LOGGING = NO
```

**Access in code:**
```swift
// Core/Configuration/AppConfig.swift
struct AppConfig {
    static let supabaseURL = Bundle.main.object(
        forInfoDictionaryKey: "SUPABASE_URL"
    ) as! String

    static let environment = Bundle.main.object(
        forInfoDictionaryKey: "ENVIRONMENT_NAME"
    ) as! String
}
```

---

## Localization Files

```
/Resources/
├── en.lproj/
│   └── Localizable.strings
├── tr.lproj/
│   └── Localizable.strings
└── es.lproj/
    └── Localizable.strings
```

**en.lproj/Localizable.strings:**
```
"home_title" = "Video Models";
"generate_button" = "Generate Video";
"error_network" = "Network connection failed";
```

**Usage:**
```swift
Text(NSLocalizedString("home_title", comment: ""))

// Or with custom helper:
Text(L10n.homeTitle)
```

---

## Testing Structure

```
RendioAITests/
├── Features/
│   ├── HomeViewModelTests.swift
│   ├── ModelDetailViewModelTests.swift
│   └── ResultViewModelTests.swift
│
├── Services/
│   ├── CreditServiceTests.swift
│   ├── VideoGenerationServiceTests.swift
│   └── OnboardingServiceTests.swift
│
└── Mocks/
    ├── MockCreditService.swift
    ├── MockVideoGenerationService.swift
    └── MockResultService.swift
```

**Mirror your main structure in tests**

---

## Best Practices

### ✅ Do This

1. **Keep features independent**
   - Features should not import other features
   - Share code via Core/Services

2. **Use descriptive names**
   ```swift
   // ✅ Good
   VideoGenerationService.swift
   FeaturedModelCard.swift

   // ❌ Bad
   VGS.swift
   Card.swift
   ```

3. **Group related files**
   ```
   /Features/Home/
   ├── HomeView.swift
   ├── HomeViewModel.swift
   └── Components/
   ```

4. **Extract reusable components**
   - If used in 2+ places → move to Shared/

### ❌ Don't Do This

1. **Don't create deep nesting**
   ```
   // ❌ Too deep
   /Features/Home/Views/Main/Components/Cards/Featured/
   ```

2. **Don't mix feature code with shared code**
   ```
   // ❌ Bad
   /Shared/Components/HomeSpecificCard.swift

   // ✅ Good
   /Features/Home/Components/HomeSpecificCard.swift
   ```

3. **Don't put everything in Core**
   - Core is for truly shared code
   - Feature-specific code stays in Features/

---

## Migration Guide

### If your project is type-based:

**Before:**
```
/Views/
  HomeView.swift
  ModelDetailView.swift
/ViewModels/
  HomeViewModel.swift
  ModelDetailViewModel.swift
```

**After:**
```
/Features/
  Home/
    HomeView.swift
    HomeViewModel.swift
  ModelDetail/
    ModelDetailView.swift
    ModelDetailViewModel.swift
```

**Steps:**
1. Create `/Features` folder
2. Create subfolders for each screen
3. Move View + ViewModel together
4. Update imports
5. Delete old folders

---

## Summary

| Principle | Implementation |
|-----------|----------------|
| **Feature-based** | Group by screen/feature, not by type |
| **Core vs. Features** | Core = shared, Features = specific |
| **Protocol-first** | Every service has protocol + implementation + mock |
| **Design system** | Centralize colors, fonts, spacing |
| **Testability** | Mirror structure in tests folder |

**Next:** [Service Layer →](03-Service-Layer.md)
