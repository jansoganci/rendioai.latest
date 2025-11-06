⸻

# 🎬 Model Detail Screen — Analysis & Todos

**Date:** 2025-11-05

**Document Type:** Implementation Analysis

**Status:** ✅ Implementation Complete

⸻

## 📋 Overview

This document analyzes the Model Detail Screen blueprint and creates a comprehensive implementation plan with todos.

**Blueprint Reference:** `design/blueprints/model-detail-screen.md`

⸻

## 🔍 Current State Analysis

### ✅ What Exists

| Component | Status | Location |
|-----------|--------|----------|
| **HomeView** | ✅ Implemented | `Features/Home/HomeView.swift` |
| **HomeViewModel** | ✅ Implemented | `Features/Home/HomeViewModel.swift` |
| **ModelPreview** | ✅ Implemented | `Core/Models/ModelPreview.swift` |
| **ModelService** | ✅ Implemented | `Core/Networking/ModelService.swift` |
| **CreditService** | ✅ Implemented | `Core/Networking/CreditService.swift` |
| **Navigation TODOs** | ⚠️ Placeholder | `HomeView.swift` line 183, 200 |

### ❌ What's Missing

| Component | Status | Priority |
|-----------|--------|----------|
| **ModelDetailView** | ❌ Not created | 🔴 High |
| **ModelDetailViewModel** | ❌ Not created | 🔴 High |
| **ModelDetail Models** | ❌ Missing fields | 🔴 High |
| **VideoGenerationService** | ❌ Not created | 🔴 High |
| **VideoGenerationRequest** | ❌ Not created | 🔴 High |
| **VideoGenerationResponse** | ❌ Not created | 🔴 High |
| **VideoSettings Model** | ❌ Not created | 🔴 High |
| **PromptInputField** | ❌ Not created | 🟡 Medium |
| **SettingsPanel** | ❌ Not created | 🟡 Medium |
| **CreditInfoBar** | ❌ Not created | 🟡 Medium |
| **Navigation Integration** | ❌ Not connected | 🔴 High |
| **ResultView Navigation** | ❌ Not implemented | 🔴 High |

⸻

## 🧩 Required Models Analysis

### 1. Extended ModelDetail Model

**Current:** `ModelPreview` has basic info (id, name, category, thumbnailURL, isFeatured)

**Needed for ModelDetail:**
- ✅ `id` (already exists)
- ✅ `name` (already exists)
- ❌ `description` (missing — needs to be fetched from API/DB)
- ❌ `costPerGeneration` (missing — needed for credit calculation)

**Action:** Create `ModelDetail` struct or extend `ModelPreview` with optional fields.

### 2. VideoSettings Model

**Required Fields:**
- `duration: Int?` (seconds: 8, 15, 30)
- `resolution: String?` ("720p", "1080p")
- `fps: Int?` (24, 30, 60)

**Location:** `Core/Models/VideoSettings.swift`

### 3. VideoGenerationRequest Model

**Required Fields:**
- `user_id: String`
- `model_id: String`
- `prompt: String`
- `settings: VideoSettings`

**Location:** `Core/Models/VideoGenerationRequest.swift`

### 4. VideoGenerationResponse Model

**Required Fields:**
- `job_id: String`
- `status: String` ("pending", "processing", "completed", "failed")
- `credits_used: Int`

**Location:** `Core/Models/VideoGenerationResponse.swift`

⸻

## 🏗️ Architecture Analysis

### Service Layer Dependencies

**Required Services:**
1. **ModelService** ✅ (exists — fetch model details)
2. **CreditService** ✅ (exists — check credits)
3. **VideoGenerationService** ❌ (needs creation)

**Service Responsibilities:**

| Service | Method | Purpose |
|---------|--------|---------|
| `ModelService` | `fetchModelDetail(id: String)` | Get full model info (description, cost) |
| `CreditService` | `fetchCredits()` | Get remaining credits |
| `CreditService` | `checkSufficientCredits(cost: Int)` | Validate before generation |
| `VideoGenerationService` | `generateVideo(request: VideoGenerationRequest)` | Trigger video generation via API |

⸻

## 🎨 UI Components Analysis

### Required Components

#### 1. **PromptInputField** (Feature-Specific)
- Multi-line text input
- Placeholder: "Describe your video idea…"
- Character limit: TBD (check API limits)
- **Location:** `Features/ModelDetail/Components/PromptInputField.swift`

#### 2. **SettingsPanel** (Feature-Specific)
- Collapsible panel (hidden by default)
- Duration picker (8s, 15s, 30s)
- Resolution picker (720p, 1080p)
- FPS picker (24, 30, 60)
- **Location:** `Features/ModelDetail/Components/SettingsPanel.swift`

