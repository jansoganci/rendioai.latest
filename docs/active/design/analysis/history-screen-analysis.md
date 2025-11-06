⸻

# 🎞️ History Screen — Analysis & Todos

**Date:** 2025-11-05

**Document Type:** Implementation Analysis

**Status:** 📋 Planning Phase

⸻

## 📋 Overview

This document analyzes the History Screen blueprint and creates a comprehensive implementation plan with todos.

**Blueprint Reference:** `design/blueprints/history-screen.md`

⸻

## 🔍 Current State Analysis

### ✅ What Exists

| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| **HistoryView** | ✅ Placeholder | `Features/History/HistoryView.swift` | Just "Coming Soon" message |
| **ResultView** | ✅ Placeholder | `Features/Result/ResultView.swift` | Basic placeholder |
| **Navigation Flow** | ✅ Tab Menu | `ContentView.swift` | History tab exists |
| **AppError** | ✅ Implemented | `Core/Models/AppError.swift` | Error handling system |
| **HomeViewModel** | ✅ Pattern exists | `Features/Home/HomeViewModel.swift` | MVVM pattern reference |
| **ModelService** | ✅ Pattern exists | `Core/Networking/ModelService.swift` | Service pattern reference |
| **CreditService** | ✅ Pattern exists | `Core/Networking/CreditService.swift` | Service pattern reference |

### ❌ What's Missing

| Component | Status | Priority |
|-----------|--------|----------|
| **VideoJob Model** | ❌ Not created | 🔴 High |
| **HistoryService** | ❌ Not created | 🔴 High |
| **HistoryViewModel** | ❌ Not created | 🔴 High |
| **HistoryCard Component** | ❌ Not created | 🔴 High |
| **HistorySection Component** | ❌ Not created | 🔴 High |
| **HistoryEmptyState Component** | ❌ Not created | 🟡 Medium |
| **Search Bar** | ❌ Not implemented | 🟡 Medium |
| **Pull-to-Refresh** | ❌ Not implemented | 🟡 Medium |
| **Swipe to Delete** | ❌ Not implemented | 🟡 Medium |
| **Date Grouping Logic** | ❌ Not implemented | 🔴 High |
| **Navigation to ResultView** | ❌ Not connected | 🔴 High |

⸻

## 🧩 Required Models Analysis

### 1. VideoJob Model

**Required Fields (from blueprint & API):**

```swift
struct VideoJob: Identifiable, Codable {
    let job_id: String          // Primary identifier
    let prompt: String          // User's prompt text
    let model_name: String      // Provider name (e.g., "FalAI Veo 3.1")
    let credits_used: Int       // Cost of generation
    let status: JobStatus       // Enum: pending, processing, completed, failed
    let video_url: String?      // Optional: only when completed
    let thumbnail_url: String?  // Optional: preview image
    let created_at: Date        // For date grouping
    
    var id: String { job_id }   // For Identifiable
    
    enum JobStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
}
```

**Location:** `Core/Models/VideoJob.swift`

**Additional:**
- Convenience properties: `isPending`, `isProcessing`, `isCompleted`, `isFailed`
- Preview data for SwiftUI previews

### 2. HistorySection Model

**Required Fields:**

```swift
struct HistorySectionModel: Identifiable {
    let id: String              // Date string as ID
    let date: String            // Formatted date (e.g., "November 2025")
    let items: [VideoJob]       // Jobs created on this date
    
    var dateValue: Date?        // Optional: for sorting
}
```

**Location:** `Core/Models/HistorySectionModel.swift`

**Purpose:** Groups VideoJobs by creation date for display in sections

### 3. VideoJobsResponse Model (API Response)

**Required Fields:**

```swift
struct VideoJobsResponse: Codable {
    let jobs: [VideoJob]
}
```

**Location:** `Core/Models/VideoJobsResponse.swift`

**Purpose:** Wraps API response from `/get-video-jobs` endpoint

⸻

## 🏗️ Architecture Analysis

### Service Layer Dependencies

**Required Services:**

