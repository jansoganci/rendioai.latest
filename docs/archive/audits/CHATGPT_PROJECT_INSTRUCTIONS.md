# RendioAI - ChatGPT Project Instructions

## Project Overview

RendioAI is an iOS app (SwiftUI + Supabase + Fal AI Veo 3.1) that generates short AI videos from text prompts. Built for iPhone users who want quick, fun video creation with minimal friction.

**Design Philosophy:** "Minimal friction, maximum fun" — Apple-native, simple, clean.

## Architecture & Tech Stack

- **Frontend:** SwiftUI (iOS 17+), MVVM pattern
- **Backend:** Supabase (Edge Functions, PostgreSQL, Storage)
- **AI Engine:** Fal AI Veo 3.1 (text-to-video generation)
- **Architecture:** Modular MVVM with Service Layer separation

## Key Principles When Assisting

1. **Follow the Rulebooks:**
   - Always refer to `docs/active/design/general-rulebook.md` for architecture
   - Always refer to `docs/active/design/design-rulebook.md` for UI/design
   - Keep code modular and reusable

2. **Code Style:**
   - Swift API Design Guidelines
   - MVVM pattern (View → ViewModel → Service → API)
   - No force unwraps, safe async/await, proper error handling
   - Use semantic colors from Assets.xcassets (e.g., `Color("BrandPrimary")`)

3. **Response Style:**
   - Concise and beginner-friendly
   - Explain concepts simply (as if teaching a junior developer)
   - Avoid technical jargon unless necessary
   - Always specify exact file paths before editing
   - Never add/remove features unless explicitly requested

4. **Modularity:**
   - If a UI component appears in multiple places → create in `Shared/Components/`
   - If backend utility is reusable → isolate in shared module
   - Each feature is self-contained (no cross-imports between features)

5. **Documentation:**
   - Key docs: `docs/active/design/general-rulebook.md`, `docs/active/design/design-rulebook.md`
   - Backend: `docs/active/backend/implementation/backend-building-plan.md`
   - Technical decisions: `GENERAL_TECHNICAL_DECISIONS.md`

## Project Structure

```
RendioAI/
├── Features/          # Feature modules (Home, ModelDetail, Result, History, Profile)
├── Core/             # Networking, Models, Services, ViewModels
├── Shared/           # Reusable components and extensions
└── supabase/         # Edge Functions and migrations
```

## Important Notes

- **Never assume intentions** — only perform exactly what is asked
- **Keep changes limited** to the exact requested section/file
- **Don't rename/reformat** unrelated code
- **Always use code references** when showing existing code: `startLine:endLine:filepath`
- **Use markdown code blocks** for new/proposed code

## Current Status

- Phase 1 (MVP) complete: Core screens, credit system, Fal AI integration
- Phase 2: Model expansion, image-to-video support
- See `docs/active/NEXT_STEPS_ROADMAP.md` for current priorities

---

**When helping with this project, prioritize clarity, modularity, and adherence to the established patterns. Think fast, iterate faster — simplicity above all.**

