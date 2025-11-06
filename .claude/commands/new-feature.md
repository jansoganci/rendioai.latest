# Create New Feature Module

You are creating a new feature module for Rendio AI following MVVM architecture.

## Instructions

Ask the user for:
1. **Feature name** (e.g., "Favorites", "Search", "Settings")
2. **Brief description** of what this feature does

Then create:

### 1. Folder Structure
```
Features/{FeatureName}/
├── {FeatureName}View.swift
├── {FeatureName}ViewModel.swift
└── Components/
    └── (feature-specific components as needed)
```

### 2. View File
Create `{FeatureName}View.swift` with:
- SwiftUI `View` conformance
- `@StateObject` for ViewModel
- Proper navigation structure
- Design tokens for colors/typography
- 16pt horizontal padding

### 3. ViewModel File
Create `{FeatureName}ViewModel.swift` with:
- `@MainActor` annotation
- `ObservableObject` conformance
- `@Published` properties for state
- Dependency injection for services
- Proper error handling via `AppError`

### 4. Quality Checks
Ensure:
- ✅ No force unwraps
- ✅ Design tokens used (Color("BrandPrimary"), etc.)
- ✅ All user-facing text uses i18n keys
- ✅ Proper async/await for async operations
- ✅ File names match type names

### 5. Integration Guide
Provide instructions for:
- Adding navigation from existing screens
- Registering in TabView (if needed)
- Required service dependencies
- Database schema changes (if any)

## Example Output

After gathering requirements, create the complete implementation and explain how to integrate it into the app.