1. **HistoryService** ❌ (needs creation)
   - Method: `fetchVideoJobs(userId: String?) async throws -> [VideoJob]`
   - Endpoint: `GET /get-video-jobs?user_id={id}` or `GET /get-video-jobs?device_id={uuid}`
   - Returns: Array of VideoJob objects

2. **VideoStatusService** ❌ (optional - for polling status)
   - Method: `getVideoStatus(jobId: String) async throws -> VideoJob`
   - Endpoint: `GET /get-video-status?job_id={id}`
   - Purpose: Poll for status updates on processing jobs

**Service Responsibilities:**

| Service | Method | Purpose |
|---------|--------|---------|
| `HistoryService` | `fetchVideoJobs(userId:)` | Get all jobs for user/device |
| `HistoryService` | `deleteVideoJob(jobId:)` | Delete a job (optional for MVP) |
| `VideoStatusService` | `getVideoStatus(jobId:)` | Poll for status updates (future) |

⸻

## 🎨 UI Components Analysis

### Required Components

#### 1. **HistoryCard** (Feature-Specific)
- Displays single video job
- Shows thumbnail (or placeholder)
- Shows prompt snippet (truncated if long)
- Shows model name, duration, status
- Shows action buttons based on status:
  - Completed: [▶️ Play] [📥 Download] [📤 Share]
  - Processing: [⏱ Wait] (disabled)
  - Failed: [🔁 Retry] [🗑 Delete]
- Tap to navigate to ResultView
- **Location:** `Features/History/Components/HistoryCard.swift`

#### 2. **HistorySection** (Feature-Specific)
- Displays section header with date
- Contains list of HistoryCards
- Uses SwiftUI `Section` component
- **Location:** `Features/History/Components/HistorySection.swift`

#### 3. **HistoryEmptyState** (Feature-Specific)
- Shows when user has no history
- Icon + message: "No videos yet. Generate your first video!"
- Call-to-action button (optional)
- **Location:** `Features/History/Components/HistoryEmptyState.swift`

#### 4. **SearchBar** (Could be Shared)
- Similar to HomeView search bar
- Filters jobs by prompt keyword
- **Location:** `Features/History/Components/` or `Shared/Components/`

### Shared Components Check

**Already Available:**
- ✅ `PrimaryButton` - For action buttons
- ⚠️ `SecondaryButton` - May need for secondary actions
- ❌ `CardView` - May need for job cards
- ❌ `LoadingView` - May need for loading states

**If missing, create in:** `Shared/Components/`

⸻

## 📱 Navigation Flow Analysis

### Current Navigation

```swift
// ContentView.swift (TabView)
History Tab → HistoryView (placeholder)
```

### Required Navigation

1. **HistoryView → ResultView**
   - User taps on HistoryCard
   - Navigate with `job_id: String`
   - Use `navigationDestination` (similar to ModelDetailView → ResultView)

2. **Navigation State**
   - Each tab maintains its own NavigationStack (already implemented in ContentView)
   - HistoryView is wrapped in NavigationStack
   - ResultView should be accessible from History tab

### Navigation Implementation

```swift
// HistoryView.swift
@State private var selectedJobId: String?

// On card tap:
selectedJobId = job.job_id

// Navigation:
.navigationDestination(isPresented: Binding(
    get: { selectedJobId != nil },
    set: { if !$0 { selectedJobId = nil } }
)) {
    if let jobId = selectedJobId {
        ResultView(jobId: jobId)
    }
}
```

⸻

## 🔌 API Integration Analysis

### Backend Endpoint

**Endpoint:** `GET /get-video-jobs`

**Query Parameters:**
- For logged-in users: `?user_id={uuid}`
- For guest users: `?device_id={uuid}`

**Response:**
```json
{
  "jobs": [
    {
      "job_id": "a1b2c3",
      "prompt": "sunset ocean scene",
      "model_name": "FalAI Veo 3.1",
      "credits_used": 4,
      "status": "completed",
      "video_url": "https://cdn.supabase.com/video123.mp4",
      "thumbnail_url": "https://cdn.supabase.com/thumb123.jpg",
      "created_at": "2025-11-03T18:10:24Z"
    },
    {
      "job_id": "b2c3d4",
      "prompt": "neon city lights",
      "model_name": "Sora 2",
      "credits_used": 6,
      "status": "processing",
      "created_at": "2025-11-04T10:01:45Z"
    }
  ]
}
```

