# 🚨 Error Handling Context — Rendio AI

**Purpose:** Quick reference for error handling — categories, mapping, i18n, UI presentation.

**Sources:** `design/operations/error-handling-guide.md`, `design/general-rulebook.md`

---

## 🧱 Error Categories

| Category | Prefix | Source | Example |
|----------|--------|--------|---------|
| Validation | `error.validation.*` | iOS Client | `error.validation.empty_prompt` |
| Network | `error.network.*` | Supabase / Fal API | `error.network.timeout` |
| API / Backend | `error.api.*` | Edge Functions | `error.api.failed` |
| Credit | `error.credit.*` | Credit Manager | `error.credit.insufficient` |
| Security / Auth | `error.auth.*` | DeviceCheck | `error.auth.device_invalid` |
| Generic | `error.general.*` | Catch-all | `error.general.unexpected` |

---

## 🔄 Error Propagation

**Flow:** `FalAPI → Supabase Edge → ViewModel → ErrorMapper → UI Toast`

**Swift Implementation:**
```swift
enum AppError: LocalizedError {
    case networkTimeout
    case insufficientCredits
    case invalidDevice
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkTimeout: return "error.network.timeout"
        case .insufficientCredits: return "error.credit.insufficient"
        case .invalidDevice: return "error.auth.device_invalid"
        case .unknown: return "error.general.unexpected"
        }
    }
}

struct ErrorMapper {
    static func map(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription ?? "error.general.unexpected"
        }
        return "error.general.unexpected"
    }
}
```

**ViewModel Handler:**
```swift
func handleError(_ error: Error) {
    let errorKey = ErrorMapper.map(error)
    errorMessage = LocalizedStringKey(errorKey)
    showingErrorAlert = true
}
```

---

## 💬 Localization (i18n)

**All error messages via i18n keys** (never hardcoded):

```swift
// ✅ DO
Text(LocalizationManager.shared.text(for: "error.network.timeout"))

// ❌ DON'T
Text("Connection timed out")
```

**i18n Structure:**
- `/Resources/Localizations/en.lproj/`
- `/Resources/Localizations/tr.lproj/`
- Keys: `error.{category}.{specific}`

**Example mapping:**
```json
{
  "error.validation.empty_prompt": "Please enter a prompt before generating a video.",
  "error.network.timeout": "The connection timed out. Please try again.",
  "error.credit.insufficient": "You don't have enough credits."
}
```

---

## 🪟 UI Presentation Rules

| Error Type | Display Style | Duration | Haptic |
|------------|---------------|----------|--------|
| **Validation** | Inline label or toast | 2s | none |
| **Network** | Banner | 3s | medium |
| **Credit** | Modal + CTA button | Until dismissed | error |
| **API / Server** | Banner or modal | 4s | error |
| **Security / Auth** | Full-screen alert | Until dismissed | error |
| **Unknown** | Toast | 3s | light |

**Toast Implementation:**
```swift
ToastView(
    message: LocalizedStringKey(errorKey),
    type: .error,
    duration: 4.0
)
```

**Max 3 concurrent toasts** → auto-dismiss oldest.

---

## 📝 Logging

**Use `Logger` (os_log):**
```swift
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let video = Logger(subsystem: subsystem, category: "video")
}

Logger.networking.error("Network timeout: \(error.localizedDescription)")
```

**Rules:**
- **Never log sensitive data** (API keys, user tokens, prompts, URLs)
- Format: `[ERROR][timestamp] category=network key=error.network.timeout user_id=UUID1234`
- Log context only (what failed, why)

---

## ✅ Developer Guidelines

- ✅ Always throw `AppError`, never raw `Error`
- ✅ Use `ErrorMapper` before UI rendering
- ✅ All new errors must include: unique i18n key + user-facing message
- ✅ User-friendly wording (avoid "API 500")

---

## 📚 References

- Full error guide: `design/operations/error-handling-guide.md`
- Logging patterns: `design/general-rulebook.md` (Section 8)
