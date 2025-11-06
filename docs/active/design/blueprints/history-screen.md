⸻

# 🎞️ History Screen Blueprint – Video App

**Date:** 2025-11-04

**Author:** [You]

**Purpose:**

Display all generated videos from the user (guest or logged-in), fetched from the video_jobs table, grouped by creation date.

Provide quick playback, sharing, and status visibility for each generation job.

⸻

## 🧭 User Flow Overview

```
HomeView
   ↓
Profile / Navigation Tab
   ↓
HistoryView (List of Generated Videos)
   ↓
ResultView (if user opens specific video)
```

⸻

## 🧱 Layout Overview (Simplified Skeletal Wireframe)

```
┌─────────────────────────────────────────────┐
│ ← Back             🎞️ History              │  ← Header
├─────────────────────────────────────────────┤
│ 🔍 [Search your videos…]                    │  ← Optional search bar
├─────────────────────────────────────────────┤
│ 📅 November 2025                            │  ← Section header (date)
│ ┌─────────────────────────────────────────┐ │
│ │ [Thumbnail]  Prompt: "sunset ocean…"     │ │
│ │ Model: RunwayML • Duration: 15s          │ │
│ │ Status: ✅ Completed                      │ │
│ │ [▶︎ Play] [📥 Download] [📤 Share]        │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ [Thumbnail]  Prompt: "neon city lights"  │ │
│ │ Model: Pika • Duration: 10s              │ │
│ │ Status: ⚙️ Processing…                   │ │
│ │ [⏱ Wait]                                │ │
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ 📅 October 2025                            │
│ ┌─────────────────────────────────────────┐ │
│ │ [Thumbnail]  Prompt: "forest waterfall"  │ │
│ │ Model: FalAI • Duration: 20s             │ │
│ │ Status: ❌ Failed                        │ │
│ │ [🔁 Retry] [🗑 Delete]                   │ │
│ └─────────────────────────────────────────┘ │
│                (Scrollable List)            │
└─────────────────────────────────────────────┘
```

⸻

## 🧩 Component Architecture

| Component | Type | Description |
|-----------|------|-------------|
| HistoryView | View | Main container for all history items |
| HistoryViewModel | ViewModel | Fetches and groups jobs by date |
| HistorySection | Component | Displays jobs created on the same date |
| HistoryCard | Component | Displays single video job with actions |
| HistoryEmptyState | Component | Shows message when user has no history |
| SupabaseService | Service | Fetches video_jobs for given user/device |

⸻

## ⚙️ Backend Requirements

**Endpoint:**

```
GET /get-video-jobs?user_id={id}
```

or

```
GET /get-video-jobs?device_id={uuid}
```

for guest users.

**Note:** Supabase Edge Functions use kebab-case names without `/api` prefix (e.g., `supabase/functions/get-video-jobs/index.ts`).

**Response example:**

```json
[
  {
    "job_id": "a1b2c3",
    "prompt": "sunset ocean scene",
    "model_name": "RunwayML",
    "video_url": "https://cdn.supabase.com/video123.mp4",
    "status": "completed",
    "duration": 15,
    "created_at": "2025-11-03T18:10:24Z"
  },
  {
    "job_id": "b2c3d4",
    "prompt": "neon city lights",
    "model_name": "Pika",
    "status": "processing",
    "created_at": "2025-11-04T10:01:45Z"
  }
]
```

⸻

## 🧠 UI Behavior by Status

| Status | Behavior | Actions |
|--------|----------|---------|
| completed | Thumbnail and play available | [▶︎ Play] [📥 Download] [📤 Share] |
| processing | Spinner / disabled actions | [⏱ Wait] |
| failed | Error icon and message | [🔁 Retry] [🗑 Delete] |

⸻

## 🎨 Design Tokens & Styling

| Element | Token | Example |
|---------|-------|---------|
| Header | Typography.title3 | "History" |
| Section headers | Typography.subheadline.bold | Date labels |
| Card | Surface.secondary | Subtle background |
| Buttons | Button.secondary / Button.tertiary | Share/Retry actions |
| Status icons | Semantic.success, warning, error | Status colors |
| Spacing | Spacing.md | Vertical list rhythm |
| Scroll behavior | ScrollView with bounce + pull-to-refresh | Standard iOS |

⸻

## 🧱 Data Handling

| Source | Field | Use |
|--------|-------|-----|
| video_jobs | job_id | Navigate to ResultView |
| video_jobs | prompt | Display prompt snippet |
| video_jobs | model_name | Display provider |
| video_jobs | status | UI state |
| video_jobs | video_url | Playback or download |
| video_jobs | created_at | Date grouping key |

⸻

## 🧩 ViewModel State (Swift)

```swift
@Published var historySections: [HistorySectionModel] = []
@Published var isLoading: Bool = false
@Published var errorMessage: String?
@Published var searchQuery: String = ""

struct HistorySectionModel {
    let date: String
    let items: [VideoJob]
}
```

**Fetch flow:**

```swift
func fetchHistory(for userId: String?) {
    isLoading = true
    SupabaseService.shared.getVideoJobs(userId: userId) { jobs in
        let grouped = Dictionary(grouping: jobs) {
            $0.created_at.formatted("MMMM yyyy")
        }
        self.historySections = grouped.map { HistorySectionModel(date: $0.key, items: $0.value) }
        self.isLoading = false
    }
}
```

⸻

## 📱 Interactions

| Action | Effect |
|--------|--------|
| Tap on card | Navigates to ResultView(job_id) |

> When a user taps on a HistoryCard, the app navigates to the existing ResultView screen.  
> The ResultView opens as a full page for video playback, reusing the same layout and logic defined in the Result Screen Blueprint.  
> No new modal or viewer component is required — this maintains consistent video experience across the app.

| Swipe left | Shows delete option |
| Pull down | Refreshes list |
| Search | Filters by prompt keyword |
| Long press | Copy prompt text |

⸻

## 🔒 Access Rules

| Case | Behavior |
|------|----------|
| Guest user | Filter by device_id |
| Logged-in user | Filter by user_id |
| No results | Show HistoryEmptyState: "No videos yet. Generate your first video!" |

⸻

## ✅ Success Criteria

1. List loads in <2s for up to 100 jobs.
2. Correct date grouping & visual order (newest first).
3. Smooth scrolling & responsive card actions.
4. Completed jobs playable via ResultView.
5. Consistent design tokens with other screens.

⸻

**End of Document**

Attach to `/design/blueprints/` as the specification for HistoryView implementation.

⸻
