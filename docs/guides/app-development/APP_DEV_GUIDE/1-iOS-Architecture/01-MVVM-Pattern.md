# MVVM Pattern in SwiftUI

## Overview

MVVM (Model-View-ViewModel) is the recommended architecture pattern for SwiftUI apps. It provides clear separation of concerns and makes your code testable.

## The Three Layers

```
┌──────────────────────────────────────────────────────────┐
│  View (SwiftUI)                                          │
│  - User interface                                        │
│  - Displays data                                         │
│  - Sends user actions to ViewModel                       │
└────────────────────┬─────────────────────────────────────┘
                     │ @StateObject / @ObservedObject
                     ↓
┌──────────────────────────────────────────────────────────┐
│  ViewModel                                               │
│  - Business logic                                        │
│  - State management (@Published properties)              │
│  - Coordinates Services                                  │
│  - Transforms data for View                              │
└────────────────────┬─────────────────────────────────────┘
                     │ Dependency Injection
                     ↓
┌──────────────────────────────────────────────────────────┐
│  Model + Services                                        │
│  - Data structures (Codable)                             │
│  - Network calls                                         │
│  - Database operations                                   │
│  - Business rules                                        │
└──────────────────────────────────────────────────────────┘
```

---

## 1. Model Layer

### Purpose
- Define data structures
- Match backend API schemas
- Handle encoding/decoding

### Example: VideoJob Model

```swift
// MARK: - Model
struct VideoJob: Codable, Identifiable {
    let id: String
    let userId: String
    let prompt: String
    let status: JobStatus
    let videoUrl: String?
    let creditsUsed: Int
    let createdAt: Date

    // Map Swift naming to backend snake_case
    enum CodingKeys: String, CodingKey {
        case id = "job_id"
        case userId = "user_id"
        case prompt
        case status
        case videoUrl = "video_url"
        case creditsUsed = "credits_used"
        case createdAt = "created_at"
    }
}

enum JobStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}
```

### Key Points
- ✅ **Use Codable** for automatic JSON parsing
- ✅ **Use CodingKeys** to map snake_case backend fields to camelCase Swift properties
- ✅ **Make models immutable** (use `let` instead of `var`)
- ✅ **Conform to Identifiable** for use in SwiftUI Lists

---

## 2. View Layer

### Purpose
- Display UI
- Observe ViewModel state
- Send user actions to ViewModel
- NO business logic

### Example: VideoResultView

```swift
// MARK: - View
struct VideoResultView: View {
    @StateObject private var viewModel: VideoResultViewModel

    init(jobId: String) {
        // Dependency injection via initializer
        _viewModel = StateObject(wrappedValue: VideoResultViewModel(
            jobId: jobId,
            resultService: ResultService()
        ))
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .loading:
                loadingView

            case .loaded(let job):
                videoPlayerView(job: job)

            case .error(let error):
                errorView(error: error)
            }
        }
        .onAppear {
            viewModel.loadVideo()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Generating your video...")
                .foregroundColor(.secondary)
        }
    }

    private func videoPlayerView(job: VideoJob) -> some View {
        VStack {
            VideoPlayer(url: job.videoUrl!)

            HStack {
                Button("Download") {
                    viewModel.downloadVideo()
                }

                Button("Share") {
                    viewModel.shareVideo()
                }
            }
        }
    }

    private func errorView(error: AppError) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text(error.localizedDescription)

            Button("Retry") {
                viewModel.loadVideo()
            }
        }
    }
}
```

### Key Points
- ✅ **Use @StateObject** for ViewModel ownership
- ✅ **Inject dependencies** via initializer
- ✅ **Use computed properties** for subviews (keeps body clean)
- ✅ **Handle all states** (loading, loaded, error)
- ❌ **Never call services directly** from View
- ❌ **Never put business logic** in View

---

## 3. ViewModel Layer

### Purpose
- Manage View state
- Execute business logic
- Coordinate Services
- Transform data for display

### Example: VideoResultViewModel

```swift
// MARK: - ViewModel
@MainActor
class VideoResultViewModel: ObservableObject {

    // MARK: - Published Properties (State)

    @Published private(set) var state: LoadingState<VideoJob> = .loading
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0

    // MARK: - Dependencies

    private let jobId: String
    private let resultService: ResultServiceProtocol

    // MARK: - Initialization

    init(
        jobId: String,
        resultService: ResultServiceProtocol
    ) {
        self.jobId = jobId
        self.resultService = resultService
    }

    // MARK: - Public Methods (Called by View)

    func loadVideo() {
        state = .loading

        Task {
            do {
                let job = try await resultService.getVideoStatus(jobId: jobId)

                if job.status == .completed {
                    state = .loaded(job)
                } else if job.status == .failed {
                    state = .error(.videoGenerationFailed)
                } else {
                    // Still processing, poll again
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await loadVideo() // Recursive polling
                }

            } catch {
                state = .error(AppError.from(error))
            }
        }
    }

    func downloadVideo() {
        guard case .loaded(let job) = state,
              let videoUrl = job.videoUrl else { return }

        isDownloading = true

        Task {
            do {
                try await resultService.downloadVideo(
                    url: videoUrl,
                    progress: { [weak self] progress in
                        self?.downloadProgress = progress
                    }
                )
                isDownloading = false
            } catch {
                isDownloading = false
                state = .error(AppError.from(error))
            }
        }
    }

    func shareVideo() {
        guard case .loaded(let job) = state,
              let videoUrl = job.videoUrl else { return }

        // Present share sheet (View will handle)
        // This is just state preparation
    }
}

// MARK: - Loading State

enum LoadingState<T> {
    case loading
    case loaded(T)
    case error(AppError)
}
```

