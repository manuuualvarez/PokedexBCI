import XCTest
import Combine
import SwiftData
@testable import pokedex_pci

/// # PokemonListViewModel Test Suite
///
/// This test suite thoroughly verifies the functionality of PokemonListViewModel, ensuring 
/// all methods and edge cases are properly covered. The tests are organized by functionality
/// to ensure comprehensive coverage.
///
/// ## Test Categories:
///
/// 1. **Network and State Tests**
///    - Tests fetching Pokemon from the network
///    - Verifies proper state transitions during network operations
///    - Tests both success and failure scenarios
///
/// 2. **Basic Cache Tests**
///    - Tests the fundamental caching mechanism
///    - Verifies that Pokemon data is properly saved to cache
///
/// 3. **Cache Loading Tests**
///    - Tests loading data from valid cache
///    - Tests handling of multiple cached Pokemon
///    - Tests handling of expired cache
///    - Tests handling of empty cache
///    - Tests cache validation logic
///
/// 4. **State Management Tests**
///    - Tests direct state manipulation
///    - Tests Pokemon data setter methods
///
/// 5. **Search Tests**
///    - Tests search functionality with various inputs
///    - Tests filtering behavior with matches and no matches
///    - Tests clearing search
///
/// 6. **Detail Fetching Tests**
///    - Tests fetching individual Pokemon details
///    - Tests handling of network errors during detail fetch
///
/// 7. **Error Handling Tests**
///    - Tests how the ViewModel handles various error conditions
///    - Tests the loading guard condition to prevent multiple concurrent loads
///
/// 8. **Edge Case Tests**
///    - Tests behavior with empty arrays
///    - Tests cache update decision logic when valid cache exists
///
/// Each test is designed to be independent and focuses on a specific aspect of the ViewModel,
/// following best practices for unit testing.
///
/// ## IMPORTANT CONVERSION NOTE:
/// This file is being updated to use the shared testing infrastructure from the main app
/// instead of duplicated test mocks.
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
    
    /// Test fetching Pokemon with shared test infrastructure
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
    
    // MARK: - Helper Methods for Reducing Duplication
    
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
    
    /// Helper to verify state transitions include loading and loaded states
    private func verifySuccessStateTransitions(in states: [PokemonListState]) {
        XCTAssertTrue(states.contains { if case .loading = $0 { return true } else { return false } }, 
                     "Should have loading state")
        XCTAssertTrue(states.contains { if case .loaded = $0 { return true } else { return false } }, 
                     "Should have loaded state")
    }
    
    /// Helper to verify state transitions include loading and error states
    private func verifyErrorStateTransitions(in states: [PokemonListState]) {
        XCTAssertTrue(states.contains { if case .loading = $0 { return true } else { return false } }, 
                     "Should have loading state")
        XCTAssertTrue(states.contains { if case .error = $0 { return true } else { return false } }, 
                     "Should have error state")
    }
    
    /// Helper to create a valid cache entry with appropriate timestamps
    @MainActor
    private func createValidCacheEntry(from pokemon: Pokemon) -> PokemonCache {
        let cacheEntry = PokemonCache(from: pokemon)
        let now = Date()
        cacheEntry.lastUpdated = now.addingTimeInterval(-5 * 60) // 5 minutes ago
        cacheEntry.expiresAt = now.addingTimeInterval(30 * 60)   // 30 minutes from now (valid)
        return cacheEntry
    }
    
    /// Helper to create an expired cache entry
    @MainActor
    private func createExpiredCacheEntry(from pokemon: Pokemon) -> PokemonCache {
        let cacheEntry = PokemonCache(from: pokemon)
        let now = Date()
        cacheEntry.lastUpdated = now.addingTimeInterval(-30 * 60) // 30 minutes ago
        cacheEntry.expiresAt = now.addingTimeInterval(-5 * 60)    // 5 minutes ago (expired)
        return cacheEntry
    }
    
    /// Helper to reset the view model and test state
    @MainActor
    private func resetViewModelState() async throws {
        // Clear cache
        try await clearCache()
        
        // Reset view model state
        sut.setState(.idle)
        sut.setPokemon([])
    }
    
    /// Helper test method for search functionality
    @MainActor
    private func performSearchTest(
        initialPokemon: [Pokemon],
        searchText: String,
        expectedCount: Int,
        assertion: () -> Void
    ) async throws {
        // Ensure SUT is initialized
        guard let sut = sut else {
            XCTFail("SUT is nil")
            return
        }
        
        // Given
        try await clearCache()
        sut.setPokemon(initialPokemon)
        
        // When
        sut.searchText = searchText
        
        // Wait for debounce
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds (slightly more than debounce)
        
        // Then
        XCTAssertEqual(sut.filteredPokemon.count, expectedCount, 
                      "Should have \(expectedCount) Pokemon after search")
        assertion()
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
    
    // MARK: - Network and State Tests
    // Tests the network fetch functionality and state transitions during fetch operations
    
    /// Test successful Pokemon list fetch
    @MainActor
    func testFetchPokemonSuccess() async throws {
        // Given
        try await resetViewModelState()
        
        // Use the official DefaultMockDataProvider for test data
        let dataProvider = DefaultMockDataProvider()
        let mockList = try dataProvider.providePokemonList()
        
        // Verify test data is as expected - should be 6 Pokemon with proper names
        XCTAssertEqual(mockList.count, 6, "DefaultMockDataProvider should return 6 Pokemon")
        XCTAssertEqual(mockList.results[0].name, "bulbasaur", "First Pokemon should be bulbasaur")
        
        // Create a mock network manager with the proper data
        let testNetworkManager = TestNetworkManager.createWithCustomResponses(pokemonList: mockList)
        
        // Replace the SUT with one using our configured network manager
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: testNetworkManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // When
        await sut.fetchPokemon()
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, 6, "Should have 6 Pokemon")
        
        // Verify Pokemon details
        let pokemon = sut.filteredPokemon
        XCTAssertFalse(pokemon.isEmpty, "Should have Pokemon in the array")
        
        // Mapping of expected Pokemon names from the DefaultMockDataProvider
        let expectedPokemonNames = [
            1: "bulbasaur",
            2: "ivysaur",
            3: "venusaur",
            4: "charmander",
            5: "charmeleon",
            6: "charizard"
        ]
        
        // Check each Pokemon matches what's expected
        for i in 0..<pokemon.count {
            let pokemonId = i + 1
            XCTAssertEqual(pokemon[i].id, pokemonId, "Pokemon ID should match index")
            XCTAssertEqual(pokemon[i].name, expectedPokemonNames[pokemonId], "Pokemon name should match expected value")
        }
    }
    
    /// Test failed Pokemon list fetch
    @MainActor
    func testFetchPokemonFailure() async throws {
        // Given
        try await resetViewModelState()
        
        // Ensure our SUT is properly initialized before proceeding
        XCTAssertNotNil(sut, "SUT should not be nil")
        
        setupMockNetworkManager(success: false, mockData: nil)
        
        // When - use Task to ensure proper async execution
        let task = Task { await sut.fetchPokemon() }
        
        // Then
        let errorMessage = await waitForErrorState()
        XCTAssertNotNil(errorMessage, "Should have received an error message")
        XCTAssertTrue(sut.filteredPokemon.isEmpty, "Filtered Pokemon should be empty")
        
        // Ensure the task completes
        await task.value
    }
    
    /// Test the loading behavior with empty results from the API
    @MainActor
    func testEmptyPokemonResults() async throws {
        // Given
        try await resetViewModelState()
        
        // Ensure our SUT is properly initialized before proceeding
        XCTAssertNotNil(sut, "SUT should not be nil")
        
        // Set up empty results
        let emptyList = PokemonListResponse(count: 0, results: [])
        setupMockNetworkManager(success: true, mockData: emptyList)
        
        // When - use Task to ensure proper async execution
        let task = Task { await sut.fetchPokemon() }
        
        // Then
        let errorMessage = await waitForErrorState()
        
        // No Pokemon should be loaded
        XCTAssertTrue(sut.filteredPokemon.isEmpty, "No Pokemon should be loaded with empty results")
        XCTAssertEqual(errorMessage, "Failed to load Pokemon data", "Should have correct error message")
        
        // Ensure the task completes
        await task.value
    }
    
    // MARK: - Cache Tests
    // Tests the fundamental cache operations like saving and retrieving data
    
    /// Test caching a Pokemon and retrieving it
    @MainActor
    func testCacheBasicPokemon() async throws {
        // Given
        try await resetViewModelState()
        let dataProvider = DefaultMockDataProvider()
        let mockPokemon = try dataProvider.providePokemonDetail(id: 1)
        
        // When
        await sut.cachePokemon([mockPokemon])
        
        // Then
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        
        XCTAssertEqual(cachedItems.count, 1, "Should have cached 1 Pokemon")
        XCTAssertEqual(cachedItems.first?.id, mockPokemon.id, "Cached Pokemon should have correct ID")
        XCTAssertEqual(cachedItems.first?.name, mockPokemon.name, "Cached Pokemon should have correct name")
        XCTAssertTrue(cachedItems.first?.isValid ?? false, "Cached Pokemon should be valid")
    }
    
    // MARK: - Cache Loading Tests
    // Tests various scenarios for loading data from the cache
    
    /// Test loading Pokemon from cache when available
    @MainActor
    func testLoadFromCache() async throws {
        // Given
        try await resetViewModelState()
        
        // Create a Pokemon with unique ID and add to cache
        let dataProvider = DefaultMockDataProvider()
        let testId = 1 // Use a valid Pokemon ID
        let mockPokemon = try dataProvider.providePokemonDetail(id: testId)
        let cacheEntry = createValidCacheEntry(from: mockPokemon)
        
        // Insert into database
        Self.modelContainer.mainContext.insert(cacheEntry)
        try Self.modelContainer.mainContext.save()
        
        // Configure network manager to fail (should not be used)
        mockNetworkManager.shouldSucceed = false
        
        // When
        Task { await sut.loadCachedPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon from cache
        XCTAssertEqual(sut.filteredPokemon.count, 1, "Should have loaded 1 Pokemon from cache")
        XCTAssertEqual(sut.filteredPokemon.first?.id, testId, "Should have loaded Pokemon with correct ID")
        XCTAssertEqual(sut.filteredPokemon.first?.name, mockPokemon.name, "Should have loaded Pokemon with correct name")
    }
    
    /// Test loading from cache with multiple Pokemon
    @MainActor
    func testLoadFromCacheWithMultiplePokemon() async throws {
        // Given
        try await resetViewModelState()
        
        // Create multiple Pokemon and add to cache
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try (1...5).map { try dataProvider.providePokemonDetail(id: $0) }
        
        // Add to cache with valid timestamps
        for pokemon in mockPokemonList {
            let cacheEntry = createValidCacheEntry(from: pokemon)
            Self.modelContainer.mainContext.insert(cacheEntry)
        }
        try Self.modelContainer.mainContext.save()
        
        // Configure network manager to fail (should not be used)
        mockNetworkManager.shouldSucceed = false
        
        // When
        Task { await sut.loadCachedPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, 5, "Should have loaded 5 Pokemon from cache")
        
        // Check that Pokemon are sorted by ID
        if sut.filteredPokemon.count >= 5 {
            for i in 0..<5 {
                let expectedId = i + 1
                XCTAssertEqual(sut.filteredPokemon[i].id, expectedId, "Pokemon should be sorted by ID")
                XCTAssertEqual(sut.filteredPokemon[i].name, mockPokemonList[i].name, "Pokemon name should match expected value")
            }
        }
    }
    
    /// Test loading Pokemon when cache is expired
    @MainActor
    func testLoadFromExpiredCache() async throws {
        // Given
        try await resetViewModelState()
        
        // Ensure our SUT is properly initialized before proceeding
        XCTAssertNotNil(sut, "SUT should not be nil")
        
        // Create a Pokemon and expired cache entry
        let dataProvider = DefaultMockDataProvider()
        let pokemon = try dataProvider.providePokemonDetail(id: 1)
        let cache = createExpiredCacheEntry(from: pokemon)
                
        // Insert the expired cache
        Self.modelContainer.mainContext.insert(cache)
        try Self.modelContainer.mainContext.save()
        
        // Set up mock for network that will be used after expired cache
        let mockPokemonList = try dataProvider.providePokemonList() // Use real mock data
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.customPokemonList = mockPokemonList
        
        // When - use Task to ensure proper async execution
        let task = Task { await sut.loadCachedPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify network fetch happened by checking for expected Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, mockPokemonList.count, 
                       "Should have fetched correct number of Pokemon from network after expired cache")
        
        // Verify the cache was updated with new data
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(cachedItems.count, mockPokemonList.count, "Should have updated cache entries")
        XCTAssertTrue(cachedItems.allSatisfy { $0.isValid }, "All cache entries should be valid")
        
        // Ensure the task completes
        await task.value
    }
    
    /// Test loading when cache is empty
    @MainActor
    func testLoadFromEmptyCache() async throws {
        // Given
        try await resetViewModelState()
        
        // Ensure our SUT is properly initialized before proceeding
        XCTAssertNotNil(sut, "SUT should not be nil")
        
        // Verify the cache is empty
        let initialDescriptor = FetchDescriptor<PokemonCache>()
        let initialCache = try Self.modelContainer.mainContext.fetch(initialDescriptor)
        XCTAssertEqual(initialCache.count, 0, "Cache should be empty before test")
        
        // Set up mock data using DefaultMockDataProvider
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try dataProvider.providePokemonList()
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.customPokemonList = mockPokemonList
        
        // When - use Task to ensure proper async execution
        let task = Task { await sut.loadCachedPokemon() }
    
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, mockPokemonList.count, "Should have correct number of Pokemon from network")
        
        // Verify the cache was created
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(cachedItems.count, mockPokemonList.count, "Should have correct number of new cache entries")
        
        // Ensure the task completes
        await task.value
    }
    
    /// Test direct validation of cache entries
    @MainActor
    func testCacheValidation() throws {
        // Create a Pokemon
        let dataProvider = DefaultMockDataProvider()
        let mockPokemon = try dataProvider.providePokemonDetail(id: 1)
        
        // Create valid cache entry
        let validCache = PokemonCache(from: mockPokemon)
        let now = Date()
        validCache.lastUpdated = now
        validCache.expiresAt = now.addingTimeInterval(15 * 60)
        
        // It should be valid
        XCTAssertTrue(validCache.isValid, "Cache entry should be valid")
        
        // Create invalid entries
        
        // 1. Expired
        let expiredCache = PokemonCache(from: mockPokemon)
        expiredCache.lastUpdated = now.addingTimeInterval(-30 * 60) // 30 minutes ago
        expiredCache.expiresAt = now.addingTimeInterval(-5 * 60)    // 5 minutes ago
        XCTAssertFalse(expiredCache.isValid, "Expired cache entry should be invalid")
        
        // 2. Zero ID
        let zeroIdCache = PokemonCache(from: mockPokemon)
        zeroIdCache.id = 0
        XCTAssertFalse(zeroIdCache.isValid, "Cache with zero ID should be invalid")
        
        // 3. Empty name
        let emptyNameCache = PokemonCache(from: mockPokemon)
        emptyNameCache.name = ""
        XCTAssertFalse(emptyNameCache.isValid, "Cache with empty name should be invalid")
        
        // 4. Empty sprite URL
        let emptySpriteCache = PokemonCache(from: mockPokemon)
        emptySpriteCache.spriteURL = ""
        XCTAssertFalse(emptySpriteCache.isValid, "Cache with empty sprite URL should be invalid")
        
        // 5. Future lastUpdated
        let futureUpdateCache = PokemonCache(from: mockPokemon)
        futureUpdateCache.lastUpdated = now.addingTimeInterval(60 * 60) // 1 hour in future
        XCTAssertFalse(futureUpdateCache.isValid, "Cache with future lastUpdated should be invalid")
        
        // 6. expiresAt before lastUpdated
        let invalidExpiryCache = PokemonCache(from: mockPokemon)
        invalidExpiryCache.lastUpdated = now
        invalidExpiryCache.expiresAt = now.addingTimeInterval(-5 * 60) // 5 minutes ago
        XCTAssertFalse(invalidExpiryCache.isValid, "Cache with expiresAt before lastUpdated should be invalid")
    }
    
    // MARK: - State Management Tests
    // Tests the direct state and property manipulation methods
    
    /// Test setting state directly
    @MainActor func testSetState() {
        // Given
        let initialState = sut.state
        XCTAssertEqual(initialState, .idle, "Initial state should be idle")
        
        // When
        let error = "Test error"
        sut.setState(.error(error))
        
        // Then
        XCTAssertEqual(sut.state, .error(error), "State should be updated to error")
    }
    
    /// Test setting Pokemon directly
    @MainActor func testSetPokemon() throws {
        // Given
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try (1...3).map { try dataProvider.providePokemonDetail(id: $0) }
        
        // When
        sut.setPokemon(mockPokemonList)
        
        // Then
        XCTAssertEqual(sut.filteredPokemon.count, 3, "Should have 3 Pokemon")
        XCTAssertEqual(sut.filteredPokemon, mockPokemonList, "Filtered Pokemon should match the mock list")
    }
    
    // MARK: - Search Tests
    // Tests the search and filtering functionality
    
    /// Test search functionality with matching results
    @MainActor
    func testSearchWithMatches() async throws {
        // Given - ensure setup
        try await setUpAsync()
        
        guard let sut = sut else {
            XCTFail("SUT is nil")
            return
        }
        
        // Create Pokemon with real names using DefaultMockDataProvider
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try [
            dataProvider.providePokemonDetail(id: 1),   // bulbasaur
            dataProvider.providePokemonDetail(id: 2),   // ivysaur
            dataProvider.providePokemonDetail(id: 3),   // venusaur
            dataProvider.providePokemonDetail(id: 4),   // charmander
            dataProvider.providePokemonDetail(id: 5)    // charmeleon
        ]
        
        // When/Then - searching for "saur" should match bulbasaur, ivysaur, venusaur (3 matches)
        try await performSearchTest(initialPokemon: mockPokemonList, searchText: "saur", expectedCount: 3) {
            XCTAssertTrue(sut.filteredPokemon.contains { $0.name == "bulbasaur" }, "Should contain bulbasaur")
            XCTAssertTrue(sut.filteredPokemon.contains { $0.name == "ivysaur" }, "Should contain ivysaur")
            XCTAssertTrue(sut.filteredPokemon.contains { $0.name == "venusaur" }, "Should contain venusaur")
        }
    }
    
    /// Test search functionality with no matches
    @MainActor
    func testSearchWithNoMatches() async throws {
        // Given - ensure setup
        try await setUpAsync()
        
        guard let _ = sut else {
            XCTFail("SUT is nil")
            return
        }
        
        // Create Pokemon with real names using DefaultMockDataProvider
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try [
            dataProvider.providePokemonDetail(id: 1),   // bulbasaur
            dataProvider.providePokemonDetail(id: 2),   // ivysaur
            dataProvider.providePokemonDetail(id: 3)    // venusaur
        ]
        
        // When/Then - searching for "xyz" should not match any Pokemon
        try await performSearchTest(initialPokemon: mockPokemonList, searchText: "xyz", expectedCount: 0) {
            // No additional assertions needed - the helper verifies the count is 0
        }
    }
    
    /// Test clearing search to show all Pokemon
    @MainActor
    func testClearSearch() async throws {
        // Given - Setup
        try await setUpAsync()
        
        // Ensure SUT is initialized
        guard let sut = sut else {
            XCTFail("SUT is nil after setup")
            return
        }
        
        // Create Pokemon with real names using DefaultMockDataProvider
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try [
            dataProvider.providePokemonDetail(id: 1),   // bulbasaur
            dataProvider.providePokemonDetail(id: 2),   // ivysaur
            dataProvider.providePokemonDetail(id: 3)    // venusaur
        ]
        
        sut.setPokemon(mockPokemonList)
        
        // Verify initial state
        XCTAssertEqual(sut.filteredPokemon.count, 3, "Should start with all 3 Pokemon")
        
        // When - Set search text to filter
        sut.searchText = "bulba"
        
        // Wait for debounce
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds (slightly more than debounce)
        
        // Then - Verify filtering
        XCTAssertEqual(sut.filteredPokemon.count, 1, "Should filter to 1 Pokemon with 'bulba' in name")
        XCTAssertEqual(sut.filteredPokemon.first?.name, "bulbasaur", "Should be bulbasaur")
        
        // When - Clear search
        sut.searchText = ""
        
        // Wait for debounce again
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Then - Verify all Pokemon are shown again
        XCTAssertEqual(sut.filteredPokemon.count, 3, "Should show all 3 Pokemon when search is cleared")
    }
    
    // MARK: - Detail Fetching Tests
    // Tests fetching individual Pokemon details
    
    /// Test fetching individual Pokemon details
    @MainActor
    func testFetchPokemonDetails() async throws {
        // Given
        let testId = 25 // Pikachu's ID
        let dataProvider = DefaultMockDataProvider()
        let mockPokemon = try dataProvider.providePokemonDetail(id: testId)
        mockNetworkManager.customPokemonDetail = mockPokemon
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = try await sut.fetchPokemonDetails(id: testId)
        
        // Then
        XCTAssertEqual(result.id, testId, "Should fetch Pokemon with correct ID")
        XCTAssertEqual(result.name, mockPokemon.name, "Should fetch Pokemon with correct name")
        XCTAssertEqual(result.abilities.first?.ability.name, mockPokemon.abilities.first?.ability.name, "Should fetch Pokemon with correct ability")
    }
    
    /// Test partial Pokemon loading with network errors for specific Pokemon
    @MainActor
    func testPartialPokemonLoading() async throws {
        // Given
        try await resetViewModelState()
        
        // Ensure our SUT is properly initialized before proceeding
        XCTAssertNotNil(sut, "SUT should not be nil")
        
        // Use network manager that fails for even-numbered Pokemon
        let partialNetworkManager = createPartialFailureNetworkManager()
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: partialNetworkManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // Use DefaultMockDataProvider for real mock data
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try dataProvider.providePokemonList()
        partialNetworkManager.customPokemonList = mockPokemonList
        
        // When - use Task to ensure proper async execution
        let task = Task { await sut.fetchPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // We should have loaded only the odd-numbered Pokemon
        let loadedCount = sut.filteredPokemon.count
        let expectedLoadedCount = mockPokemonList.count / 2 + mockPokemonList.count % 2 // Counts odd numbers
        XCTAssertEqual(loadedCount, expectedLoadedCount, "Should have loaded only odd-numbered Pokemon")
        
        // Verify all IDs are odd
        for pokemon in sut.filteredPokemon {
            XCTAssertEqual(pokemon.id % 2, 1, "Only odd-numbered Pokemon should be loaded")
        }
        
        // Ensure the task completes
        await task.value
    }
    
    /// Test case where all Pokemon fetch operations fail
    @MainActor
    func testAllPokemonDetailsFail() async throws {
        // Given
        try await resetViewModelState()
        
        // Use network manager that fails for all Pokemon
        let failNetworkManager = createAllFailNetworkManager()
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: failNetworkManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // Use DefaultMockDataProvider for real mock data
        let dataProvider = DefaultMockDataProvider()
        let mockPokemonList = try dataProvider.providePokemonList()
        failNetworkManager.customPokemonList = mockPokemonList
        
        // When
        await sut.fetchPokemon()
        
        // Then
        let errorMessage = await waitForErrorState()
        
        // We should have an error state and no Pokemon
        XCTAssertTrue(sut.filteredPokemon.isEmpty, "No Pokemon should be loaded when all details fail")
        XCTAssertEqual(errorMessage, "Failed to load Pokemon data", "Should have the correct error message")
    }
    
    /// Test loading guard condition
    @MainActor
    func testLoadingGuardCondition() async throws {
        // Given - set up a way to track calls to our network manager
        let networkSpy = NetworkManagerSpy()
        networkSpy.shouldSucceed = true
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: networkSpy,
            cacheLoadingStrategy: TestCacheStrategy()
        )
 
        // When - start the first load
        await sut.fetchPokemon()
        
        // Wait a tiny bit for the operation to start
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Try to start second load while already loading
        await sut.loadCachedPokemon()
        
        // Then - verify only one network call was made
        XCTAssertEqual(networkSpy.fetchPokemonListCallCount, 1, 
                       "Should have called fetchPokemonList exactly once, indicating guard condition worked")
    }
    
    // MARK: - Error Handling Tests
    // Tests to verify error handling and error propagation

    /// Test specific network error propagation
    @MainActor
    func testNetworkErrorPropagation() async throws {
        // Given
        try await resetViewModelState()
        
        // Create a mock network manager that throws specific network errors
        let networkErrorTypes: [(error: NetworkError, expectedMessage: String)] = [
            (.invalidURL, "Invalid URL. Please contact technical support."),
            (.noInternet, "No internet connection. Please check your connection and try again."),
            (.timeout, "Request timed out. Please try again later."),
            (.serverError, "Server error. Please try again later."),
            (.noData, "No data received from server."),
            (.requestFailed(statusCode: 404), "Request failed with status code 404. Please try again later."),
            (.decodingFailed(description: "Test"), "Could not process server response.")
        ]
        
        // Test each error type
        for (networkError, expectedMessage) in networkErrorTypes {
            // Create mock network manager that throws the specific error
            let errorManager = NetworkErrorTestManager(specificError: networkError)
            
            // Create a dedicated expectation for this error test
            let expectation = XCTestExpectation(description: "Waiting for error state: \(networkError)")
            
            // Create a new view model with this error manager
            let errorViewModel = PokemonListViewModel(
                modelContainer: Self.modelContainer,
                networkManager: errorManager,
                cacheLoadingStrategy: TestCacheStrategy()
            )
            
            // Subscribe to state changes to detect when we reach error state
            var stateObserver: AnyCancellable?
            stateObserver = errorViewModel.$state.sink { state in
                if case .error(let message) = state {
                    // When we get an error state, fulfill expectation and check message
                    XCTAssertEqual(message, expectedMessage, "Error message should match for \(networkError)")
                    expectation.fulfill()
                }
            }
            
            // When - fetch pokemon which will trigger the error
            Task {
                await errorViewModel.fetchPokemon()
            }
            
            // Wait for the error state
            await fulfillment(of: [expectation], timeout: 5.0)
            
            // Clean up
            stateObserver?.cancel()
        }
    }
    
    /// Test TestNetworkError propagation for backwards compatibility
    @MainActor
    func testTestNetworkErrorPropagation() async throws {
        // Given
        try await resetViewModelState()
        
        // Create test network errors to try
        let testErrors: [(error: TestNetworkError, expectedMessage: String)] = [
            (.configuredError, "A test error occurred."),
            (.connectionFailed("Test connection failed"), "Test connection failed"),
            (.serverError("Test server error"), "Test server error"),
            (.invalidResponse, "Invalid server response")
        ]
        
        for (testError, expectedMessage) in testErrors {
            // Create a mock network manager that throws the specific test error
            let errorManager = TestErrorManager(specificError: testError)
            
            // Create a new view model with this error manager
            let errorViewModel = PokemonListViewModel(
                modelContainer: Self.modelContainer,
                networkManager: errorManager,
                cacheLoadingStrategy: TestCacheStrategy()
            )
            
            // When - fetch pokemon which will trigger the error
            await errorViewModel.fetchPokemon()
            
            // Add delay to ensure async operations complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Then - verify the error state and message
            if case .error(let message) = errorViewModel.state {
                XCTAssertEqual(message, expectedMessage, "Error message should match for \(testError)")
            } else {
                XCTFail("Expected error state for \(testError), got \(errorViewModel.state)")
            }
        }
    }
    
    /// Test retry behavior for retryable errors
    @MainActor
    func testRetryBehavior() async throws {
        // Given
        try await resetViewModelState()
        
        // Create a network manager that fails initially then succeeds
        let retryManager = RetryTestNetworkManager()
        
        // Replace SUT with one using our retry manager
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: retryManager,
            cacheLoadingStrategy: TestCacheStrategy()
        )
        
        // Create longer expectation timeout for the retry test
        let expectation = XCTestExpectation(description: "Retry test completed")
        expectation.assertForOverFulfill = false
        
        // When - fetch pokemon which will trigger the retry logic
        Task {
            await sut.fetchPokemon()
            
            // Give the task time to properly run through the retry
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            expectation.fulfill()
        }
        
        // Wait for the operation to complete
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Give a little more time for processing
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then - verify we have data
        XCTAssertEqual(retryManager.fetchCallCount, 2, 
                    "Should have called fetchPokemonList twice (initial failure + success)")
        
        // Check if we have Pokemon loaded (should be loaded if retry succeeded)
        if case .loaded(let pokemon) = sut.state {
            XCTAssertFalse(pokemon.isEmpty, "Should have Pokemon after retries")
        } else {
            XCTFail("Expected .loaded state after retry, got \(sut.state)")
        }
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

