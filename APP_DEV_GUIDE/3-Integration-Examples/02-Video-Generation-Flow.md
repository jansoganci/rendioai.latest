# Video Generation Flow - End-to-End

## Overview

Complete flow from user tapping "Generate" button to displaying the finished video, including error handling, rollback, and state management.

---

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│                     iOS App (SwiftUI)                      │
├────────────────────────────────────────────────────────────┤
│  1. User taps "Generate Video"                             │
│  2. ModelDetailViewModel validates input                   │
│  3. Calls VideoGenerationService                           │
│     ↓                                                       │
│  4. Service generates idempotency key (UUID)               │
│  5. POST /generate-video with Idempotency-Key header       │
└────────────────────────┬───────────────────────────────────┘
                         │ HTTPS + JWT Auth
                         ↓
┌────────────────────────────────────────────────────────────┐
│              Supabase Edge Function                        │
├────────────────────────────────────────────────────────────┤
│  6. Check idempotency_log for duplicate                    │
│  7. Get model cost from database (never trust client)      │
│  8. Call deduct_credits() stored procedure                 │
│     - Atomic operation with row lock                       │
│     - Returns { success, credits_remaining }               │
│  9. If insufficient credits → return 402                   │
│  10. Create video_jobs record (status: pending)            │
│  11. Call FalAI provider API                               │
│  12. Store provider_job_id                                 │
│  13. Store idempotency record (cache response)             │
│  14. Return { job_id, status, credits_used }               │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ↓
┌────────────────────────────────────────────────────────────┐
│  15. iOS polls /get-video-status every 2s                  │
│  16. Backend queries FalAI for status                      │
│  17. Updates video_jobs.status                             │
│  18. When complete, migrates video to Supabase Storage     │
│  19. Returns { status: completed, video_url }              │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ↓
┌────────────────────────────────────────────────────────────┐
│  20. iOS receives completed status                         │
│  21. ResultView displays video player                      │
│  22. User can download/share                               │
└────────────────────────────────────────────────────────────┘
```

---

## iOS Implementation

### Step 1: User Input (ModelDetailView)

```swift
// Features/ModelDetail/ModelDetailView.swift

struct ModelDetailView: View {
    @StateObject private var viewModel: ModelDetailViewModel

