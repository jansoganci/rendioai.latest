# 🌐 Backend API Context — Rendio AI

**Purpose:** Quick reference for API integration — endpoints, adapters, response mapping, error handling.

**Sources:** `design/backend/api-layer-blueprint.md`, `design/backend/api-adapter-interface.md`, `design/backend/api-response-mapping.md`

---

## 📡 API Endpoints

**Base URL:** `{SUPABASE_URL}/functions/v1`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/generate-video` | POST | Create video job, deduct credits |
| `/get-video-status?job_id={id}` | GET | Poll generation progress |
| `/get-video-jobs?user_id={id}` | GET | Fetch user history |
| `/get-user-credits?user_id={id}` | GET | Get credit balance |
| `/update-credits` | POST | Add/deduct credits |

**Request Example:**
```swift
struct VideoGenerationRequest: Codable {
    let user_id: String
    let model_id: String
    let prompt: String
    let settings: VideoSettings
}

struct VideoSettings: Codable {
    let duration: Int?
    let resolution: String?
    let fps: Int?
}
```

**Response Example:**
```swift
struct VideoGenerationResponse: Codable {
    let job_id: String
    let status: String  // "pending", "processing", "completed", "failed"
    let credits_used: Int
}
```

---

## 🔌 Adapter Pattern

**Unified Interface:**
```swift
enum ProviderType: String, Codable {
    case fal = "fal-ai/veo3.1"
    case sora = "fal-ai/sora-2/image-to-video"
}

protocol VideoGenerationProvider {
    func generateVideo(input: VideoInput) async throws -> VideoResult
}

struct VideoInput: Codable {
    let prompt: String
    let aspectRatio: String?
    let resolution: String?
    let duration: Int?
    let generateAudio: Bool?
    let imageURL: String?  // Sora only
}

struct VideoResult: Codable {
    let provider: ProviderType
    let videoURL: String
    let resolution: String?
    let duration: Float?
    let fps: Float?
    let hasAudio: Bool?
    let createdAt: Date
}
```

**Factory:**
```swift
final class VideoAdapter {
    static let shared = VideoAdapter()
    
    func generateVideo(provider: ProviderType, input: VideoInput) async throws -> VideoResult {
        switch provider {
        case .fal: return try await FalProvider().generateVideo(input: input)
        case .sora: return try await SoraProvider().generateVideo(input: input)
        }
    }
}
```

**Benefits:**
- New providers added without changing app logic
- Centralized error handling
- Retry policy: 3 attempts, exponential backoff, 120s timeout

---

## 🧩 Response Mapping

**Provider-specific models → Unified VideoResult:**

```swift
final class UnifiedVideoResultMapper {
    static func mapFalResponse(_ response: FalVeo31Response) -> VideoResult {
        return VideoResult(
            provider: .fal,
            videoURL: response.video.url,
            resolution: "720p",
            hasAudio: true,
            createdAt: Date()
        )
    }
    
    static func mapSoraResponse(_ response: Sora2Response) -> VideoResult {
        return VideoResult(
            provider: .sora,
            videoURL: response.video.url,
            resolution: response.video.width >= 1080 ? "1080p" : "720p",
            duration: response.video.duration,
            fps: response.video.fps,
            hasAudio: true,
            createdAt: Date()
        )
    }
}
```

**Safe Decoding:**
```swift
extension Data {
    func decodeSafe<T: Decodable>(_ type: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: self)
    }
}
```

---

## 🔒 Security Rules

- **Never expose API keys** → FalAI key server-side only
- **All requests require** `device_id` or `user_id`
- **Edge Functions enforce RLS** → user data isolation
- **DeviceCheck validation** on `/generate-video` for guests

---

## 📚 References

- API blueprint: `design/backend/api-layer-blueprint.md`
- Adapter interface: `design/backend/api-adapter-interface.md`
- Response mapping: `design/backend/api-response-mapping.md`