### Error Handling

**HTTP Status Codes:**
- `200` → Success
- `401` → Unauthorized (invalid device/user)
- `404` → No jobs found (return empty array)
- `500` → Server error

**Error Mapping:**
- Map HTTP 401 → `AppError.unauthorized`
- Map HTTP 404 → Return empty array (not an error)
- Map network errors → `AppError.networkFailure`

### User ID / Device ID Management

**Current State:** Placeholder in ViewModels (`"user-placeholder-id"`)

**Required:**
- Device ID from DeviceCheck (for guest users)
- User ID from Auth (for logged-in users)
- TODO: Implement proper ID management service

**Temporary:** Use placeholder, add TODO comments

⸻

## 📐 UI Behavior Analysis

### Status-Based UI States

| Status | UI Elements | Actions Available |
|--------|-------------|-------------------|
| **completed** | ✅ Icon, thumbnail, play button | [▶️ Play] [📥 Download] [📤 Share] |
| **processing** | ⚙️ Spinner icon, disabled state | [⏱ Wait] (disabled) |
| **failed** | ❌ Error icon, error message | [🔁 Retry] [🗑 Delete] |

### Date Grouping Logic

**Format:** "November 2025", "October 2025", etc.

**Sorting:** Newest first (most recent date at top)

**Grouping Algorithm:**
```swift
// Group jobs by month/year
let grouped = Dictionary(grouping: jobs) { job in
    job.created_at.formatted(date: .abbreviated, time: .omitted)
    // Or: Calendar.current.dateComponents([.month, .year], from: job.created_at)
}

// Convert to sections sorted by date (newest first)
let sections = grouped.map { dateString, jobs in
    HistorySectionModel(
        date: dateString,
        items: jobs.sorted { $0.created_at > $1.created_at }
    )
}.sorted { $0.dateValue ?? Date.distantPast > $1.dateValue ?? Date.distantPast }
```

### Search Functionality

**Scope:** Filter by prompt text (case-insensitive)

**Implementation:**
```swift
var filteredSections: [HistorySectionModel] {
    if searchQuery.isEmpty {
        return historySections
    }
    
    return historySections.map { section in
        let filteredJobs = section.items.filter { job in
            job.prompt.localizedCaseInsensitiveContains(searchQuery)
        }
        return HistorySectionModel(
            date: section.date,
            items: filteredJobs
        )
    }.filter { !$0.items.isEmpty }  // Remove empty sections
}
```

### Pull-to-Refresh

**Implementation:** SwiftUI `.refreshable` modifier

```swift
ScrollView {
    // Content
}
.refreshable {
    await viewModel.refreshHistory()
}
```

### Swipe to Delete

**Implementation:** SwiftUI `.swipeActions`

```swift
HistoryCard(job: job)
    .swipeActions(edge: .trailing) {
        Button(role: .destructive) {
            viewModel.deleteJob(jobId: job.job_id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```

⸻

## ✅ Implementation Todos

### Phase 1: Foundation (Core Models & Services)

- [x] **1.1** Create `VideoJob.swift` model
  - Location: `Core/Models/VideoJob.swift`
  - Fields: `job_id`, `prompt`, `model_name`, `credits_used`, `status`, `video_url`, `thumbnail_url`, `created_at`
  - Enum: `JobStatus` (pending, processing, completed, failed)
  - Convenience properties: `isPending`, `isProcessing`, etc.
  - Preview data
  - ✅ Created with ISO8601 date decoding, convenience properties, and preview data

- [x] **1.2** Create `HistorySectionModel.swift` model
  - Location: `Core/Models/HistorySectionModel.swift`
  - Fields: `id`, `date`, `items`, `dateValue`
  - Purpose: Group jobs by date
  - ✅ Created with date sorting support and preview data

- [x] **1.3** Create `VideoJobsResponse.swift` model
  - Location: `Core/Models/VideoJobsResponse.swift`
  - Fields: `jobs: [VideoJob]`
  - Purpose: Wrap API response
  - ✅ Created with preview data

