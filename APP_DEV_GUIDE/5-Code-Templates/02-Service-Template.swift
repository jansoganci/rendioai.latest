// MARK: - Service Template
// Copy this template when creating a new Service

import Foundation

// MARK: - Protocol Definition

/// Protocol defining the contract for [Service Name]
/// Used for dependency injection and testing
protocol FeatureServiceProtocol {
    /// Fetch data from the backend
    /// - Returns: The fetched data
    /// - Throws: AppError if the request fails
    func fetchData() async throws -> DataModel

    /// Create a new item
    /// - Parameter request: The creation request
    /// - Returns: The created item
    /// - Throws: AppError if creation fails
    func createItem(request: CreateItemRequest) async throws -> Item

    /// Update an existing item
    /// - Parameters:
    ///   - id: The item ID
    ///   - request: The update request
    /// - Returns: The updated item
    /// - Throws: AppError if update fails
    func updateItem(id: String, request: UpdateItemRequest) async throws -> Item

    /// Delete an item
    /// - Parameter id: The item ID
    /// - Throws: AppError if deletion fails
    func deleteItem(id: String) async throws

    /// Search for items
    /// - Parameter query: The search query
    /// - Returns: Matching items
    /// - Throws: AppError if search fails
    func search(query: String) async throws -> [Item]
}

// MARK: - Production Implementation

/// Production implementation of FeatureServiceProtocol
/// Makes real API calls to the backend
class FeatureService: FeatureServiceProtocol {

    // MARK: - Dependencies

    /// API client for making HTTP requests
    private let apiClient: APIClientProtocol

    /// Optional analytics service
    private let analytics: AnalyticsServiceProtocol?

    // MARK: - Configuration

    /// Base endpoint path
    private let basePath = "/api/feature"

    // MARK: - Initialization

    /// Initialize the service with dependencies
    /// - Parameters:
    ///   - apiClient: API client for HTTP requests (default: shared instance)
    ///   - analytics: Optional analytics service
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        analytics: AnalyticsServiceProtocol? = nil
    ) {
        self.apiClient = apiClient
        self.analytics = analytics
    }

    // MARK: - Public Methods

    func fetchData() async throws -> DataModel {
        do {
            let response: DataModel = try await apiClient.request(
                endpoint: "\(basePath)/data",
                method: .GET
            )

            analytics?.track(event: "data_fetched", properties: [
                "item_count": response.items.count
            ])

            return response

        } catch let error as AppError {
            analytics?.track(event: "data_fetch_failed", properties: [
                "error": error.localizedDescription
            ])
            throw error

        } catch {
            throw AppError.networkError
        }
    }

    func createItem(request: CreateItemRequest) async throws -> Item {
        // Validate input
        guard !request.name.isEmpty else {
            throw AppError.validation("Name cannot be empty")
        }

        do {
            let response: Item = try await apiClient.request(
                endpoint: "\(basePath)/items",
                method: .POST,
                body: request
            )

            analytics?.track(event: "item_created", properties: [
                "item_id": response.id
            ])

            return response

        } catch {
            throw AppError.from(error)
        }
    }

    func updateItem(id: String, request: UpdateItemRequest) async throws -> Item {
        do {
            let response: Item = try await apiClient.request(
                endpoint: "\(basePath)/items/\(id)",
                method: .PUT,
                body: request
            )

            analytics?.track(event: "item_updated", properties: [
                "item_id": id
            ])

            return response

        } catch {
            throw AppError.from(error)
        }
    }

    func deleteItem(id: String) async throws {
        do {
            try await apiClient.request(
                endpoint: "\(basePath)/items/\(id)",
                method: .DELETE
            )

            analytics?.track(event: "item_deleted", properties: [
                "item_id": id
            ])

        } catch {
            throw AppError.from(error)
        }
    }

    func search(query: String) async throws -> [Item] {
        guard !query.isEmpty else {
            return []
        }

        do {
            let response: SearchResponse = try await apiClient.request(
                endpoint: "\(basePath)/search",
                method: .GET,
                queryParameters: ["q": query]
            )

            analytics?.track(event: "search_performed", properties: [
                "query": query,
                "result_count": response.items.count
            ])

            return response.items

        } catch {
            throw AppError.from(error)
        }
    }

    // MARK: - Private Helpers

    /// Validate common business rules
    private func validate(_ request: CreateItemRequest) throws {
        guard !request.name.isEmpty else {
            throw AppError.validation("Name is required")
        }

        guard request.name.count <= 100 else {
            throw AppError.validation("Name must be 100 characters or less")
        }
    }
}

