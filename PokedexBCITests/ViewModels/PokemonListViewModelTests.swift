import XCTest
import Combine
import SwiftData
@testable import PokedexBCI

// MARK: - PokemonListViewModel Tests
/// Comprehensive test suite for the PokemonListViewModel, covering all critical paths:
///
/// 1. Network operations and state transitions
/// 2. Cache read/write operations 
/// 3. Search functionality and filtering
/// 4. Error handling and resilience
/// 5. Memory management during cancelled operations
///
/// These tests validate both the public interfaces and ensure internal state consistency
/// throughout the full lifecycle of the ViewModel.
@MainActor
final class PokemonListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    /// The system under test
    private var sut: PokemonListViewModel!
    
    /// The mock network manager used for testing
    private var mockNetworkManager: TestNetworkManager!
    
    // MARK: - Setup & Teardown
    
    /// Shared model container for all tests
    static var modelContainer: ModelContainer!
    
    /// Set up the test environment once before all tests
    override class func setUp() {
        super.setUp()
        
        // Create an in-memory SwiftData container for testing
        do {
            // Use an in-memory configuration for tests
            let schema = Schema([PokemonCache.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // This is a critical failure that should halt tests
            fatalError("❌ Failed to create in-memory test database: \(error)")
        }
    }
    
    /// Set up before each test
    override func setUp() {
        super.setUp()
        
        // Create a fresh mock network manager for each test
        mockNetworkManager = TestNetworkManager()
        
        // Create a fresh view model for each test
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: mockNetworkManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // Add this verification to ensure SUT is always initialized
        XCTAssertNotNil(sut, "SUT should not be nil after setUp")
        XCTAssertNotNil(mockNetworkManager, "Mock network manager should not be nil after setUp")
    }
    
    /// Tear down after each test
    override func tearDown() {
        // Clean up
        sut = nil
        mockNetworkManager = nil
        super.tearDown()
    }
    
    /// Helper method to configure the mock network manager
    private func setupMockNetworkManager(success: Bool, mockData: PokemonListResponse?) {
        mockNetworkManager.shouldSucceed = success
        if let mockData = mockData {
            mockNetworkManager.customPokemonList = mockData
        }
    }
    
    // MARK: - Integration Tests
    
    /// Integration test using the shared test infrastructure
    /// Validates end-to-end flow from network request to state update
    @MainActor
    func testFetchPokemonWithSharedTestInfrastructure() async throws {
        try await setUpAsync()
        
        // Use TestNetworkManager with default mock data
        let dataProvider = DefaultMockDataProvider()
        let customResponse = try dataProvider.providePokemonList()
        let mockPokemon = try dataProvider.providePokemonDetail(id: 1)
        
        // Setup test dependencies
        let networkManager = CustomDetailNetworkManager(mockDetail: mockPokemon, shouldSucceed: true, customList: customResponse)
        let testViewModel = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: networkManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // Act
        await testViewModel.fetchPokemon()
        
        // Add delay to ensure async operations complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Assert
        if case .loaded(let pokemonList) = testViewModel.state {
            XCTAssertEqual(pokemonList.count, customResponse.results.count)
            XCTAssertEqual(pokemonList.first?.name, customResponse.results.first?.name)
        } else {
            XCTFail("Expected loaded state but got \(testViewModel.state)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to clear the cache before tests
    @MainActor private func clearCache() async throws {
        let descriptor = FetchDescriptor<PokemonCache>()
        let existingCache = try Self.modelContainer.mainContext.fetch(descriptor)
        existingCache.forEach { Self.modelContainer.mainContext.delete($0) }
        try Self.modelContainer.mainContext.save()
    }
    
    /// Helper method to set up a special network manager that fails for specific Pokemon
    private func createPartialFailureNetworkManager() -> TestNetworkManager {
        let manager = PartialFailureNetworkManager()
        manager.shouldSucceed = true
        return manager
    }
    
    /// Helper to set up a network manager that fails for all Pokemon details
    private func createAllFailNetworkManager() -> TestNetworkManager {
        let manager = AllFailNetworkManager()
        manager.shouldSucceed = true
        return manager
    }
    
    // MARK: - State Observation Helpers
    
    /// Helper to wait for a specific state in the view model
    @MainActor
    private func waitForState<T>(_ stateCase: @escaping (PokemonListState) -> T?, 
                               description: String,
                               timeout: TimeInterval = 5.0) async -> (T?, [PokemonListState]) {
        let expectation = XCTestExpectation(description: description)
        var receivedStates: [PokemonListState] = []
        var matchedValue: T?
        
        let cancellable = sut.$state
            .sink { state in
                receivedStates.append(state)
                if let value = stateCase(state) {
                    matchedValue = value
                    expectation.fulfill()
                }
            }
        
        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()
        
        return (matchedValue, receivedStates)
    }
    
    /// Helper to wait for loading state
    @MainActor
    private func waitForLoadingState(timeout: TimeInterval = 5.0) async -> [PokemonListState] {
        let (_, states) = await waitForState({ state in
            if case .loading = state { return true }
            return nil
        }, description: "Wait for loading state", timeout: timeout)
        return states
    }
    
    /// Helper to wait for loaded state
    @MainActor
    private func waitForLoadedState(timeout: TimeInterval = 5.0) async -> [Pokemon]? {
        let expectation = XCTestExpectation(description: "Wait for loaded state")
        var loadedPokemon: [Pokemon]? = nil
        
        let cancellable = sut.$state
            .sink { state in
                if case .loaded(let pokemon) = state {
                    loadedPokemon = pokemon
                    expectation.fulfill()
                }
            }
        
        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()
        
        return loadedPokemon
    }
    
    /// Helper to wait for error state
    @MainActor
    private func waitForErrorState(timeout: TimeInterval = 5.0) async -> String? {
        let expectation = XCTestExpectation(description: "Wait for error state")
        var errorMessage: String? = nil
        
        let cancellable = sut.$state
            .sink { state in
                if case .error(let message) = state {
                    errorMessage = message
                    expectation.fulfill()
                }
            }
        
        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()
        
        return errorMessage
    }
    
    /// Helper method to set up the test asynchronously
    @MainActor private func setUpAsync() async throws {
        if sut == nil {
            mockNetworkManager = TestNetworkManager()
            mockNetworkManager.shouldSucceed = true
            
            sut = PokemonListViewModel(
                modelContainer: Self.modelContainer,
                networkManager: mockNetworkManager,
                cacheLoadingStrategy: TestCacheStrategy()
            )
        }
        
        XCTAssertNotNil(sut, "SUT should not be nil after setUpAsync")
        XCTAssertNotNil(mockNetworkManager, "Mock network manager should not be nil after setUpAsync")
    }
}

// MARK: - Custom Network Managers for Testing

/// A custom network manager for testing detail fetch
class CustomDetailNetworkManager: NetworkManagerProtocol {
    var mockDetail: Pokemon
    var shouldSucceed: Bool
    var customPokemonList: PokemonListResponse?
    var cancelAllRequestsCalled = false
    
    init(mockDetail: Pokemon, shouldSucceed: Bool = true, customList: PokemonListResponse? = nil) {
        self.mockDetail = mockDetail
        self.shouldSucceed = shouldSucceed
        self.customPokemonList = customList
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        if !shouldSucceed {
            throw TestNetworkError.configuredError
        }
        // Return custom list if provided, otherwise create default
        if let customList = customPokemonList {
            return customList
        } else {
            let items = (1..<10).map { id in
                PokemonListItem(
                    name: "pokemon\(id)",
                    url: "https://pokeapi.co/api/v2/pokemon/\(id)/"
                )
            }
            return PokemonListResponse(count: items.count, results: items)
        }
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        if !shouldSucceed {
            throw TestNetworkError.configuredError
        }
        return mockDetail
    }
    
    /// Cancels all ongoing network requests - mock implementation for testing
    func cancelAllRequests() {
        cancelAllRequestsCalled = true
        print("🧪 CustomDetailNetworkManager: cancelAllRequests called")
    }
}

/// Network manager that fails for specific Pokemon (even-numbered IDs)
class PartialFailureNetworkManager: TestNetworkManager {
    override func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        if id % 2 == 0 {
            throw TestNetworkError.invalidResponse
        }
        return try await super.fetchPokemonDetail(id: id)
    }
}

/// Network manager that fails for all Pokemon details
class AllFailNetworkManager: TestNetworkManager {
    override func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        throw TestNetworkError.invalidResponse
    }
}

/// Network manager that tracks calls for testing guard conditions
class NetworkManagerSpy: TestNetworkManager {
    var fetchPokemonListCallCount = 0
    var cancelAllRequestsCallCount = 0
    var fetchPokemonDetailCallCount = 0
    var isInProgress = false
    
    override func fetchPokemonList() async throws -> PokemonListResponse {
        fetchPokemonListCallCount += 1
        isInProgress = true
        
        // Add a small delay to ensure we have time to test the guard condition
        do {
            // Sleep long enough for the test to be able to cancel
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Check if we've been cancelled during the sleep
            if Task.isCancelled || !isInProgress {
                // If cancelled, throw a cancellation error
                throw CancellationError()
            }
            
            isInProgress = false
            return try await super.fetchPokemonList()
        } catch is CancellationError {
            // Handle cancellation by throwing an expected error
            isInProgress = false
            throw CancellationError()
        } catch {
            isInProgress = false
            throw error
        }
    }
    
    override func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        fetchPokemonDetailCallCount += 1
        return try await super.fetchPokemonDetail(id: id)
    }
    
    override func cancelAllRequests() {
        cancelAllRequestsCallCount += 1
        isInProgress = false
        super.cancelAllRequests()
        print("🧪 NetworkManagerSpy: cancelAllRequests called (\(cancelAllRequestsCallCount) times)")
    }
}

// MARK: - Additional Test Managers

/// Network manager that returns specific Network Errors
class NetworkErrorTestManager: NetworkManagerProtocol {
    let specificError: NetworkError
    
    init(specificError: NetworkError) {
        self.specificError = specificError
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        throw specificError
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        throw specificError
    }
    
    func cancelAllRequests() {
        // No-op for this test
    }
}

/// Network manager that simulates retry behavior (fails once, then succeeds)
class RetryTestNetworkManager: NetworkManagerProtocol {
    var fetchCallCount = 0
    private let dataProvider = DefaultMockDataProvider()
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        fetchCallCount += 1
        print("🧪 RetryTestNetworkManager: fetchPokemonList call #\(fetchCallCount)")
        
        // Add some delay to simulate network latency
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        if fetchCallCount == 1 {
            // First call fails with a retryable error
            print("🧪 RetryTestNetworkManager: First call fails with timeout")
            throw NetworkError.timeout
        }
        
        // Subsequent calls succeed
        print("🧪 RetryTestNetworkManager: Call #\(fetchCallCount) succeeds")
        
        let response = try dataProvider.providePokemonList()
        // For test purposes, make sure we have a small number of Pokemon to load
        let limitedResponse = PokemonListResponse(
            count: 3,
            results: Array(response.results.prefix(3))
        )
        return limitedResponse
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        // Always succeed for Pokemon details to simplify the test
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        return try dataProvider.providePokemonDetail(id: id)
    }
    
    func cancelAllRequests() {
        // No-op for this test
        print("🧪 RetryTestNetworkManager: cancelAllRequests called (no-op)")
    }
}

/// Network manager that returns specific TestNetworkError
class TestErrorManager: NetworkManagerProtocol {
    let specificError: TestNetworkError
    
    init(specificError: TestNetworkError) {
        self.specificError = specificError
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        throw specificError
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        throw specificError
    }
    
    func cancelAllRequests() {
        // No-op for this test
    }
}

// MARK: - Additional Test Helpers

/// Network manager that adds long delays for cancellation testing
class DelayNetworkManager: NetworkManagerProtocol {
    var cancelCalled = false
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        // Sleep for a long time to ensure the operation can be cancelled
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        return PokemonListResponse(count: 0, results: [])
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        // Sleep for a long time to ensure the operation can be cancelled
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        throw NetworkError.timeout // Should never reach this
    }
    
    func cancelAllRequests() {
        cancelCalled = true
        print("🧪 DelayNetworkManager: cancelAllRequests called")
    }
} 

