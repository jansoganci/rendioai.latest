# 🎨 UI Guidelines Context — Rendio AI

**Purpose:** Quick reference for SwiftUI code generation — design tokens, colors, typography, components.

**Sources:** `design/design-rulebook.md`, `design/general-rulebook.md`

---

## 🎨 Color System

**Semantic Colors** (always use these, never hardcode hex):

```swift
Color("BrandPrimary")      // Cosmic Purple (#6B4FFF light, #8B7CFF dark)
Color("Accent")            // Electric Pink (#FF3D71 light, #FF6B6B dark)
Color("SurfaceBase")       // Background
Color("SurfaceCard")       // Card background
Color("TextPrimary")       // Main text
Color("TextSecondary")     // Subtle text
Color("AccentWarning")     // Amber
Color("AccentSuccess")     // Green
Color("AccentError")        // Red
```

**Usage:**
- Maintain contrast ≥ 4.5:1 for text
- Gradients only for hero/premium sections
- Avoid pure black backgrounds (use charcoal in dark mode)

---

## ✍️ Typography

**SF Pro only** (system default):

| Element | SwiftUI Style | Size | Weight | Use |
|---------|---------------|------|--------|-----|
| Page Title | `.largeTitle` | 34pt | Bold | Main headers |
| Section Title | `.title2` | 22pt | Semibold | Screen sections |
| Headline | `.headline` | 17pt | Semibold | Subsections |
| Body | `.body` | 17pt | Regular | General text |
| Caption | `.caption` | 12pt | Regular | Metadata |

**Variants:**
- `.rounded` → credits, badges
- `.monospaced` → technical IDs
- Limit to 3 font weights max

---

## 📐 Layout & Spacing

**8pt grid system:**
- Default padding: 16pt (content), 24pt (sections)
- Vertical rhythm: `.spacing(12)` for stacks
- Safe area: `.safeAreaInset()` for navigation

**Visual Style:**
- Rounded corners: 12pt (cards), 8pt (buttons)
- Shadows: `shadow(color: .black.opacity(0.1), radius: 4, y: 2)`
- Blur: `.thinMaterial` for overlays only

---

## 🧩 Reusable Components

**Location:** `/Shared/Components/`

**Example: PrimaryButton**
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color("BrandPrimary"))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(!isEnabled || isLoading)
    }
}
```

**ViewModifiers:**
```swift
// CardStyle
VStack { Text("Content") }
    .cardStyle()  // .padding(16) + .background(Color("SurfaceCard")) + .cornerRadius(12) + shadow
```

**Rules:**
- Extract component if used ≥2 times
- Stateless by default (data via parameters)
- Use design tokens (colors, spacing)

---

## ⚡ Animation

**Principles:** "Purposeful, not playful"

```swift
// Micro-transitions: 0.2–0.3s
// Screen transitions: 0.3–0.4s
withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
    showResult = true
}

// Success: interpolatingSpring(stiffness: 200, damping: 25)
// Haptic: .success on video completion
```

**Respect "Reduce Motion"** → disable nonessential animations automatically.

---

## ⏳ Loading & Feedback

**Loading:**
- `ProgressView()` for immediate feedback
- Shimmer skeletons for content loading
- Overlay loaders, never full-screen blocking

**Toasts & Banners:**
- Success: Green, 3s, light haptic
- Warning: Amber, 3s, medium haptic (low credits)
- Error: Red, 4s, error haptic
- Info: Blue, 2s, none
- Auto-dismiss, max 3 concurrent

---

## 📚 References

- Full design system: `design/design-rulebook.md`
- Component patterns: `design/general-rulebook.md` (Section 4)