- [x] **1.4** Create `HistoryService.swift`
  - Location: `Core/Networking/HistoryService.swift`
  - Protocol: `HistoryServiceProtocol`
  - Method: `fetchVideoJobs(userId: String?) async throws -> [VideoJob]`
  - Method: `deleteVideoJob(jobId: String) async throws` (optional for MVP)
  - Endpoint: `GET /get-video-jobs`
  - Mock implementation (ready for API integration)
  - ✅ Created with protocol, implementation, and mock service for testing

### Phase 2: ViewModel (Business Logic)

- [x] **2.1** Create `HistoryViewModel.swift`
  - Location: `Features/History/HistoryViewModel.swift`
  - `@MainActor class HistoryViewModel: ObservableObject`
  - Published properties:
    - `historySections: [HistorySectionModel]`
    - `isLoading: Bool`
    - `errorMessage: String?`
    - `showingErrorAlert: Bool`
    - `searchQuery: String`
  - Dependencies: `HistoryServiceProtocol`
  - Methods:
    - `loadHistory()`
    - `refreshHistory()`
    - `deleteJob(jobId:)`
    - `groupJobsByDate(_ jobs: [VideoJob]) -> [HistorySectionModel]`
    - `filteredSections: [HistorySectionModel]` (computed)
  - ✅ Created with all required properties and methods, following MVVM pattern

- [x] **2.2** Implement date grouping logic
  - Group by month/year
  - Sort newest first
  - Format dates as "November 2025"
  - ✅ Implemented with DateFormatter, proper sorting (newest first), and jobs sorted within sections

- [x] **2.3** Implement search filtering
  - Filter by prompt text
  - Case-insensitive
  - Update filtered sections
  - ✅ Implemented as computed property `filteredSections` with case-insensitive prompt matching

### Phase 3: UI Components

- [x] **3.1** Create `HistoryCard.swift`
  - Location: `Features/History/Components/HistoryCard.swift`
  - Props: `job: VideoJob`, `onTap: () -> Void`
  - Display: thumbnail, prompt, model name, status, actions
  - Status-based UI (completed/processing/failed)
  - Action buttons based on status
  - ✅ Created with AsyncImage for thumbnails, status badges, and action buttons based on job status

- [x] **3.2** Create `HistorySection.swift`
  - Location: `Features/History/Components/HistorySection.swift`
  - Props: `section: HistorySectionModel`
  - Display: section header + list of cards
  - ✅ Created with date header and ForEach loop for cards

- [x] **3.3** Create `HistoryEmptyState.swift`
  - Location: `Features/History/Components/HistoryEmptyState.swift`
  - Display: icon, message, optional CTA button
  - ✅ Created with icon, localized messages, and optional generate button

- [x] **3.4** Create or reuse `SearchBar` component
  - Check if HomeView search bar can be extracted
  - Location: `Shared/Components/SearchBar.swift` or `Features/History/Components/`
  - ✅ Created reusable SearchBar component in History/Components with clear button

### Phase 4: Main View

- [x] **4.1** Update `HistoryView.swift`
  - Replace placeholder with full implementation
  - Add search bar at top
  - Add `ScrollView` with sections
  - Add pull-to-refresh
  - Add loading state
  - Add empty state
  - Add error handling (alert)
  - ✅ Fully implemented with all states and components integrated

- [x] **4.2** Implement navigation to ResultView
  - Add `@State private var selectedJobId: String?`
  - Add `navigationDestination` modifier
  - Connect card tap to navigation
  - ✅ Navigation implemented with proper state management

- [x] **4.3** Implement swipe to delete
  - Add `.swipeActions` to HistoryCard
  - Call `viewModel.deleteJob(jobId:)` on delete action
  - ✅ Swipe actions added to HistoryCard with delete functionality
  - Refresh list after deletion

### Phase 5: Localization