    var body: some View {
        VStack {
            // Prompt input
            TextField("Describe your video...", text: $viewModel.prompt)

            // Settings
            Picker("Duration", selection: $viewModel.duration) {
                Text("4 seconds").tag(Duration.four)
                Text("8 seconds").tag(Duration.eight)
                Text("12 seconds").tag(Duration.twelve)
            }

            // Credits display
            HStack {
                Text("Cost:")
                Text("\(viewModel.estimatedCost) credits")
                    .fontWeight(.bold)
            }

            // Generate button
            Button("Generate Video") {
                viewModel.generateVideo()
            }
            .disabled(viewModel.isGenerating || !viewModel.canGenerate)
        }
        .alert("Insufficient Credits", isPresented: $viewModel.showInsufficientCreditsAlert) {
            Button("Buy Credits") {
                viewModel.showPurchaseSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
```

### Step 2: ViewModel Logic

```swift
// Features/ModelDetail/ModelDetailViewModel.swift

@MainActor
class ModelDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published var prompt: String = ""
    @Published var duration: Duration = .four
    @Published var resolution: Resolution = .hd720

    @Published private(set) var isGenerating: Bool = false
    @Published private(set) var estimatedCost: Int = 4

    @Published var showInsufficientCreditsAlert = false
    @Published var generatedJobId: String?

    // MARK: - Dependencies

    private let model: VideoModel
    private let videoService: VideoGenerationServiceProtocol
    private let creditService: CreditServiceProtocol

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !prompt.isEmpty && !isGenerating
    }

    // MARK: - Methods

    func generateVideo() {
        guard canGenerate else { return }

        isGenerating = true

        Task {
            do {
                // Create request
                let settings = VideoSettings(
                    duration: duration.seconds,
                    resolution: resolution.rawValue,
                    aspectRatio: "16:9"
                )

                let request = VideoGenerationRequest(
                    modelId: model.id,
                    prompt: prompt,
                    settings: settings
                )

                // Call service
                let response = try await videoService.generateVideo(request: request)

                // Handle success
                generatedJobId = response.jobId
                isGenerating = false

                // Navigate to result view (via coordinator/router)
                navigateToResult(jobId: response.jobId)

            } catch let error as AppError {
                isGenerating = false
                handleError(error)
            } catch {
                isGenerating = false
                handleError(AppError.from(error))
            }
        }
    }

    private func handleError(_ error: AppError) {
        switch error {
        case .insufficientCredits:
            showInsufficientCreditsAlert = true

        case .networkError:
            // Show network error toast

        default:
            // Show generic error
        }
    }
}
```

### Step 3: Video Generation Service

```swift
// Core/Networking/VideoGenerationService.swift

protocol VideoGenerationServiceProtocol {
    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

class VideoGenerationService: VideoGenerationServiceProtocol {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        // Generate idempotency key (CRITICAL for preventing duplicate charges)
        let idempotencyKey = UUID().uuidString

        let response: VideoGenerationResponse = try await apiClient.request(
            endpoint: "generate-video",
            method: .POST,
            body: request,
            headers: [
                "Idempotency-Key": idempotencyKey  // ← Prevents duplicate charges
            ]
        )

        return response
    }
}

// MARK: - Models

struct VideoGenerationRequest: Codable {
    let modelId: String
    let prompt: String
    let settings: VideoSettings

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case prompt
        case settings
    }
}

struct VideoGenerationResponse: Codable {
    let jobId: String
    let status: String
    let creditsUsed: Int
    let creditsRemaining: Int

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case creditsUsed = "credits_used"
        case creditsRemaining = "credits_remaining"
    }
}

struct VideoSettings: Codable {
    let duration: Int
    let resolution: String
    let aspectRatio: String

    enum CodingKeys: String, CodingKey {
        case duration
        case resolution
        case aspectRatio = "aspect_ratio"
    }
}
```

---

## Backend Implementation

### Step 4: Edge Function (/generate-video)

```typescript
// supabase/functions/generate-video/index.ts

import { createClient } from '@supabase/supabase-js'
import { callFalAI } from '../_shared/falai-adapter.ts'

