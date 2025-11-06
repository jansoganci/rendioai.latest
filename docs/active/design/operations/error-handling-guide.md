⸻

# 🚨 Error Handling Guide — Rendio AI

**Version:** 1.0.0

**Scope:** Unified error handling system for iOS client, Supabase backend, and Fal API integration

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🎯 Purpose

This document defines how Rendio AI detects, categorizes, localizes, and displays errors across the app.

All error messages are centralized in `errors.json` (or `Localizable.stringsdict`) to support i18n and prevent hardcoded text.

⸻

## 🧱 1. Error Categories

| Category | Prefix | Source | Example Code |
|----------|--------|--------|--------------|
| UI / Validation | `error.validation.*` | iOS Client | `error.validation.empty_prompt` |
| Network | `error.network.*` | Supabase / Fal API | `error.network.timeout` |
| API / Backend | `error.api.*` | Edge Functions / Supabase | `error.api.failed` |
| Credit System | `error.credit.*` | Credit Manager | `error.credit.insufficient` |
| Security / Auth | `error.auth.*` | DeviceCheck / Sign-in | `error.auth.device_invalid` |
| Unknown / Generic | `error.general.*` | Catch-all | `error.general.unexpected` |

⸻

## 💬 2. Localization & i18n Keys

All error messages must be referenced by i18n keys, not plain text.

Each key maps to a localized message in `/i18n/en.json`, `/i18n/tr.json`, etc.

**Example mapping:**

```json
{
  "error.validation.empty_prompt": "Please enter a prompt before generating a video.",
  "error.network.timeout": "The connection timed out. Please try again.",
  "error.credit.insufficient": "You don't have enough credits.",
  "error.api.failed": "The server could not complete your request.",
  "error.general.unexpected": "Something went wrong. Please try again later."
}
```

**In SwiftUI:**

```swift
Text(LocalizationManager.shared.text(for: "error.network.timeout"))
```

⸻

## ⚙️ 3. Error Propagation Model

All errors flow through a central error handler in the ViewModel layer.

```
FalAPI → Supabase Edge → ViewModel → ErrorMapper → UI Toast
```

**Swift Example:**

```swift
func handleError(_ error: AppError) {
    let localizedKey = ErrorMapper.map(error)
    self.alertMessage = LocalizationManager.shared.text(for: localizedKey)
    self.showingErrorAlert = true
}
```

⸻

## 🧩 4. Error Mapping

A unified ErrorMapper converts system errors into app-level i18n keys.

**Example:**

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
        case .invalidDevice: return "error.auth.device_invalid"
        case .unknown: return "error.general.unexpected"
        }
    }
}
```

⸻

## 🪟 5. UI Presentation Rules

| Error Type | Display Style | Example |
|------------|---------------|---------|
| Validation | Inline label or toast | "Please enter a prompt." |
| Network | Banner | "Connection lost." |
| Credit | Modal + CTA | "You're out of credits. [Buy Credits]" |
| API / Server | Banner or modal | "The server couldn't complete your request." |
| Security / Auth | Full-screen alert | "Device authentication failed. Restart app." |
| Unknown | Toast | "Something went wrong." |

⸻

## 🔄 6. Error Logging & Telemetry

All caught errors are also logged for monitoring via Telegram (see MonitoringAndAlerts.md).

**Log Format:**

```
[ERROR][timestamp] category=network key=error.network.timeout user_id=UUID1234
```

Sensitive user data (prompt text, file URLs) must never be included.

⸻

## 🧠 7. Developer Guidelines

✅ Always throw `AppError`, never raw `Error`.

✅ Use `ErrorMapper` before UI rendering.

✅ All new error types must include:

- Unique i18n key
- User-facing message
- Optional recovery hint

⸻

## 🧩 8. Example Flow

1️⃣ User taps "Generate Video"  
2️⃣ Network request fails (timeout)  
3️⃣ FalAPI throws `AppError.networkTimeout`  
4️⃣ ErrorMapper → `"error.network.timeout"`  
5️⃣ UI → Toast: "Connection timed out. Please try again."

⸻

## 🌍 9. i18n Expansion Example

**en.json:**

```json
{
  "error.network.timeout": "The connection timed out. Please try again."
}
```

**tr.json:**

```json
{
  "error.network.timeout": "Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin."
}
```

All language packs follow the same key hierarchy.

⸻

## ✅ 10. Summary

| Rule | Description |
|------|-------------|
| Centralized handling | All errors flow through ViewModel → ErrorMapper → i18n |
| No hardcoded messages | Everything comes from localized files |
| User-friendly wording | Avoid technical jargon ("API 500") |
| i18n-ready | Keys structured by category |
| Logged safely | No personal data in logs |

⸻
