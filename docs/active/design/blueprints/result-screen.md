⸻

# 🎞️ Result Screen Blueprint – Video App

**Date:** 2025-11-04

**Document Type:** Feature Blueprint

**Author:** [You]

**Target Platform:** iOS (SwiftUI, MVVM)

**Project Codename:** Video App / Banana Universe 2.0

⸻

## 🎯 Purpose

This screen displays the generated video result after a user completes a generation request in ModelDetailView.

It provides video playback, basic information (prompt, model, cost), and key actions like saving, sharing, and regenerating.

⸻

## 🧭 User Journey Overview

```
HomeView
   ↓ (selects model)
ModelDetailView
   ↓ (taps Generate)
ResultView
   ↓ (views, saves, shares, or regenerates)
```

⸻

## 🧱 Layout Overview (Simplified)

```
┌────────────────────────────────────┐
│ ← Back to Edit     [🏠 Home]       │   ← Header
│        🎬 Your Video is Ready!     │
├────────────────────────────────────┤
│ ▷ [Video Player Area]              │
│   - Full width                     │
│   - 16:9 or auto aspect ratio      │
│   - Tap → fullscreen playback      │
├────────────────────────────────────┤
│ 📜 Prompt: "sunset ocean scene"    │
│ 🧠 Model: Runway ML                │
│ 💰 Cost: 4 credits                 │
├────────────────────────────────────┤
│ [📥 Save to Library] [📤 Share]     │
│ [🔁 Regenerate]                    │
├────────────────────────────────────┤
│ (Optional): Tips, download status  │
└────────────────────────────────────┘
```

⸻

## 🧩 Component Architecture (SwiftUI + MVVM)

| Component | Type | Responsibility |
|-----------|------|----------------|
| ResultView | View | Main screen container |
| ResultViewModel | ViewModel | Manages video URL, playback, save/share logic |
| VideoPlayerView | Component | Embedded player (AVPlayer) |
| ActionButtonsRow | Component | Save, Share, Regenerate buttons |
| ResultInfoCard | Component | Displays prompt, model, cost |
| QuotaService | Service | Updates credit usage |
| StorageService | Service | Handles download and saving to Photos |

⸻

## ⚙️ Workflow (Step-by-Step)

1. **Receive Job Result**
   - ModelDetailView passes job_id to ResultView.
   - ResultViewModel calls Supabase endpoint /get-video-status?job_id=....
   - Fetches video_url, prompt, model_name, credits_used.

2. **Display Video**
   - VideoPlayerView(videoURL) uses AVPlayer for playback.
   - Supports inline playback and fullscreen toggle.

3. **Display Metadata**
   - Below video, show prompt, model, and cost summary.
   - Helps user recall what they generated.

4. **User Actions**
   - Save to Library: Downloads video → saves to iOS Photos.
   - Share: Opens native share sheet.
   - Regenerate: Navigates back to ModelDetailView with same prompt prefilled.

5. **Quota Update**
   - Quota already consumed during generation.
   - On "Regenerate," check quota again before new request.

⸻

## 🎨 Design Tokens & Styling

| Element | Token | Example |
|---------|-------|---------|
| Background | DesignTokens.Background.primary() | Neutral tone |
| Header | Typography.title3 | "Your video is ready!" |
| Labels | Typography.subheadline | Prompt, model name, cost |
| Buttons | Button.primary / Button.secondary | Save/Share vs Regenerate |
| Spacing | Spacing.md | 16pt vertical rhythm |
| Corners | CornerRadius.lg | Rounded cards and buttons |
| Shadows | Shadow.level1 | Soft elevation around video player |

⸻

## 🧠 Navigation & Behavior

| Action | Destination |
|--------|-------------|
| ← Back | ModelDetailView (with prompt restored) |
| 🏠 Home | HomeView (main feed) |
| 🔁 Regenerate | Triggers same flow from ModelDetailView |
| 📥 Save / 📤 Share | Local system actions |

### Why Full Page Instead of Modal?

- Full video experience feels cinematic, immersive.
- Avoids modal clutter; better for playback and share sheets.
- Cleaner navigation stack: ModelDetailView → ResultView.

⸻

## 🧱 State Management

| Property | Description |
|----------|-------------|
| @Published var videoURL: URL? | Video file URL (signed Supabase link) |
| @Published var isLoading: Bool | Loading state while fetching video |
| @Published var isSaving: Bool | Save in progress |
| @Published var showShareSheet: Bool | Controls native share sheet |
| @Published var prompt: String | Prompt text (read-only) |
| @Published var modelName: String | Model used |
| @Published var creditsUsed: Int | Credit cost of this generation |

⸻

## 💡 Playback Experience

- Inline player using VideoPlayer(url:) (SwiftUI AVKit wrapper).
- Tap → expands to fullscreen.
- Auto-loop toggle optional in future.
- Audio enabled by default.
- Handles video caching locally for faster replays.

⸻

## 🔄 Error & Loading States

| State | UI Behavior |
|-------|-------------|
| Loading | Show centered spinner + "Fetching video…" text |
| Error | Show friendly message "Video could not be loaded. Try again." |
| Playback error | Retry button + option to open link externally |
| No internet | Cached preview or "Offline mode unavailable" message |

⸻

## 🔮 Future Extensions

| Feature | Description |
|---------|-------------|
| Background download | Continue downloading if app minimized |
| Video trimming | Let user cut before saving |
| Auto-captioning | Generate captions from prompt |
| Favorite system | Star / like generated videos |
| Gallery integration | Show in user's personal library page |
| AI Insights | Automatic tags / title suggestions |

⸻

## ✅ Success Criteria

1. Video loads within 3–5 seconds of job completion.
2. Playback smooth and responsive (AVPlayer-based).
3. Save and Share functions work natively (Photos + ShareSheet).
4. Regenerate keeps same prompt data.
5. No duplicate credit consumption.
6. UI remains lightweight, no modal clutter.

⸻

**End of Document**

Use this blueprint as the implementation reference for the ResultView screen and its ViewModel.

⸻