Deno.serve(async (req) => {
    try {
        // Initialize Supabase client
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        // Parse request
        const { model_id, prompt, settings } = await req.json()
        const idempotencyKey = req.headers.get('Idempotency-Key')
        const authHeader = req.headers.get('Authorization')

        // Validate
        if (!idempotencyKey) {
            return new Response(
                JSON.stringify({ error: 'Idempotency-Key header required' }),
                { status: 400 }
            )
        }

        // Get user from JWT
        const { data: { user }, error: authError } = await supabase.auth.getUser(
            authHeader?.replace('Bearer ', '')
        )

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { status: 401 }
            )
        }

        const user_id = user.id

        // ===== IDEMPOTENCY CHECK =====
        const { data: existing } = await supabase
            .from('idempotency_log')
            .select('response_data, status_code')
            .eq('idempotency_key', idempotencyKey)
            .eq('user_id', user_id)
            .gt('expires_at', new Date().toISOString())
            .single()

        if (existing) {
            // Return cached response (duplicate request)
            return new Response(
                JSON.stringify(existing.response_data),
                {
                    status: existing.status_code,
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Idempotent-Replay': 'true'
                    }
                }
            )
        }

        // ===== GET MODEL COST (never trust client) =====
        const { data: model } = await supabase
            .from('models')
            .select('cost_per_generation, provider_model_id')
            .eq('id', model_id)
            .single()

        if (!model) {
            return new Response(
                JSON.stringify({ error: 'Model not found' }),
                { status: 404 }
            )
        }

        const cost = model.cost_per_generation

        // ===== DEDUCT CREDITS (atomic) =====
        const { data: deductResult } = await supabase.rpc('deduct_credits', {
            p_user_id: user_id,
            p_amount: cost,
            p_reason: 'video_generation'
        })

        if (!deductResult.success) {
            return new Response(
                JSON.stringify({
                    error: deductResult.error,
                    current_credits: deductResult.current_credits,
                    required_credits: cost
                }),
                { status: 402 }  // Payment Required
            )
        }

        // ===== CREATE VIDEO JOB =====
        const { data: job, error: jobError } = await supabase
            .from('video_jobs')
            .insert({
                user_id,
                model_id,
                prompt,
                settings,
                status: 'pending',
                credits_used: cost
            })
            .select()
            .single()

        if (jobError) {
            // ROLLBACK: Refund credits
            await supabase.rpc('add_credits', {
                p_user_id: user_id,
                p_amount: cost,
                p_reason: 'generation_failed_refund'
            })

            return new Response(
                JSON.stringify({ error: 'Failed to create job' }),
                { status: 500 }
            )
        }

        // ===== CALL VIDEO PROVIDER =====
        try {
            const providerResult = await callFalAI({
                model: model.provider_model_id,
                prompt,
                settings
            })

            // Update job with provider ID
            await supabase
                .from('video_jobs')
                .update({
                    provider_job_id: providerResult.request_id,
                    status: 'processing'
                })
                .eq('job_id', job.job_id)

        } catch (providerError) {
            // ROLLBACK: Mark failed and refund
            await supabase
                .from('video_jobs')
                .update({
                    status: 'failed',
                    error_message: providerError.message
                })
                .eq('job_id', job.job_id)

            await supabase.rpc('add_credits', {
                p_user_id: user_id,
                p_amount: cost,
                p_reason: 'generation_failed_refund',
                p_job_id: job.job_id
            })

            return new Response(
                JSON.stringify({ error: 'Provider API failed' }),
                { status: 500 }
            )
        }

        // ===== STORE IDEMPOTENCY RECORD =====
        const responseData = {
            job_id: job.job_id,
            status: 'pending',
            credits_used: cost,
            credits_remaining: deductResult.credits_remaining
        }

        await supabase.from('idempotency_log').insert({
            idempotency_key: idempotencyKey,
            user_id,
            job_id: job.job_id,
            operation_type: 'video_generation',
            response_data: responseData,
            status_code: 200,
            expires_at: new Date(Date.now() + 24 * 3600 * 1000).toISOString()
        })

        // ===== SUCCESS RESPONSE =====
        return new Response(
            JSON.stringify(responseData),
            {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
            }
        )

    } catch (error) {
        console.error('generate-video error:', error)
        return new Response(
            JSON.stringify({ error: 'Internal server error' }),
            { status: 500 }
        )
    }
})
```

### Step 5: FalAI Provider Adapter

```typescript
// supabase/functions/_shared/falai-adapter.ts

