# 🤖 AI Context Documents — Rendio AI

**Purpose:** Internal context summaries for Cursor AI to ensure consistent code generation, architecture alignment, and design compliance.

---

## 📚 Document Overview

These concise context files (300–400 words each) extract actionable rules from the full project documentation:

| Document | Purpose | Key Topics |
|----------|---------|------------|
| `_context-architecture.md` | MVVM patterns, folder structure, naming conventions | Folder layout, View/ViewModel/Service separation, naming rules |
| `_context-ui-guidelines.md` | Design system, colors, typography, components | Semantic colors, SF Pro typography, reusable components, animations |
| `_context-backend-apis.md` | API endpoints, adapter pattern, response mapping | Supabase Edge Functions, provider adapters, unified models |
| `_context-security.md` | RLS policies, DeviceCheck, privacy | Row-level security, anonymous device verification, data privacy |
| `_context-error-handling.md` | Error categories, mapping, i18n, UI presentation | Error propagation, localization, toast/banner patterns |
| `_context-testing.md` | Testing patterns, dependency injection, scalability | Unit tests, mocking, adapter pattern, future-proofing |

---

## 🎯 Usage in Cursor

These documents enable Cursor AI to:

1. **Generate SwiftUI Views** → Follow design system (`_context-ui-guidelines.md`)
2. **Create ViewModels** → Follow MVVM pattern (`_context-architecture.md`)
3. **Implement API Services** → Use adapter pattern (`_context-backend-apis.md`)
4. **Add Error Handling** → Use unified error system (`_context-error-handling.md`)
5. **Implement Security** → Enforce RLS and DeviceCheck (`_context-security.md`)
6. **Write Tests** → Follow dependency injection patterns (`_context-testing.md`)

---

## 📖 Full Documentation

These context files are **summaries**. For complete details, refer to:

- `design/general-rulebook.md` — Architecture, coding conventions, folder structure
- `design/design-rulebook.md` — Complete design system (colors, typography, layout)
- `design/backend/api-layer-blueprint.md` — Full API specification
- `design/security/security-policies.md` — Complete security architecture
- `design/operations/error-handling-guide.md` — Full error handling guide

---

## 🔄 Maintenance

These context files should be updated when:
- New design tokens are added
- Architecture patterns change
- API endpoints are modified
- Security policies are updated

**Keep them concise (300–400 words max)** — they're quick references, not replacements for full documentation.

---

**Last Updated:** 2025-11-05
