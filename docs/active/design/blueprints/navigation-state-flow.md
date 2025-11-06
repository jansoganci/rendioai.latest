⸻

# 🧭 Video App – Navigation + State Flow Diagram

**Date:** 2025-11-04

**Document Type:** Architecture Diagram

**Author:** [You]

**Target Platform:** iOS (SwiftUI, MVVM)

**Project Codename:** Video App / Banana Universe 2.0

⸻

> ⚠️ **Note:** State key names are preliminary and may change during implementation.

```mermaid
flowchart TD

    %% Screens

    A[🏠 HomeView\n(Model Selection Screen)]

    B[🎬 ModelDetailView\n(Video Generation Form)]

    C[🎞️ ResultView\n(Video Preview Screen)]

    %% Navigation Flow

    A -->|User taps model card\n(Passes model_id)| B

    B -->|User taps 'Generate Video'\n(API call → returns job_id)| C

    %% State Flow Details

    subgraph STATE_FLOW["📦 Shared State Flow"]

        direction LR

        P1["prompt: String"]

        S1["settings: {duration, resolution, fps}"]

        J1["job_id: String"]

        V1["video_url: URL"]

    end

    %% Data passing between screens

    A -->|Selected Model → model_id| B

    B -->|Sends: prompt + settings| STATE_FLOW

    STATE_FLOW -->|Returned: job_id| B

    B -->|Navigates with job_id →| C

    STATE_FLOW -->|Fetch video_url via API (Supabase job table)| C

    %% ResultView logic

    C -->|Displays: video_url\nShows: prompt, model_name, credits_used| C

    C -->|Back to Edit →| B

    C -->|Back to Home →| A

    %% External services

    subgraph SUPABASE["🗄️ Supabase Backend"]

        direction TB

        F1["Edge Function: /generate-video"]

        F2["Function: get_video_status(job_id)"]

        DB["Tables:\n- video_jobs\n- quota_log\n- models"]

    end

    %% Backend connections

    B -->|POST → /generate-video\nRequest: {prompt, settings, model_id}| F1

    F1 -->|Response: {job_id}| B

    C -->|GET → get_video_status(job_id)| F2

    F2 -->|Response: {video_url, credits_used, model_name}| C

    F2 --> DB
```

⸻

## 🧠 How to Read It

### Navigation Layer

The flow `HomeView → ModelDetailView → ResultView` shows the screen transitions:

- **HomeView**: User selects a model
- **ModelDetailView**: User configures prompt and settings, then generates video
- **ResultView**: User views the generated video result

### State Layer

Data values passed between screens:

- `prompt: String` - User's video description
- `settings: {duration, resolution, fps}` - Video generation parameters
- `job_id: String` - Unique identifier for the generation job
- `video_url: URL` - Final video file location

### Backend Layer

Supabase Edge Functions handle video generation and job management:

- **`/generate-video`**: Receives generation request, returns `job_id`
- **`get_video_status(job_id)`**: Polls for job completion, returns `video_url` and metadata
- **Database tables**: Store job status, quota usage, and model information

⸻

## ⚠️ Implementation Notes

- State key names (`prompt`, `settings`, `job_id`, `video_url`) are proposed, not final.
- Final naming will be decided when writing the ViewModel and database schema.
- This diagram serves as a reference for understanding data flow and navigation patterns.

⸻
