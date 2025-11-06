# Add Error Type to Centralized System

You are extending Rendio AI's centralized error handling system with a new error type.

## Instructions

Ask the user:
1. **Error scenario** (what goes wrong)
2. **Error category** (network, validation, API, credit, auth, general)
3. **User-facing message** (what the user should see)
4. **Recovery action** (what can the user do)

Then update the error system:

### 1. Add to AppError Enum

File: `Core/Models/AppError.swift`

```swift
enum AppError: LocalizedError {
    case networkFailure
    case networkTimeout
    case invalidResponse
    case insufficientCredits
    case unauthorized
    case invalidDevice
    // ADD NEW CASE HERE
    case {newErrorName}
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "error.network.failure"
        case .networkTimeout:
            return "error.network.timeout"
        case .invalidResponse:
            return "error.network.invalid_response"
        case .insufficientCredits:
            return "error.credit.insufficient"
        case .unauthorized:
            return "error.auth.unauthorized"
        case .invalidDevice:
            return "error.auth.device_invalid"
        // ADD NEW CASE MAPPING
        case .{newErrorName}:
            return "error.{category}.{name}"
        case .unknown(let message):
            return message
        }
    }
}
```

### 2. Add i18n Keys

Update localization files:

**`Resources/Localizations/en.lproj/Localizable.strings`:**
```
"error.{category}.{name}" = "User-facing error message in English";
```

**`Resources/Localizations/tr.lproj/Localizable.strings`:**
```
"error.{category}.{name}" = "Turkish translation";
```

### 3. Update ErrorMapper

File: `Core/Utilities/ErrorMapper.swift`

```swift
struct ErrorMapper {
    static func map(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "error.general.unexpected"
        }

        // Map system errors to AppError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return AppError.networkTimeout.errorDescription!
            case .notConnectedToInternet:
                return AppError.networkFailure.errorDescription!
            // ADD NEW SYSTEM ERROR MAPPING
            default:
                return AppError.unknown(urlError.localizedDescription).errorDescription!
            }
        }

        return AppError.unknown(error.localizedDescription).errorDescription!
    }
}
```

### 4. Throw Pattern in Services

Example usage in service layer:

```swift
class VideoService {
    func generateVideo(prompt: String) async throws -> VideoResult {
        guard !prompt.isEmpty else {
            throw AppError.{validationError}
        }

        guard creditsRemaining > 0 else {
            throw AppError.insufficientCredits
        }

        do {
            let response = try await apiCall()
            return response
        } catch {
            // Map to AppError
            throw AppError.{newErrorName}
        }
    }
}
```

### 5. Handle in ViewModel

Example in ViewModel:

```swift
@MainActor
class HomeViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var showingErrorAlert = false

    func performAction() {
        Task {
            do {
                try await service.someOperation()
            } catch {
                handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        let errorKey = ErrorMapper.map(error)
        errorMessage = LocalizationManager.shared.text(for: errorKey)
        showingErrorAlert = true
    }
}
```

### 6. UI Presentation

In View:

```swift
.alert("Error", isPresented: $viewModel.showingErrorAlert) {
    Button("OK", role: .cancel) { }
} message: {
    if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
    }
}
```

Or with Toast:

```swift
.toast(
    isPresenting: $viewModel.showingErrorToast,
    message: viewModel.errorMessage ?? "",
    type: .error
)
```

## Error Category Prefixes

Use these i18n key patterns:

| Category | Prefix | Example |
|----------|--------|---------|
| Validation | `error.validation.*` | `error.validation.empty_prompt` |
| Network | `error.network.*` | `error.network.timeout` |
| API | `error.api.*` | `error.api.failed` |
| Credit | `error.credit.*` | `error.credit.insufficient` |
| Auth | `error.auth.*` | `error.auth.device_invalid` |
| General | `error.general.*` | `error.general.unexpected` |

## Output

Provide:
1. **Updated AppError enum** (complete)
2. **i18n keys** (EN + TR)
3. **ErrorMapper updates** (if needed)
4. **Service throw example**
5. **ViewModel handling example**
6. **UI presentation example**
7. **Testing scenario** (how to trigger this error)

Include:
- Clear user-facing message (non-technical)
- Recovery instructions (what user should do)
- Whether error should be logged/reported
