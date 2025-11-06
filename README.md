# Rendio AI

**Version:** 1.0.0  
**Platform:** iOS (SwiftUI + Supabase + Fal AI Veo 3.1)

A minimal, fun AI video generator app for iPhone. Create short videos from text prompts in just a few taps.

---

## 🎬 Overview

Rendio AI is a lightweight, Apple-native creative playground where users can generate short, realistic videos from text prompts. Built with SwiftUI, powered by Fal AI Veo 3.1, and designed with simplicity in mind — three taps and your video is ready.

**Design Philosophy:** Minimal friction, maximum fun.

---

## ✨ Key Features

- **Text-to-Video Generation** — Powered by Fal AI Veo 3.1
- **Credit System** — Freemium model with DeviceCheck verification
- **Result Viewer** — Built-in playback with download and share functionality
- **7-Day History** — View past generations with automatic cleanup
- **Privacy-First** — GDPR-ready, no tracking SDKs, minimal data collection
- **Apple Sign-in** — Optional authentication (Phase 4)
- **In-App Purchases** — Credit bundles for extended usage (Phase 4)

---

## 🏗️ Architecture

### Frontend
- **SwiftUI** (iOS 17+)
- **MVVM** architecture pattern
- **Native iOS components** — No third-party UI kits
- **Design Tokens** — Consistent styling and theming

### Backend
- **Supabase** — Auth, storage, and database
- **Row-Level Security (RLS)** — User data isolation
- **Edge Functions** — API layer for video generation
- **Private Storage Buckets** — Secure video file storage

### AI Integration
- **Fal AI Veo 3.1** — Text-to-video generation
- **Adapter Pattern** — Provider-agnostic model integration
- **Backend-only API keys** — No client-side exposure

---

## 📦 Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Swift 5.9+
- Supabase project with configured Edge Functions

### Environment Variables

Create a `.xcconfig` file or use environment variables:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
API_BASE_URL=https://your-project.supabase.co/functions/v1
```

### Backend Configuration

1. Set up Supabase tables (see `design/database/data-schema-final.md`)
2. Configure Edge Functions (see `design/backend/api-layer-blueprint.md`)
3. Set environment variables for Fal AI API key (server-side only)
4. Enable DeviceCheck verification (see `design/security/anonymous-devicecheck-system.md`)

### Build & Run

```bash
# Open project
open RendioAI.xcodeproj

# Build for simulator
⌘ + B

# Run on device
⌘ + R
```

---

## 📚 Documentation

Comprehensive project documentation is available in the `docs/` and `design/` directories:

- **[Project Overview](docs/ProjectOverview.md)** — Product vision, target audience, and core modules
- **[Roadmap](docs/Roadmap.md)** — Development phases and milestones
- **[Security Policies](design/security/security-policies.md)** — RLS, privacy, and data protection
- **[Onboarding Flow](design/blueprints/onboarding-flow.md)** — DeviceCheck and credit assignment
- **[Error Handling](design/operations/error-handling-guide.md)** — Unified error system and i18n
- **[Data Schema](design/database/data-schema-final.md)** — Database structure
- **[API Layer](design/backend/api-layer-blueprint.md)** — Supabase Edge Functions specification

---

## 🔐 Privacy & Compliance

- **Apple App Store Compliant** — Follows HIG and Privacy guidelines
- **DeviceCheck Integration** — Anonymous device verification
- **GDPR Ready** — No user profiling, no ads, no tracking SDKs
- **Row-Level Security** — User data isolation at database level
- **7-Day Auto-Cleanup** — Automatic deletion of old videos and history

See `design/security/security-policies.md` for detailed security architecture.

---

## 🗺️ Roadmap

### Phase 1 — MVP Launch (Q1 2026)
Core screens, Fal AI integration, credit system, TestFlight release

### Phase 2 — Model Expansion (Q2 2026)
Image-to-Video, dynamic pricing, catalog enhancements

### Phase 3 — Web Dashboard (Q3 2026)
Cross-platform web interface with shared database

### Phase 4 — Premium Tier (Q4 2026)
Monetization, IAP, credit bundles, referral system

### Phase 5 — AI Assistant (2027)
Chat-style prompt assistant, personalized recommendations

See `docs/Roadmap.md` for detailed milestones and success metrics.

---

## ⚙️ Development Notes

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices (ViewModifiers, State management)
- MVVM pattern for business logic separation

### Testing
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- TestFlight for beta testing

### Error Handling
- Centralized error mapping via `ErrorMapper`
- All user-facing messages via i18n keys
- No hardcoded error strings

See `design/operations/error-handling-guide.md` for error handling patterns.

---

## 📄 License

[Add your license here]

---

## 👤 Author

[Your Name]

---

## 🙏 Credits

- **Fal AI** — Video generation engine (Veo 3.1)
- **Supabase** — Backend infrastructure
- **Apple** — SwiftUI and iOS SDKs

---

Built with ❤️ for iPhone users who love creative experimentation.
