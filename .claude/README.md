# Rendio AI – Claude Code Configuration

This directory contains custom configuration for Claude Code to ensure consistent, high-quality development across all sessions.

## 📁 Structure

```
.claude/
├── project-instructions.md     # Auto-loaded project context (loaded every session)
├── commands/                   # Custom slash commands
│   ├── new-feature.md         # Scaffold MVVM feature module
│   ├── new-screen.md          # Create screen from blueprint
│   ├── new-component.md       # Generate reusable UI component
│   ├── review-code.md         # Audit code quality
│   ├── check-design.md        # Verify design compliance
│   ├── api-endpoint.md        # Create Supabase Edge Function
│   ├── new-model.md           # Create data model + RLS
│   └── error-handler.md       # Add error type to system
├── templates/                  # Code templates (optional)
└── README.md                  # This file
```

---

## 🚀 Available Commands

### `/new-feature`
**Creates a complete MVVM feature module**

Use when: Adding a new feature like Favorites, Search, Notifications, etc.

Example:
```
/new-feature
```
Claude will ask for:
- Feature name
- Description
- Required services

Outputs:
- `Features/{Name}/{Name}View.swift`
- `Features/{Name}/{Name}ViewModel.swift`
- `Features/{Name}/Components/` folder
- Integration instructions

---

### `/new-screen`
**Implements a screen from design blueprints**

Use when: Building one of the core screens (Home, ModelDetail, Result, History, Profile)

Example:
```
/new-screen
```
Claude will ask:
- Which blueprint to implement
- Any customizations needed

Outputs:
- Complete View implementation
- ViewModel with state management
- Component files
- Navigation setup

---

### `/new-component`
**Creates a reusable UI component**

Use when: Building buttons, cards, modals, or any reusable UI element

Example:
```
/new-component
```
Claude will ask:
- Component name
- Props/parameters
- Where it's used

Outputs:
- SwiftUI component with design tokens
- Preview provider
- Usage examples
- Correct folder placement

---

### `/review-code`
**Audits code against Rendio AI standards**

Use when: Reviewing existing code or before committing

Example:
```
/review-code
```
Claude will ask for:
- File path or code to review

Checks:
- ✅ MVVM architecture
- ✅ Safety (no force unwraps)
- ✅ Design tokens
- ✅ i18n compliance
- ✅ Error handling
- ✅ Naming conventions

Outputs:
- Issues found
- Refactored code
- Specific fixes

---

### `/check-design`
**Verifies design system compliance**

Use when: Ensuring UI matches design system and Apple HIG

Example:
```
/check-design
```
Claude will ask for:
- View/Component to check
- Screen context

Checks:
- ✅ Semantic colors
- ✅ Typography hierarchy
- ✅ 8pt grid spacing
- ✅ Corner radius standards
- ✅ Animation timing
- ✅ Blueprint alignment

Outputs:
- Compliance report
- Design violations
- Refactored code with correct tokens

---

### `/api-endpoint`
**Creates a Supabase Edge Function**

Use when: Adding new backend API endpoints

Example:
```
/api-endpoint
```
Claude will ask for:
- Endpoint name
- HTTP method
- Purpose
- Input/output

Outputs:
- Complete Edge Function code
- README with examples
- RLS policies
- Swift client code

---

### `/new-model`
**Creates data model with RLS policies**

Use when: Adding new database tables and Swift models

Example:
```
/new-model
```
Claude will ask for:
- Model name
- Properties
- Relationships
- Access rules

Outputs:
- Swift Codable model
- SQL migration
- RLS policies
- Service methods
- Usage examples

---

### `/error-handler`
**Adds error type to centralized system**

Use when: Handling new error scenarios

Example:
```
/error-handler
```
Claude will ask for:
- Error scenario
- Category
- User message
- Recovery action

Outputs:
- Updated AppError enum
- i18n keys (EN + TR)
- ErrorMapper updates
- Service/ViewModel examples

---

## 🧠 Project Context

The `project-instructions.md` file contains:
- Project identity and architecture
- MVVM patterns and folder structure
- Design system (colors, typography, spacing)
- Coding standards and safety rules
- Backend integration patterns
- Security and RLS policies
- Error handling system
- Screen blueprints summary

**This context is automatically loaded in every Claude Code session.**

---

## ✅ Quality Standards

Every command ensures:
- ✅ No force unwraps (`!`)
- ✅ Design tokens used (no hardcoded colors)
- ✅ i18n keys for user text
- ✅ Proper error handling
- ✅ Dependency injection
- ✅ File naming conventions
- ✅ MVVM separation
- ✅ RLS security

---

## 🔧 Customization

To add new commands:
1. Create `.claude/commands/{command-name}.md`
2. Define the prompt and instructions
3. Use in session with `/{command-name}`

To modify context:
1. Edit `.claude/project-instructions.md`
2. Changes apply to all future sessions

---

## 📚 References

For detailed documentation, see:
- `design/` — UI/UX blueprints
- `docs/` — Project overview and roadmap
- `README.md` — Setup instructions

---

**Built for Rendio AI v1.0.0 — Ensuring consistency, quality, and speed across all development sessions.**
