# Review Code Against Rendio AI Standards

You are auditing code for compliance with Rendio AI's architecture, design, and security standards.

## Instructions

Ask the user:
1. **File path** to review, or
2. **Paste code** directly

Then perform a comprehensive audit:

### 1. Architecture Compliance
Check:
- ✅ MVVM separation (no business logic in Views)
- ✅ Unidirectional data flow (View → ViewModel → Service)
- ✅ Proper folder structure (`Features/`, `Core/`, `Shared/`)
- ✅ No cross-feature imports (only `Shared/` allowed)
- ✅ Dependency injection in ViewModels

### 2. Safety & Code Quality
Verify:
- ❌ No force unwraps (`!`)
- ❌ No implicitly unwrapped optionals (`var foo: String!`)
- ✅ Safe unwrapping (`guard let`, `if let`, `??`)
- ✅ Proper error handling (throws `AppError`, not generic `Error`)
- ✅ `async/await` used (no completion handlers)
- ✅ `@MainActor` on ViewModels and UI-updating functions

### 3. Design System Compliance
Check:
- ✅ Semantic color names (`Color("BrandPrimary")`)
- ✅ Typography via modifiers (`.headline`, `.body`)
- ✅ 8pt grid spacing (16, 24, 32, not 15, 23)
- ✅ Standard corner radius (12pt cards, 8pt buttons)
- ✅ Consistent shadows (`.black.opacity(0.1)`, radius 4, y: 2)

### 4. i18n & Localization
Verify:
- ✅ No hardcoded strings for user-facing text
- ✅ All text uses localization keys
- ✅ Error messages via `ErrorMapper`

### 5. Security
Check:
- ✅ No API keys in client code
- ✅ Sensitive data in Keychain (not UserDefaults)
- ✅ RLS policies respected (no direct table access)
- ✅ DeviceCheck for anonymous users

### 6. Naming Conventions
Verify:
- ✅ PascalCase for types (`HomeView`, `VideoService`)
- ✅ camelCase for variables/functions (`remainingCredits`, `generateVideo()`)
- ✅ File names match primary type

### 7. State Management
Check:
- ✅ Correct use of `@State`, `@StateObject`, `@ObservedObject`
- ✅ `@Published` in ViewModels only
- ✅ No excessive state duplication

## Output Format

Provide:
1. **✅ Compliant Items** (what's done correctly)
2. **⚠️ Warnings** (not critical but could be improved)
3. **❌ Issues** (must be fixed)
4. **Refactored Code** (if issues found)
5. **Explanation** of each change

Be specific with line numbers and exact fixes needed.