export async function callFalAI(params: {
    model: string
    prompt: string
    settings: any
}): Promise<{ request_id: string }> {
    const response = await fetch('https://queue.fal.run/fal-ai/veo-3.1', {
        method: 'POST',
        headers: {
            'Authorization': `Key ${Deno.env.get('FALAI_API_KEY')}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            prompt: params.prompt,
            duration: params.settings.duration,
            resolution: params.settings.resolution,
            aspect_ratio: params.settings.aspect_ratio
        })
    })

    if (!response.ok) {
        throw new Error(`FalAI API error: ${response.statusText}`)
    }

    const data = await response.json()
    return { request_id: data.request_id }
}
```

---

## Polling Flow (Result View)

### Step 6: iOS Polling

```swift
// Features/Result/ResultViewModel.swift

@MainActor
class ResultViewModel: ObservableObject {

    @Published private(set) var state: LoadingState<VideoJob> = .loading

    private let jobId: String
    private let resultService: ResultServiceProtocol

    init(jobId: String, resultService: ResultServiceProtocol) {
        self.jobId = jobId
        self.resultService = resultService
    }

    func startPolling() {
        Task {
            await pollStatus()
        }
    }

    private func pollStatus() async {
        while true {
            do {
                let job = try await resultService.getVideoStatus(jobId: jobId)

                switch job.status {
                case "completed":
                    state = .loaded(job)
                    return  // Stop polling

                case "failed":
                    state = .error(.videoGenerationFailed)
                    return  // Stop polling

                case "pending", "processing":
                    state = .loading
                    try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
                    continue  // Keep polling

                default:
                    state = .error(.unknownError)
                    return
                }

            } catch {
                state = .error(AppError.from(error))
                return
            }
        }
    }
}
```

### Step 7: Backend Status Polling

```typescript
// supabase/functions/get-video-status/index.ts

import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
    const supabase = createClient(...)
    const url = new URL(req.url)
    const job_id = url.searchParams.get('job_id')

    // Get job from database
    const { data: job } = await supabase
        .from('video_jobs')
        .select('*')
        .eq('job_id', job_id)
        .single()

    if (!job) {
        return new Response(
            JSON.stringify({ error: 'Job not found' }),
            { status: 404 }
        )
    }

    // If still processing, check provider status
    if (job.status === 'processing' && job.provider_job_id) {
        const providerStatus = await checkFalAIStatus(job.provider_job_id)

        if (providerStatus.status === 'completed') {
            // Migrate video to Supabase Storage
            const videoUrl = await migrateVideoToStorage(
                providerStatus.video_url,
                job.job_id
            )

            // Update job
            await supabase
                .from('video_jobs')
                .update({
                    status: 'completed',
                    video_url: videoUrl,
                    completed_at: new Date().toISOString()
                })
                .eq('job_id', job_id)

            job.status = 'completed'
            job.video_url = videoUrl
        }
    }

    return new Response(
        JSON.stringify({
            job_id: job.job_id,
            status: job.status,
            video_url: job.video_url,
            thumbnail_url: job.thumbnail_url,
            created_at: job.created_at,
            completed_at: job.completed_at
        }),
        { status: 200 }
    )
})
```

---

## Error Scenarios

### 1. Insufficient Credits

**Backend:**
```typescript
// Returns 402 Payment Required
{
    error: "Insufficient credits",
    current_credits: 2,
    required_credits: 4
}
```

**iOS:**
```swift
catch let error as AppError {
    if case .insufficientCredits = error {
        showInsufficientCreditsAlert = true
    }
}
```

### 2. Network Retry (Idempotency)

**First Request:**
- iOS generates idempotency key: `"abc-123"`
- Backend processes, stores in `idempotency_log`
- Response: `{ job_id: "job-456", status: "pending" }`

**Network drops, iOS retries:**
- iOS sends same idempotency key: `"abc-123"`
- Backend finds existing record
- Returns cached response (no duplicate charge)

### 3. Provider API Failure

**Backend:**
```typescript
try {
    await callFalAI(...)
} catch {
    // Rollback: Mark job failed
    await supabase
        .from('video_jobs')
        .update({ status: 'failed' })
        .eq('job_id', job.job_id)

    // Rollback: Refund credits
    await supabase.rpc('add_credits', {
        p_user_id: user_id,
        p_amount: cost,
        p_reason: 'generation_failed_refund'
    })

    throw error
}
```

---

## Summary

### Critical Components

| Step | Component | Key Feature |
|------|-----------|-------------|
| 1-3 | iOS UI → ViewModel → Service | User input validation |
| 4 | Idempotency check | Prevent duplicate charges |
| 5 | Credit deduction | Atomic operation with row lock |
| 6 | Job creation | Database record |
| 7 | Provider API call | FalAI integration |
| 8 | Idempotency store | Cache response |
| 9-10 | Polling | Status updates every 2s |
| 11 | Video migration | Move to Supabase Storage |
| 12 | Result display | Video player |

### Security Guarantees

- ✅ User never charged twice (idempotency)
- ✅ No race conditions (atomic operations)
- ✅ Credits refunded on failure (rollback)
- ✅ Cost validated on backend (never trust client)
- ✅ Complete audit trail (quota_log)

**Next:** [Credit Purchase Flow →](03-Credit-Purchase-Flow.md)
