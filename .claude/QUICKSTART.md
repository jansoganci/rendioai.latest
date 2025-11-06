# Claude Code Quick Start — Rendio AI

Welcome! Your Rendio AI project is now configured with custom Claude Code commands for consistent, high-quality development.

---

## ✅ What Was Created

```
.claude/
├── project-instructions.md          ← Auto-loaded context (every session)
├── README.md                        ← Full documentation
├── QUICKSTART.md                    ← This file
└── commands/
    ├── /new-feature                 ← Scaffold MVVM feature
    ├── /new-screen                  ← Implement from blueprint
    ├── /new-component               ← Create UI component
    ├── /review-code                 ← Audit code quality
    ├── /check-design                ← Verify design compliance
    ├── /api-endpoint                ← Create Edge Function
    ├── /new-model                   ← Data model + RLS
    └── /error-handler               ← Add error type
```

---

## 🚀 Quick Examples

### Example 1: Create a New Feature
```
You: /new-feature
Claude: What's the feature name?
You: Favorites
Claude: Brief description?
You: Allow users to save favorite models for quick access
```

**Result:** Complete MVVM implementation with View, ViewModel, and Components.

---

### Example 2: Implement Home Screen
```
You: /new-screen
Claude: Which blueprint?
You: Home Screen
```

**Result:** Full HomeView with carousel, model grid, search bar, and navigation.

---

### Example 3: Create a Button Component
```
You: /new-component
Claude: Component name?
You: CreditBadge
Claude: Purpose?
You: Display credit count with icon in top-right corner
```

**Result:** Reusable SwiftUI component with design tokens and preview.

---

### Example 4: Review Your Code
```
You: /review-code
Claude: File path?
You: Features/Home/HomeView.swift
```

**Result:** Detailed audit with issues, warnings, and refactored code.

---

### Example 5: Check Design Compliance
```
You: /check-design
Claude: Component to check?
You: Features/Profile/ProfileView.swift
```

**Result:** Design system compliance report with fixes.

---

## 🎯 What Happens Automatically

Every session:
- ✅ **Project context loads automatically** from `project-instructions.md`
- ✅ Claude knows the architecture (MVVM, folder structure)
- ✅ Claude applies design tokens (colors, typography, spacing)
- ✅ Claude follows security rules (RLS, DeviceCheck, no force unwraps)
- ✅ Claude uses i18n for all user-facing text
- ✅ Claude structures code according to blueprints

---

## 💡 Common Workflows

### Starting a New Screen
1. Run `/new-screen`
2. Choose blueprint (Home, ModelDetail, Result, etc.)
3. Review generated code
4. Run `/check-design` to verify compliance
5. Integrate into navigation

### Adding Backend API
1. Run `/api-endpoint`
2. Specify name, method, purpose
3. Get Edge Function + RLS policies
4. Get Swift client code
5. Test with provided examples

### Creating Data Model
1. Run `/new-model`
2. Define properties and relationships
3. Get Swift model + SQL migration + RLS
4. Get service methods
5. Deploy migration to Supabase

### Quality Assurance
Before committing:
1. Run `/review-code` on modified files
2. Run `/check-design` on UI components
3. Fix any issues flagged
4. Verify tests pass

---

## 🔍 Consistency Guarantees

All commands ensure:
| Rule | What It Prevents |
|------|------------------|
| No force unwraps | Runtime crashes |
| Design tokens | Visual inconsistencies |
| i18n keys | Hardcoded text |
| MVVM separation | Business logic in Views |
| Dependency injection | Tight coupling |
| RLS policies | Data leaks |
| Error handling | Poor UX on failures |

---

## 📖 Need Help?

- **Full docs:** `.claude/README.md`
- **Project context:** `.claude/project-instructions.md`
- **Design system:** `design/design-rulebook.md`
- **Architecture:** `design/general-rulebook.md`
- **Blueprints:** `design/blueprints/`

---

## 🎉 You're Ready!

Try your first command:
```
/new-component
```

Claude will guide you through creating a perfect, production-ready component that follows all Rendio AI standards.

**Every command = Consistent quality + Time saved + Zero manual setup**

---

Built for Rendio AI v1.0.0 🚀