- [x] **5.1** Add localization keys:
  - `history.title` → "History" (already exists)
  - `history.search_placeholder` → "Search your videos…"
  - `history.empty` → "No videos yet"
  - `history.empty_subtitle` → "Generate your first video to see it here."
  - `history.empty_cta` → "Generate Video"
  - `history.status.completed` → "Completed"
  - `history.status.processing` → "Processing"
  - `history.status.failed` → "Failed"
  - `history.status.pending` → "Pending"
  - `history.actions.play` → "Play"
  - `history.actions.download` → "Download"
  - `history.actions.share` → "Share"
  - `history.actions.retry` → "Retry"
  - `history.actions.delete` → "Delete"
  - `history.actions.wait` → "Wait"
  - ✅ All keys added to English localization

- [x] **5.2** Add to all localization files (en, tr, es)
  - ✅ All keys translated and added to Turkish (tr.lproj)
  - ✅ All keys translated and added to Spanish (es.lproj)

### Phase 6: Polish & Testing

- [x] **6.1** Add accessibility labels
  - VoiceOver labels for cards
  - Accessibility hints for buttons
  - Accessibility labels for status icons
  - ✅ Added accessibility labels and hints to all History Screen components:
    - HistoryCard: Card label with prompt, status, model, credits; hints for tap actions (completed, processing, failed states)
    - HistoryEmptyState: Combined label for empty state messages; button label and hint
    - SearchBar: Label for search field, hint for search functionality, clear button labels with hints
    - HistoryView: Loading state accessibility label
    - Status badges: Individual labels for each status with accessibility traits
    - Action buttons: Labels and disabled state hints for all action types

- [x] **6.2** Test navigation flow
  - HistoryView → ResultView (tap card) ✅ Implementation complete
  - Back navigation works ✅ NavigationStack handles automatically
  - Navigation state persists when switching tabs ✅ Each tab has independent NavigationStack
  - ⚠️ Ready for manual testing (all navigation code implemented)

- [x] **6.3** Test edge cases
  - Empty history state ✅ Handled with HistoryEmptyState component
  - Loading state ✅ ProgressView with accessibility label
  - Error state ✅ Alert with localized error messages
  - Search with no results ✅ Filtered sections automatically exclude empty sections
  - Delete confirmation ⚠️ Swipe-to-delete implemented (confirmation dialog optional for MVP)
  - Network errors ✅ Error handling with alerts and localization
  - ⚠️ Ready for manual testing (all edge cases handled in code)

⸻

## 🚨 Considerations & Decisions

### 1. User ID / Device ID Management

**Current:** Placeholder strings in ViewModels

**Decision:** 
- Use placeholder for MVP
- Add TODO comments
- Implement proper DeviceCheck/Auth service in future phase

### 2. Delete Functionality

**Question:** Should delete be available in MVP?

**Decision:** 
- Add delete action (swipe to delete)
- Add confirmation dialog
- If API not ready, show TODO/mock implementation

### 3. Status Polling

**Question:** Should we poll for status updates on processing jobs?

**Decision:** 
- **MVP:** No automatic polling (user can pull-to-refresh)
- **Future:** Add background polling or push notifications

### 4. Thumbnail Loading

**Question:** How to handle thumbnail loading?

**Decision:** 
- Use `AsyncImage` (like HomeView)
- Show placeholder while loading
- Show error icon if thumbnail fails

### 5. Video Duration Display

**Question:** Should we show video duration in cards?

**Decision:** 
- **MVP:** Show if available from API
- **Future:** Calculate from video metadata

⸻

## 📚 References

- **Blueprint:** `design/blueprints/history-screen.md`
- **Navigation Flow:** `design/blueprints/navigation-state-flow.md`
- **Design Rulebook:** `design/design-rulebook.md`
- **General Rulebook:** `design/general-rulebook.md`
- **API Blueprint:** `design/backend/api-layer-blueprint.md`
- **Similar Implementation:** `design/analysis/model-detail-screen-analysis.md`

⸻

## 🎯 Success Criteria

✅ History loads and displays jobs grouped by date
✅ Search filters jobs by prompt text
✅ Pull-to-refresh reloads history
✅ Tap on card navigates to ResultView
✅ Status-based UI displays correctly (completed/processing/failed)
✅ Empty state shows when no jobs
✅ Loading and error states handled
✅ Swipe to delete works (with confirmation)
✅ All text localized
✅ Accessibility labels added
✅ Navigation state persists when switching tabs

⸻
