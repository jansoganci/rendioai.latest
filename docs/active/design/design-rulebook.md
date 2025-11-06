⸻

# 🎨 Rendio AI — Design Rulebook

**Version:** 1.0.0

**Platform:** iOS 17+ (SwiftUI)

**Compliance:** Fully aligned with Apple Human Interface Guidelines (HIG 2025)

⸻

## 🧭 Design Philosophy

Rendio AI is a minimal, Apple-native video generation app built for creativity and speed.

**Visual language:** "Minimal friction, maximum fun."

The design combines cosmic purple tones, smooth transitions, and clean typography to feel modern and light — never cluttered, never loud.

⸻

## 🎨 Color System

### 🧩 Semantic Color Naming

All colors are defined in `Assets.xcassets` using Light/Dark variants and referenced semantically:

- `Color("BrandPrimary")`
- `Color("SurfaceBase")`
- `Color("SurfaceCard")`
- `Color("TextPrimary")`
- `Color("TextSecondary")`
- `Color("AccentWarning")`
- `Color("AccentSuccess")`

### 🌈 Palette (Light Mode)

| Role | Color | HEX |
|------|-------|-----|
| Brand Primary | Cosmic Purple | `#6B4FFF` |
| Accent | Electric Pink | `#FF3D71` |
| Background | Off White | `#F8FAFC` |
| Surface (Card) | Neutral Gray | `#F1F5F9` |
| Text Primary | Deep Gray | `#1E1E1E` |
| Text Secondary | Mid Gray | `#525252` |
| Warning | Amber | `#F59E0B` |
| Error | Red | `#EF4444` |
| Success | Green | `#10B981` |

### 🌙 Palette (Dark Mode)

| Role | Color | HEX |
|------|-------|-----|
| Brand Primary | Soft Violet | `#8B7CFF` |
| Accent | Coral Glow | `#FF6B6B` |
| Background | Deep Charcoal | `#0D0D0F` |
| Surface (Card) | Gray-900 | `#1E293B` |
| Text Primary | White | `#FFFFFF` |
| Text Secondary | Cool Gray | `#9CA3AF` |
| Warning | Warm Amber | `#FBBF24` |
| Error | Soft Red | `#F87171` |
| Success | Mint Green | `#34D399` |

### 💡 Usage Guidelines

- Maintain contrast ≥ 4.5:1 for text and essential UI.
- Gradients only for hero sections or premium cards.
- Desaturate accent colors ~20% in Dark Mode to avoid neon glare.
- Avoid pure black backgrounds — use charcoal for OLED comfort.

⸻

## ✍️ Typography System

### 🧱 Font Family

- **Primary:** SF Pro Display / SF Pro Text
- **Fallback:** System default (auto-handled by Apple)
- **Dynamic Type:** Enabled everywhere

### 🔠 Hierarchy

| Element | SwiftUI Style | Size | Weight | Use |
|---------|---------------|------|--------|-----|
| Page Title | `.largeTitle` | 34pt | Bold | Main headers |
| Section Title | `.title2` | 22pt | Semibold | Screen sections |
| Headline | `.headline` | 17pt | Semibold | Subsections |
| Body | `.body` | 17pt | Regular | General text |
| Caption | `.caption` | 12pt | Regular | Metadata |

### 💬 Font Variants

- `.rounded` → playful counters, credits, badges
- `.monospaced` → technical or ID labels
- `.default` → general content

### 🧭 Best Practices

- Limit to 3 font weights max.
- Maintain 2:1 visual ratio between title and body text.
- Use `.foregroundStyle(.secondary)` for subtle labels.
- SF Symbols scale automatically — keep alignment consistent.

⸻

## ⚙️ Layout & Spacing

### 📐 Grid & Padding

- **Base unit:** 8pt system grid.
- **Horizontal safe area** respected via `.safeAreaInset()`.
- **Default padding:** 16pt for content blocks, 24pt for sections.
- **Maintain vertical rhythm** with `.spacing(12)` for stacks.

### 🧭 Navigation

- **Root:** TabView (Home, History, Profile).
- **Nested:** NavigationStack.
- **Modals:** `sheet()` for settings and generation results.
- **Use** `.toolbarRole(.editor)` for consistent header layout.

### 🪟 Visual Style

- **Rounded corners:** 12pt for cards, 8pt for buttons.
- **Shadows:** `shadow(color: .black.opacity(0.1), radius: 4, y: 2)`.
- **Blur:** only for background overlays (`.thinMaterial`).

⸻

## ⚡ Animation & Motion

### ⏱️ Principles

**"Purposeful, not playful."**

- **Micro-transitions:** 0.2–0.3s
- **Screen transitions:** 0.3–0.4s
- **Use** `.snappy` or `.smooth` for modern iOS 17 effects.

### 💫 Recommended

```swift
withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
    showResult = true
}
```

- **Loading transitions:** `.opacity` + `.scaleEffect`
- **Success animations:** `.interpolatingSpring(stiffness: 200, damping: 25)`
- **Video completion →** haptic feedback (`.success`)

### 🔄 Reduce Motion

If "Reduce Motion" is enabled, disable nonessential animations automatically.

⸻

## ⏳ Loading & Feedback States

### 🧩 Loading

- **Use** `ProgressView()` for immediate feedback.
- **Use** shimmer skeletons (RoundedRectangle with gradient animation).
- **Prefer** overlay loaders, never full-screen blocking.

### 🪄 Toasts & Banners

| Type | Color | Duration | Haptic |
|------|-------|----------|--------|
| Success | Green | 3s | light success |
| Warning (Low Credits) | Amber | 3s | medium |
| Error | Red | 4s | error |
| Info | Blue | 2s | none |

Toasts auto-dismiss; no more than 3 concurrent messages.

⸻

## 💳 Credit UI Patterns

- **Credit balance** displayed in top-right capsule.
- **Low credit banner** triggers under 10 credits.
- **Button style:**
  - `.tint(Color("BrandPrimary"))`
  - `.buttonStyle(.borderedProminent)`
- **Purchase sheet** follows Apple's In-App Purchase flow design.

⸻

## 🪄 Theme Personality

| Mode | Description |
|------|-------------|
| Light | Airy, soft, creative energy. Off-white backgrounds, clean cards. |
| Dark | Deep, cinematic, immersive. Purple glow accents, reduced saturation. |
| Motion | Smooth transitions, micro-haptics, no bounce. |
| Overall Feel | Calm confidence — "smart, not flashy." |

⸻

## 🧩 Summary Principles

| Category | Rule |
|----------|------|
| Layout | Use Apple's safe area + 8pt grid |
| Color | Semantic, high contrast, brand accent |
| Typography | SF Pro only, 3 weights max |
| Animation | Subtle, responsive, cancelable |
| Feedback | Always show progress + toast |
| Personality | Playful minimalism, Apple-native feel |

⸻

## 🧠 References

- Apple Human Interface Guidelines – SwiftUI 2025
- SwiftUI Documentation (Apple Developer)
- SF Symbols Guidelines

⸻

## 💡 End Note

Rendio AI's UI should feel like a bridge between playfulness and precision.

Every motion, color, and font choice should whisper **"Apple native, but alive."**

⸻
