⸻

# 🎬 Model Detail Screen Blueprint – Video App

**Date:** 2025-11-04

**Document Type:** Feature Blueprint

**Author:** [You]

**Target Platform:** iOS (SwiftUI, MVVM)

**Project Codename:** Video App / Banana Universe 2.0

⸻

## 🎯 Purpose

This screen allows the user to configure and trigger an AI video generation task.

It provides a clean, minimal interface where the user can enter a prompt, adjust key settings, see credit usage, and start video creation with one clear action.

⸻

## 🧭 User Journey Overview

```
HomeView
   ↓ (User taps model card)
ModelDetailView
   ↓ (User enters prompt + settings)
   ↓ (User taps "Generate Video")
ResultView
```

⸻

## 🧱 Layout Overview (Simplified)

```
┌──────────────────────────────┐
│ ← Back       Model Name      │   ← Header
│           [Credits: 8 / 10]  │
├──────────────────────────────┤
│ 📄 Model Description          │
│ "Generate realistic cinematic │
│  videos from simple text."    │
├──────────────────────────────┤
│ ✏️ Prompt Input               │
│ [ Describe your video idea… ] │
├──────────────────────────────┤
│ ⚙️ Settings (Collapsible)     │
│ Duration: 15s ▾              │
│ Resolution: 720p ▾            │
│ FPS: 30 ▾                     │
├──────────────────────────────┤
│ 💰 Credit Info                │
│ "This generation will cost 4 credits." │
├──────────────────────────────┤
│ [🎥  Generate Video]           │
├──────────────────────────────┤
│ Tip: Keep prompts short & clear. │
└──────────────────────────────┘
```

⸻

## 🧩 Component Architecture (SwiftUI + MVVM)

| Component | Type | Responsibility |
|-----------|------|----------------|
| ModelDetailView | View | Main screen container |
| ModelDetailViewModel | ViewModel | Manages prompt, settings, and generation call |
| PromptInputField | Component | Text input for user prompt |
| SettingsPanel | Component | Optional panel for duration/resolution/FPS |
| CreditInfoBar | Component | Displays cost per generation + remaining credits |
| GenerateButton | Component | Triggers video generation |
| QuotaService | Service | Checks credit availability and consumption |
| ModelService | Service | Fetches model metadata (name, description, cost) |

⸻

## ⚙️ Workflow (Step-by-Step)

1. **User opens ModelDetailView**
   - Fetch model data (name, description, costPerGeneration).
   - Fetch current quota from QuotaService.

2. **User enters prompt**
   - Text stored in @State or bound via ViewModel.

3. **User adjusts settings**
   - Optional — collapsible panel (hidden by default).

4. **Before generation**
   - Check credits: remaining >= cost.
   - If not enough, show alert ("Not enough credits").

5. **On "Generate Video"**
   - Disable inputs, show loading spinner.
   - Call Supabase Edge Function /generate-video.
   - Pass parameters: prompt, duration, resolution, fps, modelId.
   - Receive job_id for polling.

6. **Navigate to ResultView**
   - Once generation starts successfully → push ResultView(job_id).

⸻

## 🎨 Design Tokens & Styling

| Element | Token | Example |
|---------|-------|---------|
| Header | Typography.title3 | Model name |
| Prompt input | DesignTokens.TextField.default | Placeholder style |
| Settings labels | Typography.subheadline | Small gray labels |
| Generate button | Button.primary | Accent color (brand) |
| Credit text | Typography.caption1 | Subtle gray |
| Spacing | Spacing.md (16pt grid) | Consistent layout rhythm |

⸻

## 💰 Credit Display Logic

| Element | Description |
|---------|-------------|
| Header credit count | Shows total remaining (ex: "8 / 10 credits left") |
| Credit Info Box | Shows cost for this generation (ex: "Costs 4 credits") |
| Validation Rule | Disable button if user has insufficient credits |

⸻

## 🧠 UX Principles

- Minimal cognitive load: one task per screen.
- Credits always visible but non-intrusive.
- Settings hidden by default (tap to expand).
- Generate button always fixed and visually dominant.
- Progress state handled via transition to ResultView.

⸻

## 📱 Loading State

- Button transforms into spinner ("Generating…").
- Inputs disabled.
- App polls job status silently.
- Once ready → auto-navigate to ResultView.

⸻

## 🔮 Future Extensions

| Feature | Description |
|---------|-------------|
| Model comparison mode | Switch between providers (Fal, Runway, Pika) |
| Preset templates | One-tap ready prompts ("Nature Scene", "Product Ad") |
| Advanced settings | Add seed, aspect ratio, soundtrack toggle |
| Smart cost estimator | Dynamic credit calculation before generation |

⸻

**End of Document**

Use this as the foundation for implementing ModelDetailView and its ViewModel within the Video App architecture.

⸻