### Key Points
- ✅ **Use @MainActor** to ensure UI updates on main thread
- ✅ **Use ObservableObject** protocol
- ✅ **Use @Published** for properties View observes
- ✅ **Use private(set)** to prevent View from modifying state
- ✅ **Inject dependencies** via initializer
- ✅ **Use protocols** for dependencies (enables testing)
- ✅ **Use Task** for async operations
- ✅ **Handle errors** gracefully
- ❌ **Never import SwiftUI** in ViewModel
- ❌ **Never reference UIKit** in ViewModel (except necessary types)

---

## Data Flow

### User Action → ViewModel → Service → Backend

```swift
// 1. User taps "Generate Video" button in View
Button("Generate Video") {
    viewModel.generateVideo()
}

// 2. ViewModel receives action
func generateVideo() {
    state = .loading

    Task {
        do {
            // 3. ViewModel calls Service
            let job = try await videoService.generateVideo(
                prompt: prompt,
                settings: settings
            )

            // 4. Service returns data
            // 5. ViewModel updates state
            state = .loaded(job)

        } catch {
            state = .error(AppError.from(error))
        }
    }
}

// 6. View automatically re-renders due to @Published state change
```

---

## Testing with MVVM

### Why MVVM is Testable

```swift
// MARK: - Test
class VideoResultViewModelTests: XCTestCase {

    var viewModel: VideoResultViewModel!
    var mockService: MockResultService!

    override func setUp() {
        super.setUp()

        // Inject mock service (no real network calls)
        mockService = MockResultService()
        viewModel = VideoResultViewModel(
            jobId: "test-job-id",
            resultService: mockService
        )
    }

    func testLoadVideo_Success() async {
        // Arrange
        let expectedJob = VideoJob(
            id: "test-job-id",
            status: .completed,
            videoUrl: "https://example.com/video.mp4"
        )
        mockService.mockVideoJob = expectedJob

        // Act
        await viewModel.loadVideo()

        // Assert
        if case .loaded(let job) = viewModel.state {
            XCTAssertEqual(job.id, expectedJob.id)
            XCTAssertEqual(job.status, .completed)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testLoadVideo_Error() async {
        // Arrange
        mockService.shouldThrowError = true

        // Act
        await viewModel.loadVideo()

        // Assert
        if case .error = viewModel.state {
            // Success - error state set
        } else {
            XCTFail("Expected error state")
        }
    }
}
```

---

## Common Patterns in RendioAI

### 1. Loading States

```swift
enum LoadingState<T> {
    case loading
    case loaded(T)
    case error(AppError)
}
```

### 2. Dependency Injection

```swift
// Production
let viewModel = HomeViewModel(
    modelService: ModelService(),
    creditService: CreditService()
)

// Testing
let viewModel = HomeViewModel(
    modelService: MockModelService(),
    creditService: MockCreditService()
)
```

### 3. Async Operations

```swift
func loadData() {
    state = .loading

    Task {
        do {
            let data = try await service.fetchData()
            state = .loaded(data)
        } catch {
            state = .error(AppError.from(error))
        }
    }
}
```

---

## Best Practices

### ✅ Do This

1. **Keep ViewModels focused**
   - One ViewModel per screen
   - Extract shared logic to Services

2. **Use protocols for Services**
   ```swift
   protocol VideoServiceProtocol {
       func generateVideo(...) async throws -> VideoJob
   }
   ```

3. **Handle all states**
   - Loading
   - Loaded
   - Error
   - Empty (if applicable)

4. **Make state immutable from View**
   ```swift
   @Published private(set) var videos: [Video] = []
   ```

5. **Use async/await**
   ```swift
   Task {
       let result = try await service.fetchData()
   }
   ```

### ❌ Don't Do This

1. **Don't put business logic in Views**
   ```swift
   // ❌ Bad
   Button("Submit") {
       let url = URL(string: "https://api.com/endpoint")!
       let request = URLRequest(url: url)
       // Network call in View
   }

   // ✅ Good
   Button("Submit") {
       viewModel.submit()
   }
   ```

2. **Don't access Models directly from Views**
   ```swift
   // ❌ Bad
   struct MyView: View {
       @State private var user: User?

       func loadUser() {
           // Direct API call
       }
   }

   // ✅ Good
   struct MyView: View {
       @StateObject private var viewModel: MyViewModel
   }
   ```

3. **Don't create retain cycles**
   ```swift
   // ❌ Bad
   Task {
       self.data = try await service.fetch() // Captures self strongly
   }

   // ✅ Good
   Task { [weak self] in
       self?.data = try await service.fetch()
   }
   ```

---

## File Organization

```
/Features/VideoResult/
├── VideoResultView.swift           # View
├── VideoResultViewModel.swift      # ViewModel
└── Models/
    └── VideoJob.swift              # Model

/Core/Services/
└── ResultService.swift             # Service (shared)
```

---

## Summary

| Layer | Responsibility | SwiftUI Tools |
|-------|----------------|---------------|
| **Model** | Data structures | `Codable`, `Identifiable` |
| **View** | UI presentation | `View`, `@StateObject` |
| **ViewModel** | Business logic, state | `ObservableObject`, `@Published` |

**Golden Rule:** Data flows down (ViewModel → View), Events flow up (View → ViewModel)

---

**Next:** [Project Structure →](02-Project-Structure.md)
