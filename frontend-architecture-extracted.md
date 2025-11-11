# Frontend Architecture Documentation

This document describes the frontend architecture of the iOS mobile application. It covers the entire structure, patterns, and design decisions used in building the user interface and client-side logic.

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Component Architecture](#component-architecture)
5. [Navigation System](#navigation-system)
6. [State Management](#state-management)
7. [API Integration](#api-integration)
8. [Styling & Design System](#styling--design-system)
9. [Local Storage](#local-storage)
10. [Error Handling](#error-handling)
11. [App Initialization](#app-initialization)
12. [Key Architectural Patterns](#key-architectural-patterns)

---

## Overview

This is a native iOS application built using modern Apple technologies. The app allows users to generate videos using AI, browse generation themes, view their generation history, and manage their account settings.

### Platform Details
- **Platform**: iOS (Native Apple)
- **Language**: Swift 5.9+
- **Minimum iOS Version**: 17.0+
- **IDE**: Xcode 15.0+
- **Total Swift Files**: 74 files

---

## Technology Stack

### Core Technologies
- **UI Framework**: SwiftUI (Apple's native declarative UI framework)
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Backend**: Supabase (authentication, database, storage, serverless functions)
- **AI Service**: Fal AI for video generation
- **Payments**: StoreKit 2 (Apple's in-app purchase system)
- **Device Security**: DeviceCheck API
- **Authentication**: Apple Sign-In
- **Networking**: URLSession (native HTTP client)
- **Local Storage**: UserDefaults
- **Localization**: NSLocalizedString with custom manager

### No External UI Libraries
The app uses only native Apple components - no third-party UI frameworks. This keeps the app size small and ensures App Store compliance.

---

## Project Structure

### High-Level Folder Organization

```
/RendioAI/
├── App/                    # App entry point and main navigation
├── Core/                   # Business logic, models, services
├── Features/               # Feature screens (Home, Profile, etc.)
├── Shared/                 # Reusable components and utilities
├── Configuration/          # Environment configuration
├── Resources/              # Localizations, assets
└── Assets.xcassets/        # Images, colors, icons
```

### Core Directory (Business Logic Layer)

The `Core/` folder contains all the non-UI business logic:

```
/Core/
├── Configuration/
│   └── AppConfig.swift                    # Centralized app settings
├── Models/ (15 files)
│   ├── User.swift                         # User profile model
│   ├── Theme.swift                        # Video generation themes
│   ├── ModelDetail.swift                  # AI model specifications
│   ├── VideoJob.swift                     # Generation job status
│   ├── VideoGenerationRequest.swift       # Request payload
│   ├── VideoSettings.swift                # Video parameters
│   ├── AppError.swift                     # Error handling
│   └── ...other models
├── Networking/ (9 services)
│   ├── AuthService.swift                  # Authentication
│   ├── VideoGenerationService.swift       # Start video generation
│   ├── ResultService.swift                # Poll job status
│   ├── ThemeService.swift                 # Fetch available themes
│   ├── ModelService.swift                 # Get model details
│   ├── CreditService.swift                # Manage user credits
│   ├── HistoryService.swift               # Fetch generation history
│   ├── UserService.swift                  # User profile management
│   └── ImageUploadService.swift           # Upload images
└── Services/
    ├── OnboardingService.swift            # Device onboarding
    ├── OnboardingStateManager.swift       # Onboarding persistence
    ├── UserDefaultsManager.swift          # Local storage wrapper
    ├── LocalizationManager.swift          # Language management
    ├── StoreKitManager.swift              # In-app purchases
    └── DeviceCheckService.swift           # Device verification
```

### Features Directory (Screens)

Each feature has its own folder with a main view, view model, and sub-components:

```
/Features/
├── Home/
│   ├── HomeView.swift
│   ├── HomeViewModel.swift
│   └── Components/
│       ├── FeaturedModelCard.swift        # Carousel cards
│       ├── ModelGridCard.swift            # Grid theme cards
│       ├── WelcomeBanner.swift            # New user welcome
│       └── LowCreditBanner.swift          # Credit warnings
├── ModelDetail/
│   ├── ModelDetailView.swift
│   ├── ModelDetailViewModel.swift
│   └── Components/
│       ├── PromptInputField.swift         # Text input
│       ├── ImagePickerView.swift          # Image selection
│       ├── SettingsPanel.swift            # Generation settings
│       └── CreditInfoBar.swift            # Cost display
├── Result/
│   ├── ResultView.swift
│   ├── ResultViewModel.swift
│   └── Components/
│       ├── VideoPlayerView.swift          # Video player wrapper
│       ├── ShareSheet.swift               # Share functionality
│       └── ActionButtonsRow.swift         # Download/Share buttons
├── History/
│   ├── HistoryView.swift
│   ├── HistoryViewModel.swift
│   └── Components/
│       ├── HistoryCard.swift              # History item
│       ├── SearchBar.swift                # Search input
│       └── HistoryEmptyState.swift        # Empty state view
├── Profile/
│   ├── ProfileView.swift
│   ├── ProfileViewModel.swift
│   └── Components/
│       ├── ProfileHeader.swift            # User info header
│       ├── CreditInfoSection.swift        # Credit display
│       ├── AccountSection.swift           # Auth section
│       ├── SettingsSection.swift          # Theme/language
│       └── PurchaseSheet.swift            # Buy credits modal
└── Splash/
    └── SplashView.swift                   # Launch screen
```

### Shared Components

Reusable components used across multiple features:

```
/Shared/
├── Components/
│   └── PrimaryButton.swift                # Standard action button
└── Extensions/
    └── UIApplication+Extensions.swift     # Utility extensions
```

---

## Component Architecture

### Naming Conventions

The project follows consistent naming patterns:

- **Views**: `<Feature>View.swift` (e.g., `HomeView.swift`)
- **ViewModels**: `<Feature>ViewModel.swift` (e.g., `HomeViewModel.swift`)
- **Services**: `<Domain>Service.swift` (e.g., `AuthService.swift`)
- **Models**: `<Domain>.swift` (e.g., `User.swift`)
- **Sub-components**: `<Purpose><Type>.swift` (e.g., `WelcomeBanner.swift`)

### Component Organization Levels

**1. Screen Components (Feature-level)**
- Located in `/Features/<Feature>/`
- Always paired with a ViewModel
- Handle a complete screen's functionality
- Example: `HomeView` + `HomeViewModel`

**2. Sub-components (Feature-specific)**
- Located in `/Features/<Feature>/Components/`
- Used within a specific feature
- Accept data and callbacks as parameters
- Example: `FeaturedModelCard`, `PromptInputField`

**3. Shared Components (App-wide)**
- Located in `/Shared/Components/`
- Used across multiple features
- Highly reusable and generic
- Example: `PrimaryButton`

### Component Breakdown by Feature

#### Home Screen
The home screen shows available video generation themes:

- **FeaturedModelCard**: Displays featured themes in a carousel
- **ModelGridCard**: Shows themes in a grid layout
- **WelcomeBanner**: Welcome message for new users
- **LowCreditBanner**: Warning when credits are low
- **EmptyStateView**: Shown when no themes are available

#### ModelDetail Screen
The generation configuration screen:

- **PromptInputField**: Text input for video description
- **ImagePickerView**: Select image for image-to-video
- **SettingsPanel**: Choose video settings (resolution, duration, etc.)
- **CreditInfoBar**: Shows generation cost

#### Result Screen
Shows the generated video:

- **VideoPlayerView**: Wrapper around Apple's AVPlayer
- **ActionButtonsRow**: Download and share buttons
- **ResultInfoCard**: Displays job metadata

#### History Screen
Lists previously generated videos:

- **HistoryCard**: Individual history item card
- **HistorySection**: Groups items by date
- **SearchBar**: Filter/search functionality
- **HistoryEmptyState**: No generations yet message

#### Profile Screen
User account and settings:

- **ProfileHeader**: User name and avatar
- **CreditInfoSection**: Credit balance display
- **AccountSection**: Sign-in/authentication UI
- **SettingsSection**: Language and theme preferences
- **PurchaseSheet**: In-app purchase modal

---

## Navigation System

### Navigation Architecture

The app uses a **tab-based navigation** structure with three main tabs. Each tab has its own navigation stack.

### Navigation Flow

```
App Launch
└── SplashView (shows for 2+ seconds)
    └── Performs device onboarding
        └── ContentView (Main App)
            └── TabView (3 tabs)
                ├── Tab 1: Home
                │   └── NavigationStack
                │       ├── HomeView
                │       └── ModelDetailView (push)
                │           └── ResultView (modal)
                ├── Tab 2: History
                │   └── NavigationStack
                │       ├── HistoryView
                │       └── ResultView (push)
                └── Tab 3: Profile
                    └── NavigationStack
                        └── ProfileView
```

### Navigation Implementation

The main navigation is defined in `ContentView.swift`:

```swift
TabView(selection: $selectedTab) {
    // Home Tab
    NavigationStack {
        HomeView()
    }
    .tabItem { Label("Home", systemImage: "house.fill") }

    // History Tab
    NavigationStack {
        HistoryView()
    }
    .tabItem { Label("History", systemImage: "clock.fill") }

    // Profile Tab
    NavigationStack {
        ProfileView()
    }
    .tabItem { Label("Profile", systemImage: "person.fill") }
}
```

### Navigation Patterns Used

1. **TabView**: Primary navigation between main sections
2. **NavigationStack**: Per-tab internal navigation (iOS 16+)
3. **NavigationLink**: Push navigation (Home → ModelDetail)
4. **Sheet/Modal**: Present temporary screens (purchase flow, auth)
5. **fullScreenCover**: Full-screen transitions (splash → main app)

### Key Navigation Paths

- **Home → Generation**: Tap theme card → navigate to ModelDetailView
- **Generation → Result**: After starting generation → present ResultView
- **History → Result**: Tap history item → navigate to ResultView
- **Profile → Purchase**: Tap "Buy Credits" → present PurchaseSheet modal
- **Profile → Sign In**: Tap "Sign In" → present sign-in modal

---

## State Management

### State Management Philosophy

The app uses **MVVM pattern** with native SwiftUI state management. There are no external state management libraries like Redux or MobX.

### State Management Layers

#### 1. Global State (App-Wide)

**ThemeObserver** - Manages app color scheme (light/dark/system)
```swift
class ThemeObserver: ObservableObject {
    @Published var colorScheme: ColorScheme?
}
```
Used throughout the app as `@EnvironmentObject`

**LocalizationManager** - Manages app language
```swift
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String
}
```
Updates all views when language changes

**UserDefaultsManager** - Persistent local storage
```swift
class UserDefaultsManager {
    var language: String { get/set }
    var themePreference: String { get/set }
    var deviceId: String? { get/set }
    var onboardingCompleted: Bool { get/set }
    var currentUserId: String? { get/set }
}
```
Singleton accessed throughout the app

#### 2. Feature State (ViewModels)

Each screen has its own ViewModel with `@Published` properties that trigger UI updates:

**HomeViewModel Example:**
```swift
class HomeViewModel: ObservableObject {
    @Published var creditsRemaining: Int = 0
    @Published var searchQuery: String = ""
    @Published var featuredThemes: [Theme] = []
    @Published var allThemes: [Theme] = []
    @Published var isLoading: Bool = false

    func loadData() async {
        // Fetches data and updates @Published properties
    }
}
```

**ModelDetailViewModel Example:**
```swift
class ModelDetailViewModel: ObservableObject {
    @Published var theme: Theme?
    @Published var prompt: String = ""
    @Published var settings: VideoSettings = .default
    @Published var selectedImage: UIImage?
    @Published var isGenerating: Bool = false
    @Published var creditsRemaining: Int = 0

    var canGenerate: Bool {
        // Computed property based on published state
        !prompt.isEmpty && creditsRemaining >= cost
    }

    func generateVideo() async {
        // Performs generation and updates state
    }
}
```

#### 3. Local Component State

For simple UI state (toggles, text input, etc.), components use `@State`:

```swift
struct SomeView: View {
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var showingModal = false
}
```

### State Flow Pattern

How state flows through the app:

```
User Action
    ↓
View calls ViewModel method
    ↓
ViewModel updates @Published property
    ↓
SwiftUI automatically re-renders View
```

Example flow:
1. User taps "Generate Video" button
2. View calls `viewModel.generateVideo()`
3. ViewModel sets `isGenerating = true`
4. UI shows loading spinner automatically
5. API call completes
6. ViewModel sets `isGenerating = false`
7. UI hides loading spinner automatically

### State Persistence

States are persisted using:

- **UserDefaults**: Simple key-value data (language, theme, device ID)
- **Supabase Database**: User profile, credits, video history
- **OnboardingStateManager**: Tracks onboarding completion

### Property Wrapper Types

- **@State**: Local component state
- **@StateObject**: ViewModel lifecycle management
- **@EnvironmentObject**: Injected global state
- **@Published**: Inside ObservableObject for reactive properties
- **@Binding**: Two-way data binding between parent/child

---

## API Integration

### API Architecture

The app communicates with a backend built on Supabase serverless functions.

**Base URL**: `https://ojcnjxzctnwbmupggoxq.supabase.co`

**API Type**: REST JSON API (Supabase Edge Functions)

**Authentication**: Bearer token + API key in headers

### Service Layer Design

The app uses a **service-based architecture** where each domain has its own service class. Services use native `URLSession` for HTTP calls.

### Networking Services

The app has 9 networking services:

#### 1. AuthService
Handles user authentication:
- Apple Sign-In integration
- Guest to authenticated user migration
- Sign out functionality
- Current auth state management

#### 2. VideoGenerationService
Starts video generation:
- **Endpoint**: `POST /functions/v1/generate-video`
- **Purpose**: Submit video generation request
- **Payload**: User ID, theme, prompt, image URL, settings
- **Returns**: Job ID for tracking

#### 3. ResultService
Polls video generation status:
- **Endpoints**: Multiple for job management
- **Methods**: Get job status, list jobs, check completion
- **Purpose**: Track generation progress and get video URL
- **Polling**: Implemented in ResultViewModel

#### 4. ThemeService
Fetches available themes:
- **Endpoint**: `GET /functions/v1/get-models`
- **Purpose**: Get list of video generation themes
- **Caching**: ETag-based HTTP caching

#### 5. ModelService
Gets model specifications:
- **Endpoint**: `GET /functions/v1/get-models`
- **Purpose**: Detailed model configuration
- **Caching**: Returns cached data on 304 Not Modified

#### 6. CreditService
Manages user credits:
- **Endpoints**: Get credits, update credits
- **Purpose**: Fetch balance and perform credit transactions
- **Atomic**: Uses backend stored procedures

#### 7. HistoryService
Gets generation history:
- **Endpoint**: `GET /functions/v1/get-video-jobs`
- **Purpose**: List user's previous generations
- **Filtering**: By user ID, last 7 days

#### 8. UserService
Manages user profile:
- **Endpoint**: `GET /functions/v1/get-user-profile`
- **Purpose**: Get user data (tier, credits, settings)

#### 9. ImageUploadService
Uploads images:
- **Purpose**: Upload reference images for image-to-video
- **Storage**: Supabase Storage bucket
- **Security**: Row-Level Security policies

### Request/Response Pattern

**Standard Request Headers:**
```
Authorization: Bearer <ANON_KEY>
apikey: <ANON_KEY>
Content-Type: application/json
```

**Error Handling:**
All services throw typed errors that get caught in ViewModels:

```swift
do {
    let result = try await service.fetch()
    // Update UI state
} catch let error as AppError {
    // Show user-friendly error message
    errorMessage = error.localizedDescription
    showingAlert = true
}
```

### API Response Decoding

Responses are decoded using Swift's `Codable` protocol:

```swift
struct VideoGenerationResponse: Codable {
    let job_id: String
    let status: String
    let estimated_time: Int?
}
```

The app handles:
- ISO8601 date formats
- Snake_case to camelCase conversion
- Optional fields
- Nested objects

### Configuration Management

All API settings are in `AppConfig.swift`:

```swift
struct AppConfig {
    static var supabaseURL: String        // From Info.plist
    static var supabaseAnonKey: String    // From Info.plist
    static var apiTimeout: TimeInterval   // Environment-specific
    static var maxRetryAttempts: Int
}
```

**Environment-Specific Timeouts:**
- Development: 30 seconds
- Staging: 20 seconds
- Production: 15 seconds

### Caching Strategy

**ETag HTTP Caching** - Used in ModelService:

```swift
// First request stores ETag
cachedETag = response.allHeaderFields["ETag"]

// Subsequent requests send If-None-Match
request.setValue(cachedETag, forHTTPHeaderField: "If-None-Match")

// Server returns 304 if unchanged
if response.statusCode == 304 {
    return cachedModels  // Use cached data
}
```

This reduces bandwidth and improves performance.

### Protocol-Based Design

All services implement protocols for testability:

```swift
protocol VideoGenerationServiceProtocol {
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

class VideoGenerationService: VideoGenerationServiceProtocol {
    // Implementation
}

class MockVideoGenerationService: VideoGenerationServiceProtocol {
    // Mock implementation for testing
}
```

---

## Styling & Design System

### Design Philosophy

The app uses **native SwiftUI styling** with no external CSS or styling libraries. All styles are defined using SwiftUI modifiers and Apple's Asset Catalog for design tokens.

### Color System

Colors are defined in `Assets.xcassets/` as color sets:

- **BrandPrimary**: Main action color
- **SurfaceBase**: Background color
- **TextPrimary**: Main text color
- **TextSecondary**: Secondary text color
- **BorderColor**: Dividers and borders

Colors support both light and dark mode automatically.

### Theme System

Users can choose between three themes:

- **Light Mode**: Light colors
- **Dark Mode**: Dark colors
- **System**: Follows device settings (default)

Theme preference is stored in UserDefaults and applied app-wide:

```swift
// User selects theme in Profile screen
UserDefaultsManager.shared.themePreference = "dark"

// ThemeObserver updates
themeObserver.colorScheme = .dark

// All views refresh automatically
```

### Typography

The app uses native San Francisco font with consistent sizing:

- **Large Title**: 28-42pt (splash screen)
- **Title**: 20pt
- **Headline**: 18pt
- **Body**: 16pt
- **Caption**: 12-14pt

Font weights used:
- Regular
- Medium
- Semibold
- Bold

Example:
```swift
Text("Title")
    .font(.system(size: 20, weight: .semibold, design: .rounded))
```

### Spacing System

Consistent spacing values used throughout:

- **Padding**: 8, 12, 16, 24, 32
- **Spacing**: 8, 16, 24
- **Corner Radius**: 8, 12

### Reusable Component: PrimaryButton

The app has a standardized button component:

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color("BrandPrimary") : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
    }
}
```

Used throughout the app for consistency:
```swift
PrimaryButton(
    title: "Generate Video",
    action: { viewModel.generateVideo() },
    isEnabled: viewModel.canGenerate,
    isLoading: viewModel.isGenerating
)
```

### Styling Patterns

**Pattern 1: Inline Modifiers**
```swift
Text("Hello")
    .font(.system(size: 18, weight: .semibold))
    .foregroundColor(.white)
    .padding(.vertical, 16)
    .background(Color("BrandPrimary"))
    .cornerRadius(12)
```

**Pattern 2: Custom ViewModifiers**
```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color("SurfaceBase"))
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

// Usage:
someView.modifier(CardStyle())
```

### Animations

The app uses SwiftUI's built-in animations:

**Spring animations** (for smooth, natural motion):
```swift
withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
    scale = 1.0
    opacity = 1.0
}
```

**Transitions**:
```swift
.transition(.opacity)
.transition(.scale)
```

### Accessibility

The app supports:
- Dynamic Type (text size adjustments)
- VoiceOver labels
- High contrast mode (via color assets)

Example:
```swift
Text("home.title".localized)
    .accessibilityLabel("home.accessibility.title".localized)
```

### Localization

UI strings are localized using:
```swift
"home.title".localized  // Uses LocalizationManager
```

Supported languages:
- English (default)
- Spanish
- Turkish

---

## Local Storage

### Client-Side Storage

The app uses **UserDefaults** for local persistence - a simple key-value storage system provided by iOS.

### Stored Data

**UserDefaultsManager** manages all local storage:

```swift
class UserDefaultsManager {
    // Language & Theme Preferences
    var language: String                    // "en", "es", "tr"
    var themePreference: String             // "light", "dark", "system"

    // Onboarding State
    var hasLaunchedBefore: Bool             // First launch flag
    var deviceId: String?                   // Device identifier
    var onboardingCompleted: Bool           // Onboarding done
    var hasSeenWelcomeBanner: Bool          // Welcome shown

    // User Identification
    var currentUserId: String?              // Current user ID
    var lastSyncedUserId: String?           // Last synced user
}
```

### Remote Storage

**Supabase Database Tables:**
- `users`: User profiles and authentication
- `video_jobs`: Video generation history and status
- `quota_log`: Credit transaction history
- `themes`: Available video themes
- `models`: AI model specifications

**Supabase Storage Buckets:**
- `videos`: Generated video files
- `thumbnails`: Video thumbnail images
- `user_uploads`: User-provided images

### Data Sync Pattern

**Device Onboarding Flow:**
1. App launches for first time
2. Gets device ID from iOS
3. Sends to backend for device verification
4. Backend creates or finds user account
5. Stores device ID and user ID locally
6. All future requests include user ID

**User Data Sync:**
```swift
// When user profile loads
let user = try await userService.getUser()

// Sync preferences to local storage
UserDefaultsManager.shared.syncFromUser(user)

// Update UI
self.user = user
```

### Persistence Lifecycle

**Language Preference Example:**
1. User selects language in Profile screen
2. Saved to UserDefaults immediately
3. LocalizationManager notified via NotificationCenter
4. All views refresh automatically
5. Persists across app launches

**Onboarding State Example:**
1. First launch: `onboardingCompleted = false`
2. Device check performed
3. State saved: `onboardingCompleted = true`
4. Next launch: Onboarding skipped

### Cache Management

**HTTP ETag Caching:**
ModelService caches theme/model data in memory and uses HTTP ETags to avoid redundant downloads.

**Data Retention:**
- Video history: 7 days (backend enforced)
- User preferences: Indefinite (until app deleted)
- Device ID: Indefinite (until app deleted)

---

## Error Handling

### Unified Error Model

All errors are represented by a single enum type:

```swift
enum AppError: LocalizedError {
    case networkFailure
    case networkTimeout
    case invalidResponse
    case insufficientCredits
    case unauthorized
    case invalidDevice
    case userNotFound
    case networkError(String)
    case unknown(String)

    var errorDescription: String? {
        // Returns localized error message
        // e.g., "error.network.failure".localized
    }
}
```

### Error Handling in ViewModels

All ViewModels follow the same pattern:

```swift
func performAction() {
    Task {
        isLoading = true
        do {
            let result = try await service.performAction()
            // Update UI state
            self.result = result
        } catch let error as AppError {
            // Show user-friendly error
            errorMessage = error.errorDescription
            showingErrorAlert = true
        } catch {
            // Unknown error fallback
            errorMessage = "An unexpected error occurred"
            showingErrorAlert = true
        }
        isLoading = false
    }
}
```

### Error Handling in Services

Services throw specific errors that ViewModels can handle:

```swift
func fetchData() async throws -> Data {
    // Validate URL
    guard let url = URL(...) else {
        throw AppError.invalidResponse
    }

    // Make request
    let (data, response) = try await URLSession.shared.data(from: url)

    // Check status code
    guard let httpResponse = response as? HTTPURLResponse else {
        throw AppError.networkFailure
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        // Parse error message from backend
        if let errorMessage = extractError(data) {
            throw AppError.networkError(errorMessage)
        }
        throw AppError.networkFailure
    }

    return data
}
```

### User-Facing Error Display

Errors are shown to users via alerts:

```swift
struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        content
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
    }
}
```

### Onboarding Fallback Strategy

If device verification fails, the app uses a graceful fallback:

```swift
// Primary: Use DeviceCheck for device verification
// Fallback: Generate UUID if DeviceCheck unavailable

func performOnboarding() async {
    do {
        // Try device check
        let response = try await deviceCheckService.verify()
        return .success(response)
    } catch {
        // Fall back to guest mode with UUID
        let guestId = UUID().uuidString
        return .fallback(deviceId: guestId)
    }
}
```

This ensures the app always works, even if the backend is unreachable.

### Error Categories

**Network Errors:**
- Connection timeout
- No internet connection
- Server unavailable
- Invalid response

**Business Logic Errors:**
- Insufficient credits
- Invalid prompt
- Image upload failed
- Generation failed

**Auth Errors:**
- Unauthorized
- User not found
- Sign-in failed

**Device Errors:**
- DeviceCheck unavailable
- Invalid device

Each error shows a user-friendly message in the user's selected language.

---

## App Initialization

### Entry Point

The app starts in `RendioAIApp.swift`:

```swift
@main
struct RendioAIApp: App {
    @StateObject private var themeObserver = ThemeObserver()
    @StateObject private var localizationManager = LocalizationManager.shared

    init() {
        // Set language before any views render
        let savedLanguage = UserDefaultsManager.shared.language
        UserDefaults.standard.set([savedLanguage, "en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(themeObserver.colorScheme)
                .environmentObject(themeObserver)
                .environmentObject(localizationManager)
        }
    }
}
```

### Initialization Sequence

```
1. App Launch
   └── RendioAIApp.init()
       └── Load language preference
       └── Configure system localization

2. Create Global State
   └── Create ThemeObserver
   └── Create LocalizationManager

3. Show Splash Screen
   └── SplashView appears
   └── Play launch animation

4. Onboarding Process
   └── Check if onboarding completed
   └── If not: Verify device
   └── Save device ID and user ID
   └── Mark onboarding complete

5. Transition to Main App
   └── Ensure 2+ second splash duration
   └── Present ContentView

6. Main App Ready
   └── TabView with 3 tabs shown
   └── Home/History/Profile load data
   └── App is fully initialized
```

### Splash Screen

The splash screen serves two purposes:
1. **Branding**: Show app logo for 2+ seconds
2. **Onboarding**: Verify device and initialize user

```swift
struct SplashView: View {
    @StateObject private var viewModel = SplashViewModel()
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color("BrandPrimary").ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("App Name")
                    .font(.system(size: 42, weight: .bold))

                if viewModel.showLoadingIndicator {
                    ProgressView()
                }
            }
        }
        .onAppear {
            // Animate logo
            withAnimation(.spring()) {
                scale = 1.0
                opacity = 1.0
            }

            // Start onboarding
            Task {
                await viewModel.performOnboarding()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isOnboardingComplete) {
            ContentView()
        }
    }
}
```

**Splash Timing:**
- Minimum: 2 seconds (for branding)
- Maximum: 30 seconds (safety timeout)
- Shows loading indicator after 2 seconds if still processing

### Main Navigation Setup

After splash, `ContentView` sets up the tab navigation:

```swift
struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(1)

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(2)
        }
        .tint(Color("BrandPrimary"))
    }
}
```

---

## Key Architectural Patterns

### 1. MVVM (Model-View-ViewModel)

Every screen follows this structure:

```
View ← ViewModel ← Services ← Models
```

**Example:**
- `HomeView` (UI) → `HomeViewModel` (logic) → `ThemeService` (API) → `Theme` (data)

**Benefits:**
- Separates UI from logic
- ViewModels are testable
- Clear responsibility boundaries

### 2. Service Layer Pattern

All API calls go through dedicated service classes:

```
Views → ViewModels → Services → Backend
```

**Benefits:**
- Centralized API logic
- Easy to mock for testing
- Consistent error handling

### 3. Protocol-Based Design

All services implement protocols:

```swift
protocol ThemeServiceProtocol {
    func fetchThemes() async throws -> [Theme]
}

class ThemeService: ThemeServiceProtocol { ... }
class MockThemeService: ThemeServiceProtocol { ... }
```

**Benefits:**
- Enables dependency injection
- Makes testing easier
- Allows swapping implementations

### 4. Singleton Pattern

Services and managers use shared instances:

```swift
ThemeService.shared
UserDefaultsManager.shared
LocalizationManager.shared
```

**Benefits:**
- Single source of truth
- Consistent state across app
- Easy global access

### 5. Dependency Injection

ViewModels accept services via initializer:

```swift
class HomeViewModel {
    private let themeService: ThemeServiceProtocol
    private let creditService: CreditServiceProtocol

    init(
        themeService: ThemeServiceProtocol = ThemeService.shared,
        creditService: CreditServiceProtocol = CreditService.shared
    ) {
        self.themeService = themeService
        self.creditService = creditService
    }
}
```

**Benefits:**
- Testable (inject mocks)
- Flexible (swap implementations)
- Clear dependencies

### 6. Computed Properties Pattern

ViewModels use computed properties for derived state:

```swift
var canGenerate: Bool {
    !prompt.isEmpty && creditsRemaining >= cost && selectedImage != nil
}

var isVideoReady: Bool {
    videoJob?.status == "completed" && videoURL != nil
}
```

**Benefits:**
- Always up-to-date
- No manual syncing needed
- Single source of truth

### 7. Fallback/Graceful Degradation

The app handles failures gracefully:

- DeviceCheck fails → Use UUID fallback
- Theme fetch fails → Show empty state
- Credit fetch fails → Assume 0 credits
- Image upload fails → Show error, allow retry

**Benefits:**
- Better user experience
- App always works
- No dead ends

### 8. State Machine Pattern

Complex flows use state machines:

```swift
enum OnboardingStep {
    case idle
    case started
    case checkingDeviceSupport
    case verifyingDevice
    case completed
}
```

**Benefits:**
- Clear flow tracking
- Easier debugging
- Predictable behavior

### 9. Notification Pattern

Global state changes use NotificationCenter:

```swift
// Language changes broadcast
NotificationCenter.default.post(
    name: .languageDidChange,
    object: newLanguage
)

// LocalizationManager observes
NotificationCenter.default.addObserver(
    forName: .languageDidChange,
    object: nil,
    queue: .main
) { notification in
    self.currentLanguage = notification.object as? String ?? "en"
}
```

**Benefits:**
- Decoupled communication
- Multiple observers supported
- Works across view hierarchy

### 10. Async/Await Pattern

All async operations use Swift's modern concurrency:

```swift
func loadData() async {
    do {
        let data = try await service.fetchData()
        self.data = data
    } catch {
        self.errorMessage = error.localizedDescription
    }
}
```

**Benefits:**
- Cleaner than callbacks
- Better error handling
- Easier to read and maintain

---

## How Screens Interact with Backend

### Data Flow Overview

```
User Action
    ↓
View calls ViewModel method
    ↓
ViewModel calls Service method
    ↓
Service makes HTTP request to Backend
    ↓
Backend processes and returns JSON
    ↓
Service decodes JSON to Swift models
    ↓
ViewModel updates @Published properties
    ↓
SwiftUI automatically re-renders View
```

### Example: Loading Home Screen Themes

**1. User opens app → HomeView appears**

```swift
// HomeView.swift
struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        content
            .onAppear {
                Task {
                    await viewModel.loadData()
                }
            }
    }
}
```

**2. HomeViewModel fetches themes**

```swift
// HomeViewModel.swift
func loadData() async {
    isLoading = true

    do {
        // Call ThemeService
        let themes = try await themeService.fetchThemes()

        // Update UI state
        self.allThemes = themes
        self.featuredThemes = themes.filter { $0.isFeatured }
    } catch {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }

    isLoading = false
}
```

**3. ThemeService makes API call**

```swift
// ThemeService.swift
func fetchThemes() async throws -> [Theme] {
    let url = URL(string: "\(AppConfig.supabaseURL)/functions/v1/get-models")!

    var request = URLRequest(url: url)
    request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AppError.networkFailure
    }

    return try JSONDecoder().decode([Theme].self, from: data)
}
```

**4. Backend returns JSON**

```json
[
  {
    "id": "theme-1",
    "name": "Cinematic",
    "description": "Hollywood-style videos",
    "is_featured": true,
    "thumbnail_url": "https://...",
    "cost_per_generation": 5
  }
]
```

**5. View updates automatically**

SwiftUI detects that `allThemes` changed and re-renders the view with the new data.

### Example: Generating a Video

**1. User fills prompt and taps "Generate"**

```swift
// ModelDetailView.swift
PrimaryButton(
    title: "Generate Video",
    action: {
        Task {
            await viewModel.generateVideo()
        }
    },
    isEnabled: viewModel.canGenerate
)
```

**2. ModelDetailViewModel prepares request**

```swift
// ModelDetailViewModel.swift
func generateVideo() async {
    guard canGenerate else { return }

    isGenerating = true

    do {
        // Build request
        let request = VideoGenerationRequest(
            user_id: currentUserId,
            theme_id: theme.id,
            prompt: prompt,
            image_url: uploadedImageURL,
            settings: settings
        )

        // Call service
        let response = try await videoGenerationService.generateVideo(request: request)

        // Store job ID
        self.generatedJobId = response.job_id

        // Navigate to result screen
        showingResultScreen = true
    } catch {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
    }

    isGenerating = false
}
```

**3. VideoGenerationService sends request**

```swift
// VideoGenerationService.swift
func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
    let url = URL(string: "\(AppConfig.supabaseURL)/functions/v1/generate-video")!

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
    urlRequest.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder().decode(VideoGenerationResponse.self, from: data)
}
```

**4. Backend processes generation**

Backend receives request, validates credits, starts AI generation, and returns:

```json
{
  "job_id": "job-abc123",
  "status": "queued",
  "estimated_time": 120
}
```

**5. ResultView polls for completion**

```swift
// ResultViewModel.swift
func loadVideoResult() async {
    isLoading = true

    // Poll every 3 seconds
    while true {
        do {
            let job = try await resultService.getVideoJob(jobId: jobId)
            self.videoJob = job

            if job.status == "completed" {
                self.videoURL = job.video_url
                break
            } else if job.status == "failed" {
                throw AppError.networkError("Generation failed")
            }

            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        } catch {
            errorMessage = error.localizedDescription
            break
        }
    }

    isLoading = false
}
```

---

## App State Flow Summary

### Global State
- **ThemeObserver**: Manages app-wide color scheme
- **LocalizationManager**: Manages app-wide language
- Injected via `@EnvironmentObject` to all views

### Feature State
- Each screen has a **ViewModel** with `@Published` properties
- ViewModels call **Services** for business logic
- Services call **Backend APIs**
- State updates trigger automatic UI re-renders

### Local State
- Simple UI state uses `@State`
- Examples: modal visibility, text input, toggles

### Persistence
- **UserDefaults**: Local preferences (language, theme, device ID)
- **Supabase**: User data (credits, history, profile)

---

## UI/UX Patterns

### Loading States
Every screen shows a loading indicator while fetching data:

```swift
if viewModel.isLoading && viewModel.data.isEmpty {
    ProgressView()
} else {
    ContentView()
}
```

### Empty States
When no data is available, show helpful empty state:

```swift
if viewModel.items.isEmpty {
    VStack {
        Image(systemName: "folder")
        Text("No items yet")
        Text("Generate your first video to see it here")
    }
}
```

### Error States
Errors show via alerts with localized messages:

```swift
.alert("Error", isPresented: $viewModel.showingErrorAlert) {
    Button("OK") { }
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

### Pull to Refresh
List screens support pull-to-refresh:

```swift
.refreshable {
    await viewModel.loadData()
}
```

### Search/Filter
History screen has search functionality:

```swift
var filteredSections: [HistorySection] {
    guard !searchQuery.isEmpty else { return historySections }
    return historySections.filter { section in
        section.items.contains { item in
            item.prompt.localizedCaseInsensitiveContains(searchQuery)
        }
    }
}
```

### Disabled States
Buttons disable when action is invalid:

```swift
PrimaryButton(
    title: "Generate",
    action: { generateVideo() },
    isEnabled: canGenerate  // Disabled if prompt empty or insufficient credits
)
```

### Loading Buttons
Buttons show loading spinner during async operations:

```swift
PrimaryButton(
    title: "Sign In",
    action: { signIn() },
    isLoading: viewModel.isSigningIn  // Shows spinner
)
```

---

## Reusable Logic Patterns

### 1. Async Task Pattern
All async operations follow this structure:

```swift
func performAction() {
    Task {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.action()
            self.result = result
        } catch {
            handleError(error)
        }
    }
}
```

### 2. Computed Property Validation
Form validation uses computed properties:

```swift
var canSubmit: Bool {
    !field1.isEmpty &&
    field2.count >= 3 &&
    hasRequiredData
}
```

### 3. Environment Object Injection
Global state accessed via environment:

```swift
@EnvironmentObject var themeObserver: ThemeObserver
@EnvironmentObject var localizationManager: LocalizationManager

// Access anywhere in view
themeObserver.colorScheme
localizationManager.currentLanguage
```

### 4. Service Initialization with Defaults
Services injected with default implementations:

```swift
init(
    service: ServiceProtocol = Service.shared,
    manager: ManagerProtocol = Manager.shared
) {
    self.service = service
    self.manager = manager
}
```

This allows:
- Production: Use real services
- Testing: Inject mock services

### 5. Localization Extension
String extension for easy localization:

```swift
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

// Usage:
Text("home.title".localized)
```

### 6. Error Handling Wrapper
Consistent error handling:

```swift
private func handleError(_ error: Error) {
    if let appError = error as? AppError {
        errorMessage = appError.errorDescription
    } else {
        errorMessage = "error.general.unexpected".localized
    }
    showingErrorAlert = true
}
```

---

## Summary

This iOS application is built with:

### Core Technologies
- **SwiftUI** for native iOS UI
- **MVVM** architecture pattern
- **URLSession** for networking
- **UserDefaults** for local storage
- **Supabase** for backend services

### Key Strengths
1. **Clean Architecture**: Clear separation of UI, logic, and data
2. **Testability**: Protocol-based services, dependency injection
3. **Native Performance**: Pure Swift, no external dependencies
4. **Maintainability**: Consistent patterns throughout
5. **User Experience**: Proper loading states, error handling, animations
6. **Internationalization**: Multi-language support
7. **Accessibility**: VoiceOver, Dynamic Type support

### File Organization
- **74 Swift files** organized by function
- **6 main screens** (Home, ModelDetail, Result, History, Profile, Splash)
- **9 networking services** for backend communication
- **15 model files** for data representation

### State Management
- Global: ThemeObserver, LocalizationManager
- Feature: ViewModels with @Published properties
- Local: @State for component-level state

### Navigation
- Tab-based main navigation (3 tabs)
- NavigationStack for per-tab navigation
- Modal sheets for temporary flows

This architecture provides a solid foundation for a scalable, maintainable iOS application.