// MARK: - Mock Implementation (for Testing)

/// Mock implementation for testing
/// Returns predefined data without making network calls
class MockFeatureService: FeatureServiceProtocol {

    // MARK: - Mock Data

    var mockData: DataModel?
    var mockItems: [Item] = []
    var mockError: AppError?

    // MARK: - Test Controls

    var shouldThrowError = false
    var fetchDataCallCount = 0
    var createItemCallCount = 0

    // MARK: - Protocol Implementation

    func fetchData() async throws -> DataModel {
        fetchDataCallCount += 1

        if shouldThrowError, let error = mockError {
            throw error
        }

        if let data = mockData {
            return data
        }

        // Default mock response
        return DataModel(
            items: mockItems,
            metadata: Metadata(total: mockItems.count, page: 1)
        )
    }

    func createItem(request: CreateItemRequest) async throws -> Item {
        createItemCallCount += 1

        if shouldThrowError, let error = mockError {
            throw error
        }

        let item = Item(
            id: UUID().uuidString,
            name: request.name,
            status: "active"
        )

        mockItems.append(item)
        return item
    }

    func updateItem(id: String, request: UpdateItemRequest) async throws -> Item {
        if shouldThrowError, let error = mockError {
            throw error
        }

        guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
            throw AppError.notFound
        }

        let updated = Item(
            id: id,
            name: request.name ?? mockItems[index].name,
            status: mockItems[index].status
        )

        mockItems[index] = updated
        return updated
    }

    func deleteItem(id: String) async throws {
        if shouldThrowError, let error = mockError {
            throw error
        }

        mockItems.removeAll { $0.id == id }
    }

    func search(query: String) async throws -> [Item] {
        if shouldThrowError, let error = mockError {
            throw error
        }

        return mockItems.filter { item in
            item.name.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Test Helpers

    func reset() {
        mockData = nil
        mockItems = []
        mockError = nil
        shouldThrowError = false
        fetchDataCallCount = 0
        createItemCallCount = 0
    }
}

// MARK: - Request/Response Models

struct CreateItemRequest: Codable {
    let name: String
    let description: String?
    let metadata: [String: String]?
}

struct UpdateItemRequest: Codable {
    let name: String?
    let description: String?
    let status: String?
}

struct SearchResponse: Codable {
    let items: [Item]
    let total: Int
}

// MARK: - Usage Example

/*

 // In ViewModel:

 class FeatureViewModel: ObservableObject {
     private let service: FeatureServiceProtocol

     init(service: FeatureServiceProtocol = FeatureService()) {
         self.service = service
     }

     func loadData() async {
         do {
             let data = try await service.fetchData()
             // Handle success
         } catch {
             // Handle error
         }
     }
 }

 // In Tests:

 class FeatureViewModelTests: XCTestCase {
     func testLoadData() async {
         let mockService = MockFeatureService()
         mockService.mockItems = [
             Item(id: "1", name: "Test", status: "active")
         ]

         let viewModel = FeatureViewModel(service: mockService)
         await viewModel.loadData()

         XCTAssertEqual(mockService.fetchDataCallCount, 1)
     }
 }

 */

// MARK: - Best Practices

/*

 1. Protocol-First Design
    - Always define protocol before implementation
    - Enables dependency injection and testing

 2. Error Handling
    - Convert all errors to AppError
    - Provide meaningful error messages
    - Track errors with analytics

 3. Input Validation
    - Validate before making API calls
    - Fail fast with clear messages

 4. Analytics
    - Track success and failure events
    - Include relevant metadata

 5. Mock Implementation
    - Provide realistic mock data
    - Allow tests to control behavior
    - Track method call counts

 6. Async/Await
    - Use async/await for all network calls
    - Handle cancellation gracefully
    - Avoid callback hell

 7. Configuration
    - Centralize endpoints
    - Use dependency injection for API client
    - Support multiple environments

 */
