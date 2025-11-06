# Create Reusable UI Component

You are creating a reusable SwiftUI component for Rendio AI.

## Instructions

Ask the user:
1. **Component name** (e.g., "PrimaryButton", "VideoCard", "LoadingSpinner")
2. **Purpose** (what it does)
3. **Props/parameters** needed
4. **Where it will be used** (multiple screens or feature-specific)

Then determine placement:
- **`Shared/Components/`** if used in 2+ features
- **`Features/{Feature}/Components/`** if feature-specific

### Create Component File

Generate a SwiftUI component with:

```swift
import SwiftUI

struct {ComponentName}: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    // MARK: - Body
    var body: some View {
        // Implementation using design tokens
    }
}

// MARK: - Preview
#Preview {
    {ComponentName}(title: "Example", action: {})
}
```

### Design Token Requirements
Use:
- ✅ `Color("BrandPrimary")` not `Color.blue`
- ✅ `.headline` not `.font(.system(size: 17))`
- ✅ `16` spacing not arbitrary numbers
- ✅ `12` corner radius for cards, `8` for buttons

### Props Pattern
Follow these patterns:
- Required props first (no defaults)
- Optional props with defaults
- Action closures last
- Use `var` for optional props

### Stateless by Default
- Pass data via parameters
- No `@State` unless absolutely necessary
- Single responsibility

### Preview Provider
Always include a preview with:
- Default state
- Loading state (if applicable)
- Disabled state (if applicable)

## Output

Deliver:
- Complete component source code
- Usage examples in comments
- Preview variations
- Location in project (`Shared/` or `Features/`)