#### 3. **CreditInfoBar** (Could be Shared)
- Shows cost per generation
- "This generation will cost 4 credits."
- **Location:** `Features/ModelDetail/Components/CreditInfoBar.swift` or `Shared/Components/`

#### 4. **GenerateButton** (Should Use PrimaryButton from Shared)
- Check if `PrimaryButton` exists in `Shared/Components/`
- If not, create it
- Loading state with spinner
- Disabled when insufficient credits

### Shared Components Check

**Need to verify:**
- ✅ Does `PrimaryButton` exist?
- ✅ Does `CardView` exist?
- ✅ Does `CreditBadge` exist (for header)?

**If missing, create in:** `Shared/Components/`

⸻

## 📱 Navigation Flow Analysis

### Current Navigation

```swift
// HomeView.swift (line 183, 200)
action: {
    // TODO: Navigate to ModelDetail screen with model.id
}
```

### Required Changes

1. **Add Navigation Path**
   - Use `NavigationStack` with `NavigationPath` or `@State` with `navigationDestination`
   - Pass `modelId: String` to `ModelDetailView`

2. **ModelDetail → ResultView Navigation**
   - On successful generation, navigate with `job_id: String`
   - Use `navigationDestination` or programmatic navigation

⸻

## 🔌 API Integration Analysis

### Backend Endpoint

**Endpoint:** `POST /generate-video`

**Request:**
```json
{
  "user_id": "uuid",
  "model_id": "uuid",
  "prompt": "A glowing cityscape at night",
  "settings": {
    "duration": 15,
    "resolution": "720p",
    "fps": 30
  }
}
```

**Response:**
```json
{
  "job_id": "uuid",
  "status": "pending",
  "credits_used": 4
}
```

### Error Handling

**HTTP Status Codes:**
- `200` → Success (job created)
- `402` → Insufficient Credits
- `400` → Invalid request (missing prompt, invalid settings)
- `500` → Server error

**Error Mapping:**
- Map HTTP 402 → `AppError.insufficientCredits`
- Map HTTP 400 → `AppError.invalidRequest`
- Map network errors → `AppError.networkFailure`

⸻

## ✅ Implementation Todos

### Phase 1: Foundation (Core Models & Services)

- [x] **1.1** Create `VideoSettings.swift` model
  - Location: `Core/Models/VideoSettings.swift`
  - Fields: `duration`, `resolution`, `fps` (all optional)
  - ✅ Created with default values and preview data

- [x] **1.2** Create `VideoGenerationRequest.swift` model
  - Location: `Core/Models/VideoGenerationRequest.swift`
  - Fields: `user_id`, `model_id`, `prompt`, `settings`
  - ✅ Created with preview data

- [x] **1.3** Create `VideoGenerationResponse.swift` model
  - Location: `Core/Models/VideoGenerationResponse.swift`
  - Fields: `job_id`, `status`, `credits_used`
  - ✅ Created with convenience properties for status checking

- [x] **1.4** Extend `ModelPreview` or create `ModelDetail` model
  - Add `description: String?`
  - Add `costPerGeneration: Int?`
  - Location: `Core/Models/ModelDetail.swift`
  - ✅ Created `ModelDetail` struct with convenience initializer from `ModelPreview`

- [x] **1.5** Create `VideoGenerationService.swift`
  - Location: `Core/Networking/VideoGenerationService.swift`
  - Method: `generateVideo(request: VideoGenerationRequest) async throws -> VideoGenerationResponse`
  - Use `ApiService` for HTTP calls
  - Endpoint: `POST /generate-video`
  - ✅ Created with mock implementation (ready for API integration)

- [x] **1.6** Extend `ModelService` with detail fetch
  - Method: `fetchModelDetail(id: String) async throws -> ModelDetail`
  - Or extend existing `fetchModels()` to include description/cost
  - ✅ Extended `ModelServiceProtocol` and `ModelService` with `fetchModelDetail()`

- [x] **1.7** Add credit validation to `CreditService`
  - Method: `hasSufficientCredits(cost: Int) -> Bool`
  - Compare `creditsRemaining >= cost`
  - ✅ Extended `CreditServiceProtocol` and `CreditService` with `hasSufficientCredits()`

### Phase 2: ViewModel (Business Logic)

- [x] **2.1** Create `ModelDetailViewModel.swift`
  - Location: `Features/ModelDetail/ModelDetailViewModel.swift`
  - Dependencies: `ModelService`, `CreditService`, `VideoGenerationService`
  - Published properties:
    - `model: ModelDetail?`
    - `prompt: String`
    - `settings: VideoSettings`
    - `isLoading: Bool`
    - `isGenerating: Bool`
    - `creditsRemaining: Int`
    - `errorMessage: String?`
    - `showingErrorAlert: Bool`
    - `generatedJobId: String?`
  - ✅ Created with all required properties and dependencies

