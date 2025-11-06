⸻

# 🎬 Project Overview — Rendio AI

**Version:** 1.0.0

**Platform:** iOS (SwiftUI + Supabase + Fal AI Veo 3.1)

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🎯 Purpose

Rendio AI is a lightweight, Apple-native creative playground where users can generate short, realistic videos from text prompts — for fun, memes, and visual experiments.

The app focuses on simplicity: three taps and your video is ready.

No technical knowledge, no setup, just instant visual creativity powered by AI.

⸻

## 👥 Target Audience

| Group | Description | Motivation |
|-------|-------------|------------|
| Gen Z & young creators | Students, meme lovers, TikTok/Instagram users | Make fun, weird, or stylish short clips instantly |
| AI-curious users | People who experiment with AI for entertainment | Try text-to-video casually, no pro tools needed |
| Casual users | Everyday iPhone users who enjoy generative tech | Enjoy short-form AI content creation |

**Not targeting:** professional video editors, ad agencies, or film studios.

⸻

## 🧩 Core Modules

| Module | Description | Key Feature |
|--------|-------------|-------------|
| Home Screen | Browse video models (e.g., text-to-video, image-to-video) | Quick preview + category carousel |
| Model Detail Screen | Configure prompts and settings | Simplified form-based input |
| Result Screen | Watch, download, or share generated videos | Built-in playback & share menu |
| History Screen | View past generations (7-day retention) | Tap to reopen ResultView |
| Profile Screen | Manage credits, theme, and language | Dropdowns for Light/Dark mode & language |

⸻

## ⚙️ Technology Stack

| Layer | Tool / Service | Purpose |
|-------|----------------|---------|
| Frontend | SwiftUI (iOS 17+) | Apple-native UI & Haptic feedback |
| Backend | Supabase | Auth, storage, RLS-protected data |
| AI Engine | Fal AI Veo 3.1 | Text-to-Video generation |
| Monitoring | Telegram Bot | Cron job summaries & error alerts |
| Storage Policy | Supabase Private Buckets | 7-day auto-cleanup |
| Design System | Apple HIG + DesignTokens | Smooth animations, accessibility, clarity |

⸻

## 💰 Business Model

- **Freemium:**
  - First-time users get free credits (10 default).
  - When credits run out → optional Apple Sign-in + in-app purchase.
  - No subscription pressure.
  - Data minimalism: Only store what's necessary (device ID, job logs).

⸻

## 🔐 Compliance & Safety

- Apple App Store compliant (Privacy + Content guidelines).
- Uses DeviceCheck API for anonymous device verification.
- No personal data collection without Apple Sign-in.
- Fal AI Veo 3.1 handles content safety via model-side filters.
- Fully GDPR-ready — no user profiling, no ads, no tracking SDKs.

⸻

## 🎨 Design Philosophy

**"Minimal friction, maximum fun."**

- Three-step flow: Select model → Enter prompt → Generate
- Inspired by Apple HIG's "Delight through simplicity."
- Subtle haptics, blurred surfaces, and minimal color palette.
- Full Dark/Light mode support.
- SwiftUI-native transitions, no third-party UI kits.

⸻

## 🗺️ Future Roadmap (High-Level Summary)

| Phase | Goal | Focus |
|-------|------|-------|
| Phase 1 (MVP) | Text-to-Video (Veo 3.1) | Core screens, credit system |
| Phase 2 | Image-to-Video + Model Expansion | New model integrations |
| Phase 3 | Web version | Cross-platform access |
| Phase 4 | Premium Tiers | Subscription packs, longer durations |

⸻

## 🧭 Key Strengths

- Native Swift performance & offline-first UX
- 7-day auto cleanup (low-cost maintenance)
- Minimal permissions & privacy transparency
- Haptic feedback + smooth onboarding
- Clear monetization via credits

⸻

## ✅ Summary

Rendio AI is a fast, privacy-friendly, creative tool for generating AI videos.

Built for iPhone, designed for fun, and powered by the latest AI video models.

A product that feels Apple, works instantly, and stays ethical.

⸻
