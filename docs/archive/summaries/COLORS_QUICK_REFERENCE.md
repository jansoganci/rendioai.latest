# Rendio AI Color Quick Reference

**Copy-paste color names for SwiftUI**

---

## 🎨 Brand

```swift
Color("BrandPrimary")  // Cosmic Purple / Soft Violet
Color("Accent")        // Electric Pink / Coral Glow
```

---

## 📄 Surfaces

```swift
Color("SurfaceBase")   // App background
Color("SurfaceCard")   // Cards, elevated surfaces
```

---

## ✍️ Text

```swift
Color("TextPrimary")   // Main text
Color("TextSecondary") // Subtitles, labels
```

---

## 🎯 Semantic

```swift
Color("AccentWarning") // Warnings, alerts
Color("AccentError")   // Errors, destructive actions
Color("AccentSuccess") // Success states
```

---

## 📋 Hex Values

| Color | Light | Dark |
|-------|-------|------|
| BrandPrimary | `#6B4FFF` | `#8B7CFF` |
| Accent | `#FF3D71` | `#FF6B6B` |
| SurfaceBase | `#F8FAFC` | `#0D0D0F` |
| SurfaceCard | `#F1F5F9` | `#1E293B` |
| TextPrimary | `#1E1E1E` | `#FFFFFF` |
| TextSecondary | `#525252` | `#9CA3AF` |
| AccentWarning | `#F59E0B` | `#FBBF24` |
| AccentError | `#EF4444` | `#F87171` |
| AccentSuccess | `#10B981` | `#34D399` |

---

## ⚡ Common Patterns

### Background
```swift
.background(Color("SurfaceBase"))
```

### Card
```swift
.background(Color("SurfaceCard"))
.cornerRadius(12)
```

### Primary Button
```swift
.background(Color("BrandPrimary"))
.foregroundColor(.white)
```

### Warning Banner
```swift
.background(Color("AccentWarning").opacity(0.1))
.foregroundColor(Color("AccentWarning"))
```

---

**All colors auto-adapt to Light/Dark mode** ✨