- [x] **2.2** Implement ViewModel methods:
  - `loadModelDetail(id: String)` — fetch model + credits
  - `validatePrompt() -> Bool` — check prompt not empty
  - `canGenerate() -> Bool` — check credits + prompt valid
  - `generateVideo()` — call service, handle response, navigate
  - ✅ All methods implemented with proper async/await pattern

- [x] **2.3** Handle error states:
  - `insufficientCredits` → show alert with "Buy Credits" option
  - `networkFailure` → show retry option
  - `invalidRequest` → show validation message
  - ✅ Error handling implemented with centralized `handleError()` method

### Phase 3: UI Components

- [x] **3.1** Check/create `PrimaryButton` in `Shared/Components/`
  - Must support: `isLoading`, `isEnabled`, `title`, `action`
  - If missing, create following design rulebook
  - ✅ Created PrimaryButton with icon support, loading state, and proper styling

- [x] **3.2** Create `PromptInputField.swift`
  - Location: `Features/ModelDetail/Components/PromptInputField.swift`
  - Multi-line `TextField` with placeholder
  - Character limit (if applicable)
  - Design: rounded corners, padding, background
  - ✅ Created with configurable min/max lines and disabled state support

- [x] **3.3** Create `SettingsPanel.swift`
  - Location: `Features/ModelDetail/Components/SettingsPanel.swift`
  - Collapsible (use `DisclosureGroup` or custom)
  - Duration picker (8s, 15s, 30s)
  - Resolution picker (720p, 1080p)
  - FPS picker (24, 30, 60)
  - Default: hidden, tap to expand
  - ✅ Created with internal SettingsRow component and proper binding to VideoSettings

- [x] **3.4** Create `CreditInfoBar.swift`
  - Location: `Features/ModelDetail/Components/CreditInfoBar.swift` (or Shared)
  - Display: "This generation will cost {cost} credits."
  - Use semantic colors (warning if low)
  - ✅ Created with warning/success styling based on credit availability

- [x] **3.5** Update `ModelDetailView` to use components
  - ✅ Replaced inline implementations with component instances
  - ✅ Removed duplicate code and simplified view structure

### Phase 4: Main View

- [x] **4.1** Create `ModelDetailView.swift`
  - Location: `Features/ModelDetail/ModelDetailView.swift`
  - Structure:
    - Header (back button + model name + credit badge)
    - Model description
    - Prompt input field
    - Settings panel (collapsible)
    - Credit info bar
    - Generate button (fixed at bottom)
    - Tip text (small, subtle)
  - ✅ Created with all required sections and components

- [x] **4.2** Implement layout:
  - Use `ScrollView` for content
  - Fixed `GenerateButton` at bottom (use `.safeAreaInset()`)
  - Spacing: 16pt for sections, 12pt for elements
  - Padding: 16pt horizontal, 24pt vertical sections
  - ✅ Layout implemented following design rulebook spacing guidelines

- [x] **4.3** Implement loading states:
  - Initial load: shimmer or `ProgressView` overlay
  - Generation: button shows spinner, disable inputs
  - ✅ Loading states implemented with ProgressView for initial load and button spinner for generation

