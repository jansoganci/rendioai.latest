⸻

# 🧩 Design Decision Record

**Title:** Hybrid Home Screen Design — BananaUniverse + Video App Blueprint

**Date:** 2025-11-04

**Author:** [You]

**Status:** ✅ Approved

**Version:** 1.0

**Category:** UI / Architecture Integration

⸻

## 🎯 Decision Summary

Adopt a hybrid design strategy for the Video App Home Screen by merging strong UI/UX patterns from the existing BananaUniverse implementation with enhancements defined in the new Video App Blueprint.

The goal is to retain the mature parts of the current UI while modernizing visual hierarchy, discoverability, and user flow for video model interactions.

⸻

## 📐 Home Screen Layout

```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [Profile Icon]  RendioAI          [Empty Space]    │   │ Header
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🔍  Search models, categories, or videos...        │   │ Search Bar
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ⚠️  Warning: Low credits remaining (X left)       │   │ Quota Banner
│  │      [Upgrade] or [Dismiss]                          │   │ (Conditional)
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Featured Models                                     │   │ Section Title
│  │                                                       │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │   │
│  │  │  [Thumbnail] │  │  [Thumbnail] │  │[Thumbnail]│  │   │ Carousel
│  │  │  Model Name  │  │  Model Name  │  │Model Name │  │   │ (Auto-scroll
│  │  │  Category    │  │  Category    │  │ Category  │  │   │  every 5s)
│  │  └──────────────┘  └──────────────┘  └──────────┘  │   │
│  │                                                       │   │
│  │         ● ─── ○ ─── ○                                │   │ Page Indicators
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  All Models                                          │   │ Section Title
│  │                                                       │   │
│  │  ┌──────┐  ┌──────┐  ┌──────┐                       │   │
│  │  │[Img] │  │[Img] │  │[Img] │                       │   │
│  │  │Name  │  │Name  │  │Name  │                       │   │ Model Grid
│  │  └──────┘  └──────┘  └──────┘                       │   │ (Thumbnail
│  │                                                       │   │  Cards)
│  │  ┌──────┐  ┌──────┐  ┌──────┐                       │   │
│  │  │[Img] │  │[Img] │  │[Img] │                       │   │
│  │  │Name  │  │Name  │  │Name  │                       │   │
│  │  └──────┘  └──────┘  └──────┘                       │   │
│  │                                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│                        (Scrollable Content)                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Layout Components Breakdown

1. **Header Bar**
   - Profile icon button (top-left) for account/profile access
   - App title/logo (center or left)
   - Future: Settings or menu items (top-right)

2. **Search Bar**
   - Full-width search input
   - Placeholder: "Search models, categories, or videos..."
   - Icon: 🔍 search icon on left

3. **Quota Warning Banner** (Conditional)
   - Only visible when credits are low
   - Warning icon + message
   - Action buttons: [Upgrade] or [Dismiss]
   - Styled with Warning design token

4. **Featured Models Carousel**
   - Horizontal scrolling carousel
   - 3-5 model cards visible at once
   - Each card shows: thumbnail image, model name, category
   - Auto-scrolls every 5 seconds
   - Page indicators (dots) below show current position
   - User can swipe/scroll to navigate manually

5. **All Models Grid**
   - Vertical scrollable grid
   - Thumbnail-based model cards
   - Responsive columns (2-3 per row on mobile, more on tablet)
   - Each card: thumbnail image + model name
   - Tappable to navigate to model detail

### Empty States

When no content is available:
- Carousel shows placeholder: "No featured models available"
- Grid shows: "No models found. Try adjusting your search."

⸻

## 🧠 Rationale

The BananaUniverse app already provides stable, well-tested foundations for:

- State management (conditional rendering, empty states)
- Functional UI elements (search bar, quota banner)
- User familiarity and interaction flow

However, the new Video App Blueprint introduces improvements in clarity, hierarchy, and usability (carousel indicators, profile integration, visual cards).

Combining both creates a refined, scalable, and familiar user experience without redundant redesign.

⸻

## ✅ Keep from Current (BananaUniverse)

| Component | Reason |
|-----------|--------|
| Search Bar | Core discovery entry point; aligns with user expectations. |
| Quota Warning Banner | Integrates directly with credit system; high visibility for freemium model. |
| Conditional Rendering Logic | Stable MVVM-compatible pattern; reduces UI crashes. |
| Empty States | Enhances clarity and UX consistency during data fetch or offline mode. |

⸻

## ➕ Add from Video App Blueprint

| Component | Reason |
|-----------|--------|
| Page Indicators (Carousel) | Provides positional feedback; enhances carousel navigation. |
| Profile Icon (Header) | Enables direct access to profile/premium/auth areas. |
| Thumbnail-Based Model Cards | Essential for video-centric experience; improves scanability and visual appeal. |

⸻

## ⚙️ Improvements

| Feature | Change | Outcome |
|---------|--------|---------|
| Auto-scroll Interval | From 3s → 5s | Smoother rhythm, reduced motion fatigue. |
| Page Indicators | Adopt blueprint's dot-style pagination | Stronger UX feedback and better gesture pairing. |
| Quota Banner Design | Unify with design tokens (Warning / Secondary) | Visual consistency across all screens. |

⸻

## 🧩 Technical Impact

- Minor adjustments to HomeView logic (Timer.publish interval, Carousel state binding).
- Addition of PageIndicatorView reusable component.
- Header updated with ProfileIconButton.
- ModelCard refactored to support thumbnailPreviewURL instead of static icon.
- No breaking changes to data fetching or view models.

⸻

## 🧱 Dependencies

- DesignTokens (colors, spacing, typography)
- HomeViewModel (data source for featured + quota)
- ModelService (model metadata retrieval)

⸻

## 📈 Expected Benefits

1. More balanced visual rhythm and reduced scroll fatigue.
2. Stronger alignment with the Blueprint's marketplace-style layout.
3. Consistent design language between BananaUniverse and Video App.
4. Easier future expansion (new categories, personalized recommendations).

⸻

## 🔮 Future Considerations

- Integrate personalized recommendations beneath Featured section.
- Add dynamic search suggestions powered by AI metadata.
- A/B test scroll interval (4s vs 5s) for engagement optimization.

⸻

**Decision:** ✅ Approved

**Next Action:** Implement during Phase 1 of UI migration (HomeView modernization).

⸻
