⸻

# 🧩 API Response Mapping — Rendio AI

**Version:** 1.0  

**Last Updated:** 2025-11-05  

**Scope:** Standardized response models for FalAI (Veo 3.1) and Sora 2 integrations

---

## 🎯 Purpose

To unify and safely decode JSON responses from multiple AI video providers into a single, consistent model:  

`VideoResult`

This ensures all screens (ResultView, History, etc.) can display metadata and video content regardless of the provider.

---

## 🧠 Provider Response Models

### 🔹 FalAI — Veo 3.1 (`fal-ai/veo3.1`)

**API Output Example:**

```json
{
  "video": {
    "url": "https://v3b.fal.media/files/b/kangaroo/output.mp4"
  }
}
```

**Swift Model:**

```swift
struct FalVeo31Response: Codable {
    let video: FalVideoData
}

struct FalVideoData: Codable {
    let url: String
}
```

⸻

### 🔹 Sora 2 — Image-to-Video (`fal-ai/sora-2/image-to-video`)

**API Output Example:**

```json
{
  "video": {
    "content_type": "video/mp4",
    "url": "https://storage.googleapis.com/falserverless/example_outputs/sora_2_i2v_output.mp4",
    "width": 1280,
    "height": 720,
    "fps": 24,
    "duration": 4.2
  },
  "video_id": "video_123"
}
```

**Swift Model:**

```swift
struct Sora2Response: Codable {
    let video: Sora2VideoData
    let video_id: String
}

struct Sora2VideoData: Codable {
    let url: String
    let content_type: String?
    let width: Int?
    let height: Int?
    let fps: Float?
    let duration: Float?
}
```

⸻

## 🔁 Unified Mapping

The following mapper normalizes Fal and Sora responses to the unified `VideoResult` model (defined in `api-adapter-interface.md`).

```swift
final class UnifiedVideoResultMapper {
    
    static func mapFalResponse(_ response: FalVeo31Response) -> VideoResult {
        return VideoResult(
            provider: .fal,
            videoURL: response.video.url,
            resolution: "720p",
            duration: nil,
            fps: nil,
            width: nil,
            height: nil,
            hasAudio: true,
            createdAt: Date()
        )
    }
    
    static func mapSoraResponse(_ response: Sora2Response) -> VideoResult {
        return VideoResult(
            provider: .sora,
            videoURL: response.video.url,
            resolution: {
                guard let w = response.video.width else { return nil }
                return w >= 1080 ? "1080p" : "720p"
            }(),
            duration: response.video.duration,
            fps: response.video.fps,
            width: response.video.width,
            height: response.video.height,
            hasAudio: true,
            createdAt: Date()
        )
    }
}
```

⸻

## ⚠️ Error Response Handling

Both APIs may fail with error messages like:

```json
{ "error": "Invalid API key" }
```

**Generic Error Model:**

```swift
struct FalErrorResponse: Codable {
    let error: String
}
```

**Safe Decode Utility:**

```swift
extension Data {
    func decodeSafe<T: Decodable>(_ type: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(T.self, from: self)
    }
}
```

This allows:

- Silent fallback to generic error display
- Prevention of crashes from schema mismatches

⸻

## 🧱 Integration Example

**Usage in FalProvider:**

```swift
let data = try await fal.queue.response("fal-ai/veo3.1", of: jobId)

if let response = data.decodeSafe(FalVeo31Response.self) {
    return UnifiedVideoResultMapper.mapFalResponse(response)
} else if let err = data.decodeSafe(FalErrorResponse.self) {
    throw VideoAdapterError.unknown(err.error)
} else {
    throw VideoAdapterError.invalidResponse
}
```

**Usage in SoraProvider:**

```swift
let data = try await fal.queue.response("fal-ai/sora-2/image-to-video", of: jobId)

if let response = data.decodeSafe(Sora2Response.self) {
    return UnifiedVideoResultMapper.mapSoraResponse(response)
} else if let err = data.decodeSafe(FalErrorResponse.self) {
    throw VideoAdapterError.unknown(err.error)
} else {
    throw VideoAdapterError.invalidResponse
}
```

⸻

## ✅ Benefits

1. Decouples each provider's schema from the app UI
2. Prevents runtime crashes with safe decoding
3. Standardizes metadata for use in HistoryView
4. Supports future providers (Runway, Pika) easily

⸻

**Next Step →**

Integrate the mapper into `FalProvider` and `SoraProvider` within the API adapter implementation.

⸻

## 📄 File Summary

- **Location:** `design/backend/api-response-mapping.md`
- **Linked Doc:** `api-adapter-interface.md`
- **Status:** ✅ Complete for MVP (Fal + Sora)

---