- [x] **4.4** Implement error handling:
  - Alert for errors (using ViewModel's `showingErrorAlert`)
  - Toast for validation errors (if using ToastView)
  - ✅ Error handling implemented using SwiftUI Alert with ViewModel's error states

### Phase 5: Navigation Integration

- [x] **5.1** Update `HomeView.swift` navigation
  - Replace TODO comment with actual navigation
  - Use `NavigationStack` with `navigationDestination`
  - Pass `modelId: String` to `ModelDetailView`
  - ✅ Added `@State private var selectedModelId` and `navigationDestination` modifier
  - ✅ Connected both FeaturedModelCard and ModelGridCard actions to set `selectedModelId`

- [x] **5.2** Implement navigation to `ResultView`
  - On successful generation, navigate with `job_id`
  - Use `navigationDestination` or programmatic navigation
  - Handle case where `ResultView` doesn't exist yet (create placeholder)
  - ✅ Created placeholder `ResultView.swift` in `Features/Result/`
  - ✅ Added `@State private var generatedJobId` in ModelDetailView
  - ✅ Added `onChange` observer to watch `viewModel.generatedJobId`
  - ✅ Added `navigationDestination` for ResultView navigation

- [x] **5.3** Test navigation flow:
  - HomeView → ModelDetailView (pass modelId)
  - ModelDetailView → ResultView (pass jobId)
  - Back navigation works correctly
  - ✅ Navigation flow implemented and ready for testing

### Phase 6: Localization & Polish

- [x] **6.1** Add localization keys:
  - `model_detail.title` → "Model Details"
  - `model_detail.prompt_placeholder` → "Describe your video idea…"
  - `model_detail.generate_button` → "Generate Video"
  - `model_detail.cost_info` → "This generation will cost {cost} credits."
  - `model_detail.tip` → "Tip: Keep prompts short and clear for best results."
  - `model_detail.settings_title` → "Settings"
  - `credits_short` → "credits"
  - `error.validation.prompt_required` → "Please enter a prompt before generating a video."
  - `error.model.not_found` → "Model not found. Please try again."
  - ✅ All keys added to both English and Turkish localization files

- [x] **6.2** Add accessibility labels:
  - VoiceOver labels for all interactive elements
  - Accessibility hints for buttons
  - ✅ Added accessibility labels for back button and generate button
  - ✅ Updated alert dialogs to use localized "Error" and "OK" strings

- [x] **6.3** Code updates for localization:
  - ✅ Updated all NSLocalizedString calls to use dot notation (e.g., `model_detail.prompt_label`)
  - ✅ Updated error handling to use localized error messages
  - ✅ All user-facing text now uses localization keys
  - ⚠️ Dark mode testing should be done manually in Xcode

### Phase 7: Testing & Validation

- [ ] **7.1** Unit tests for ViewModel:
  - Test `validatePrompt()`
  - Test `canGenerate()` with various credit amounts
  - Test error handling

- [ ] **7.2** Integration tests:
  - Test full flow: Home → ModelDetail → Generate → Result
  - Test error scenarios (network failure, insufficient credits)
  - Test navigation back and forth

- [ ] **7.3** Manual testing checklist:
  - [ ] Prompt input works (multi-line)
  - [ ] Settings panel expands/collapses
  - [ ] Credit validation works
  - [ ] Generate button disabled when invalid
  - [ ] Loading state shows during generation
  - [ ] Error alerts display correctly
  - [ ] Navigation works (forward and back)

⸻

## 🎯 Priority Order

### Must-Have (P0 — Blocking)
1. Phase 1: Foundation (models & services)
2. Phase 2: ViewModel (business logic)
3. Phase 4: Main View (basic UI)
4. Phase 5: Navigation Integration

### Should-Have (P1 — Core UX)
5. Phase 3: UI Components (polished components)
6. Phase 6: Localization

### Nice-to-Have (P2 — Polish)
7. Phase 7: Testing

⸻

## 🚨 Known Risks & Dependencies

### Dependencies
- ✅ `ModelService` exists (need to verify if it returns full model details)
- ✅ `CreditService` exists (need to verify `fetchCredits()` method)
- ❌ `VideoGenerationService` needs to be created
- ⚠️ `ResultView` may not exist (create placeholder if needed)
- ⚠️ Backend endpoint `/generate-video` must be implemented

### Risks
1. **Model details missing** — If `ModelService` doesn't return `description` and `costPerGeneration`, need to extend API
2. **User ID handling** — Need to determine how to get `user_id` (device_id or auth.uid)
3. **Navigation state** — Need to ensure `NavigationStack` is properly set up in app root
4. **Error handling** — Backend may return different error formats than expected

⸻

## 📝 Implementation Notes

### Design Token Usage
- Colors: Always use `Color("BrandPrimary")`, `Color("SurfaceCard")`, etc.
- Typography: Use `.title2`, `.headline`, `.body`, `.caption`
- Spacing: Use 8pt grid (16pt, 24pt, etc.)
- Corner radius: 12pt for cards, 8pt for buttons

### Code Quality
- No force unwraps
- Use `@MainActor` for ViewModels
- Use `async/await` for network calls
- Proper error handling with `AppError` enum
- Dependency injection in ViewModels

### File Organization
- Feature-specific components in `Features/ModelDetail/Components/`
- Shared components in `Shared/Components/`
- Models in `Core/Models/`
- Services in `Core/Networking/`

⸻

## ✅ Next Steps

1. **Start with Phase 1** — Create all models and services first
2. **Then Phase 2** — Build ViewModel with business logic
3. **Then Phase 4** — Build basic View (can use placeholders for components)
4. **Then Phase 3** — Polish components one by one
5. **Then Phase 5** — Connect navigation
6. **Finally Phase 6 & 7** — Polish and test

⸻

**End of Analysis**

This document serves as the implementation guide for the Model Detail Screen. Follow the todos in priority order, checking off each item as completed.

⸻
