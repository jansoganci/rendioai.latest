⸻

# 🎛️ API Adapter Interface — Rendio AI

**Version:** 1.0  

**Last Updated:** 2025-11-05  

**Scope:** Unified interface for multiple video generation providers (FalAI Veo 3.1, Sora 2)

---

## 🎯 Purpose

The API Adapter Interface defines a unified abstraction layer between the iOS app and multiple video generation providers.

It ensures:

- Consistent function calls regardless of the provider (Fal, Sora, etc.)
- Centralized error handling and retries
- Simplified swapping or addition of new models in the future

---

## 🧩 Core Design

### 1. Provider Enumeration

```swift
enum ProviderType: String, Codable {
    case fal = "fal-ai/veo3.1"
    case sora = "fal-ai/sora-2/image-to-video"
}
```

⸻

### 2. Unified Input Model

```swift
struct VideoInput: Codable {
    let prompt: String
    let aspectRatio: String? // e.g., "16:9" or "9:16"
    let resolution: String?  // "720p" or "1080p"
    let duration: Int?       // seconds
    let generateAudio: Bool? // only used in Fal
    let imageURL: String?    // only used in Sora
}
```

⸻

### 3. Unified Output Model

```swift
struct VideoResult: Codable {
    let provider: ProviderType
    let videoURL: String
    let resolution: String?
    let duration: Float?
    let fps: Float?
    let width: Int?
    let height: Int?
    let hasAudio: Bool?
    let createdAt: Date
}
```

⸻

### 4. VideoGenerationProvider Protocol

```swift
protocol VideoGenerationProvider {
    func generateVideo(input: VideoInput) async throws -> VideoResult
}
```

All providers conform to this protocol.

⸻

### 5. Provider Implementations

**🔹 Fal Provider (Text-to-Video)**

```swift
final class FalProvider: VideoGenerationProvider {
    func generateVideo(input: VideoInput) async throws -> VideoResult {
        // Calls "fal-ai/veo3.1"
        // Maps API response to VideoResult
    }
}
```

**🔹 Sora Provider (Image-to-Video)**

```swift
final class SoraProvider: VideoGenerationProvider {
    func generateVideo(input: VideoInput) async throws -> VideoResult {
        // Calls "fal-ai/sora-2/image-to-video"
        // Maps API response to VideoResult
    }
}
```

⸻

### 6. Factory / Manager

```swift
final class VideoAdapter {
    static let shared = VideoAdapter()
    
    func generateVideo(provider: ProviderType, input: VideoInput) async throws -> VideoResult {
        switch provider {
        case .fal:
            return try await FalProvider().generateVideo(input: input)
        case .sora:
            return try await SoraProvider().generateVideo(input: input)
        }
    }
}
```

⸻

## 🧠 Retry & Error Handling Strategy

- **Retry Policy:** Up to 3 attempts with exponential backoff
- **Timeout:** 120 seconds per request
- **Fallback:** If provider unreachable → throw `VideoAdapterError.providerUnavailable`
- **Error Enumeration:**

```swift
enum VideoAdapterError: Error {
    case invalidResponse
    case providerUnavailable
    case insufficientCredits
    case unauthorized
    case unknown(String)
}
```

⸻

## 🪶 Benefits

1. New models (e.g., Runway, Pika) can be added without modifying the app logic.
2. Unified structure simplifies caching and analytics.
3. Keeps Swift codebase modular and testable.

⸻

**Next Step →** `api-response-mapping.md`

Defines how each provider's JSON output is mapped to `VideoResult`.

---
