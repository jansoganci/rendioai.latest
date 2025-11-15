// MARK: - ViewModel Template
// Copy this template when creating a new ViewModel

import Foundation
import Combine

/// ViewModel for [Feature Name] screen
/// Handles [brief description of responsibilities]
@MainActor
class FeatureNameViewModel: ObservableObject {

    // MARK: - Published Properties (State)

    /// Current loading state of the view
    @Published private(set) var state: LoadingState<DataModel> = .loading

    /// Example: List of items to display
    @Published private(set) var items: [Item] = []

    /// Example: Search query
    @Published var searchQuery: String = ""

    /// Example: Selected filter
    @Published var selectedFilter: FilterType = .all

    /// Example: Loading indicator for secondary operations
    @Published var isProcessing: Bool = false

    /// Example: Error message to display
    @Published var errorMessage: String?

    // MARK: - Dependencies

    /// Service for data operations
    private let dataService: DataServiceProtocol

    /// Example: Additional service dependency
    private let analyticsService: AnalyticsServiceProtocol?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Example: Debounce timer for search
    private var searchDebounceTimer: Timer?

    // MARK: - Initialization

    /// Initialize the ViewModel with required dependencies
    /// - Parameters:
    ///   - dataService: Service for fetching data
    ///   - analyticsService: Optional analytics service
    init(
        dataService: DataServiceProtocol,
        analyticsService: AnalyticsServiceProtocol? = nil
    ) {
        self.dataService = dataService
        self.analyticsService = analyticsService

        setupBindings()
    }

    // MARK: - Public Methods (Called by View)

    /// Load initial data when view appears
    func loadData() {
        state = .loading

        Task {
            do {
                let data = try await dataService.fetchData()
                state = .loaded(data)
                items = data.items

                // Optional: Track analytics
                analyticsService?.track(event: "data_loaded")

            } catch {
                let appError = AppError.from(error)
                state = .error(appError)
                errorMessage = appError.localizedDescription

                // Optional: Track error
                analyticsService?.track(event: "data_load_failed", properties: [
                    "error": error.localizedDescription
                ])
            }
        }
    }

    /// Refresh data (called on pull-to-refresh)
    func refresh() async {
        do {
            let data = try await dataService.fetchData()
            state = .loaded(data)
            items = data.items
        } catch {
            // Don't change state on refresh error, just show message
            errorMessage = AppError.from(error).localizedDescription
        }
    }

    /// Handle user action (e.g., button tap, selection)
    func performAction() {
        isProcessing = true

        Task {
            do {
                try await dataService.performAction()
                isProcessing = false

                // Reload data after action
                await loadData()

            } catch {
                isProcessing = false
                errorMessage = AppError.from(error).localizedDescription
            }
        }
    }

    /// Handle search query changes
    func search(query: String) {
        searchQuery = query

        // Debounce search
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performSearch()
            }
        }
    }

    /// Handle filter selection
    func selectFilter(_ filter: FilterType) {
        selectedFilter = filter
        Task {
            await loadData()
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// Set up Combine bindings for reactive updates
    private func setupBindings() {
        // Example: React to search query changes
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task { @MainActor [weak self] in
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)

        // Example: React to filter changes
        $selectedFilter
            .dropFirst() // Ignore initial value
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    /// Perform search with current query
    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            await loadData()
            return
        }

        state = .loading

        do {
            let results = try await dataService.search(query: searchQuery)
            state = .loaded(results)
            items = results.items
        } catch {
            state = .error(AppError.from(error))
        }
    }
}

// MARK: - Supporting Types

/// Generic loading state enum
enum LoadingState<T> {
    case loading
    case loaded(T)
    case error(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: AppError? {
        if case .error(let error) = self { return error }
        return nil
    }

    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
}

/// Example filter type
enum FilterType: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
}

// MARK: - Models (Example)

/// Example data model
struct DataModel: Codable {
    let items: [Item]
    let metadata: Metadata?
}

struct Item: Codable, Identifiable {
    let id: String
    let name: String
    let status: String
}

struct Metadata: Codable {
    let total: Int
    let page: Int
}

// MARK: - Service Protocol (Example)

/// Protocol for data service (enables testing)
protocol DataServiceProtocol {
    func fetchData() async throws -> DataModel
    func search(query: String) async throws -> DataModel
    func performAction() async throws
}

/// Protocol for analytics service
protocol AnalyticsServiceProtocol {
    func track(event: String, properties: [String: Any]?)
}

// MARK: - Usage Example

/*

 // In View:

 struct FeatureNameView: View {
     @StateObject private var viewModel: FeatureNameViewModel

     init() {
         _viewModel = StateObject(wrappedValue: FeatureNameViewModel(
             dataService: DataService(),
             analyticsService: AnalyticsService()
         ))
     }

     var body: some View {
         VStack {
             switch viewModel.state {
             case .loading:
                 ProgressView()

             case .loaded(let data):
                 List(viewModel.items) { item in
                     Text(item.name)
                 }

             case .error(let error):
                 ErrorView(error: error) {
                     viewModel.loadData()
                 }
             }
         }
         .searchable(text: $viewModel.searchQuery)
         .onAppear {
             viewModel.loadData()
         }
     }
 }

 */

// MARK: - Testing Example

/*

 import XCTest

 class FeatureNameViewModelTests: XCTestCase {
     var viewModel: FeatureNameViewModel!
     var mockService: MockDataService!

     override func setUp() {
         super.setUp()
         mockService = MockDataService()
         viewModel = FeatureNameViewModel(
             dataService: mockService
         )
     }

     func testLoadData_Success() async {
         // Arrange
         let expectedData = DataModel(items: [], metadata: nil)
         mockService.mockData = expectedData

         // Act
         await viewModel.loadData()

         // Assert
         XCTAssertEqual(viewModel.state.data?.items.count, 0)
     }

     func testLoadData_Error() async {
         // Arrange
         mockService.shouldThrowError = true

         // Act
         await viewModel.loadData()

         // Assert
         XCTAssertNotNil(viewModel.state.error)
     }
 }

 class MockDataService: DataServiceProtocol {
     var mockData: DataModel?
     var shouldThrowError = false

     func fetchData() async throws -> DataModel {
         if shouldThrowError {
             throw AppError.networkError
         }
         return mockData ?? DataModel(items: [], metadata: nil)
     }

     func search(query: String) async throws -> DataModel {
         return mockData ?? DataModel(items: [], metadata: nil)
     }

     func performAction() async throws {
         if shouldThrowError {
             throw AppError.unknownError
         }
     }
 }

 */
