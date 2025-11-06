# 🧪 Testing & Scalability Context — Rendio AI

**Purpose:** Quick reference for testing patterns, dependency injection, scalability approaches.

**Sources:** `design/general-rulebook.md`, `design/backend/api-adapter-interface.md`

---

## 🧪 Testing Structure

**Folder Organization:**
```
Features/
├── Home/
│   ├── HomeView.swift
│   ├── HomeViewModel.swift
│   └── Tests/
│       └── HomeViewModelTests.swift
```

**Unit Testing Pattern:**
```swift
import XCTest
@testable import RendioAI

class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockVideoService: MockVideoService!
    
    override func setUp() {
        super.setUp()
        mockVideoService = MockVideoService()
        viewModel = HomeViewModel(videoService: mockVideoService)
    }
    
    func testLoadModels() async {
        // Given
        let expectedModels = [VideoModel(id: "1", name: "Test Model")]
        mockVideoService.modelsToReturn = expectedModels
        
        // When
        await viewModel.loadModels()
        
        // Then
        XCTAssertEqual(viewModel.models.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

---

## 🔌 Dependency Injection for Testing

**Injectable Services:**
```swift
// ✅ DO: Inject dependencies
class HomeViewModel: ObservableObject {
    private let videoService: VideoGenerationService
    
    init(videoService: VideoGenerationService = .shared) {
        self.videoService = videoService
    }
}

// ❌ DON'T: Hard-code dependencies
class HomeViewModel: ObservableObject {
    private let videoService = VideoGenerationService.shared  // Hard to test
}
```

**Mock Implementation:**
```swift
class MockVideoService: VideoGenerationServiceProtocol {
    var modelsToReturn: [VideoModel] = []
    var shouldFail = false
    
    func fetchAvailableModels() async throws -> [VideoModel] {
        if shouldFail { throw AppError.networkFailure }
        return modelsToReturn
    }
}
```

---

## 🚀 Scalability Patterns

**1. Adapter Pattern (New Providers)**
- Add new provider → implement `VideoGenerationProvider` protocol
- No changes to app logic or existing code
- See: `design/backend/api-adapter-interface.md`

**2. Feature Flags**
- Store in Supabase `app_features` table
- Enable gradual rollouts without code deployment

**3. Modular Architecture**
- Features are self-contained (no cross-imports)
- New features don't affect existing code
- Clear boundaries: Features/ vs Core/ vs Shared/

**4. Protocol-Oriented Design**
- Services use protocols → easily swappable/mockable
- Example: `ApiServiceProtocol` → `ApiService` or `MockApiService`

---

## 📋 Testing Checklist

**Unit Tests:**
- ✅ ViewModels (business logic, state management)
- ✅ Services (API calls, data transformation)
- ✅ Models (Codable decoding/encoding)

**UI Tests (Optional):**
- Critical user flows (onboarding, video generation)
- Error states (network failures, insufficient credits)

**Code Quality:**
- ✅ 0 warnings in production builds
- ✅ No `print()` statements → use `Logger.shared.debug(_:)`
- ✅ No force unwraps

---

## 🔮 Future-Proofing

**Credit System:**
- Extensible to "token tiers" (free, premium, pro)
- Dynamic pricing per model (via `models.cost_per_generation`)

**Model Integration:**
- Text-to-Video, Image-to-Video, Reference-to-Video
- All use same adapter pattern

**Storage:**
- 7-day auto-cleanup (see `design/operations/data-retention-policy.md`)
- Scalable to cloud storage extension (Phase 5)

---

## 📚 References

- Testing patterns: `design/general-rulebook.md` (Section 9)
- Adapter pattern: `design/backend/api-adapter-interface.md`
- Data retention: `design/operations/data-retention-policy.md`
