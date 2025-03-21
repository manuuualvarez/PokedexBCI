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
/// using in-memory containers and mocked network responses for isolation and reliability.

// IMPORTANT: Using class-level setup to avoid launching a new simulator for each test
class PokemonListViewModelTests: XCTestCase {
    
    // Use a lazy static variable to ensure the ModelContainer is created exactly once
    // and is fully initialized before any test uses it
    static let modelContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: PokemonCache.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer for testing: \(error)")
        }
    }()
    
    var sut: PokemonListViewModel!
    var cancellables: Set<AnyCancellable> = []
    var mockNetworkManager: MockNetworkManager!
    
    // MARK: - Setup and Teardown
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        // Using the modelContainer is now safe since it's initialized by the time any test runs
        mockNetworkManager = MockNetworkManager()
        
        // Create the view model on the main actor
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer, 
            networkManager: mockNetworkManager,
            cacheLoadingStrategy: TestCacheLoadingStrategy()
        )
    }
    
    @MainActor
    override func tearDown() async throws {
        sut = nil
        cancellables.removeAll()
        mockNetworkManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to set up mock network manager
    private func setupMockNetworkManager(success: Bool, mockData: PokemonListResponse?) {
        mockNetworkManager.shouldSucceed = success
        mockNetworkManager.mockPokemonList = mockData
    }
    
    /// Helper method to clear the cache
    @MainActor private func clearCache() async throws {
        let descriptor = FetchDescriptor<PokemonCache>()
        let existingCache = try Self.modelContainer.mainContext.fetch(descriptor)
        existingCache.forEach { Self.modelContainer.mainContext.delete($0) }
        try Self.modelContainer.mainContext.save()
    }
    
    /// Helper method to create a mock Pokemon
    private func createMockPokemon(id: Int) -> Pokemon {
        Pokemon(
            id: id,
            name: "pokemon\(id)",
            types: [
                PokemonType(
                    slot: 1,
                    type: PokemonType.PokemonType(name: "grass")
                )
            ],
            sprites: Sprites(frontDefault: "https://example.com/\(id).png"),
            abilities: [
                Ability(
                    ability: Ability.AbilityDetail(name: "ability\(id)"),
                    isHidden: false,
                    slot: 1
                )
            ],
            moves: [
                Move(move: Move.MoveDetail(name: "move\(id)"))
            ]
        )
    }
    
    // MARK: - New Helper Methods for Reducing Duplication
    
    /// Helper to create a mock Pokemon list response with a given range of IDs
    private func createMockPokemonListResponse(range: Range<Int>) -> PokemonListResponse {
        let pokemonList = range.map { id in
            PokemonListItem(name: "pokemon\(id)", url: "https://pokeapi.co/api/v2/pokemon/\(id)/")
        }
        return PokemonListResponse(count: range.count, results: pokemonList)
    }
    
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
        let (pokemonArray, _) = await waitForState({ state in
            if case .loaded(let pokemon) = state { return pokemon }
            return nil
        }, description: "Wait for loaded state", timeout: timeout)
        return pokemonArray
    }
    
    /// Helper to wait for error state
    @MainActor
    private func waitForErrorState(timeout: TimeInterval = 5.0) async -> String? {
        let (errorMessage, _) = await waitForState({ state in
            if case .error(let message) = state { return message }
            return nil
        }, description: "Wait for error state", timeout: timeout)
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
        
        // Reset cancellables
        cancellables.removeAll()
        
        // Reset view model state
        sut.setState(.idle)
        sut.setPokemon([])
    }
    
    /// Helper to perform a search test with debounce
    @MainActor
    private func performSearchTest(initialPokemon: [Pokemon], searchText: String, 
                                 expectedCount: Int, 
                                 assertion: @escaping () -> Void) {
        // Set up the test
        sut.setPokemon(initialPokemon)
        
        // Perform search
        sut.searchText = searchText
        
        // Wait for debounce and check results
        let expectation = XCTestExpectation(description: "Search completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.sut.filteredPokemon.count, expectedCount, 
                          "Should have \(expectedCount) Pokemon after search")
            assertion()
            expectation.fulfill()
        }
        
        XCTWaiter().wait(for: [expectation], timeout: 1.0)
    }
    
    /// Helper to set up a special network manager that fails for specific Pokemon
    private func createPartialFailureNetworkManager() -> MockNetworkManager {
        class PartialFailureNetworkManager: MockNetworkManager {
            override func fetchPokemonDetail(id: Int) async throws -> Pokemon {
                if id % 2 == 0 {
                    throw NetworkError.invalidResponse
                }
                return try await super.fetchPokemonDetail(id: id)
            }
        }
        
        let manager = PartialFailureNetworkManager()
        manager.shouldSucceed = true
        return manager
    }
    
    /// Helper to set up a network manager that fails for all Pokemon details
    private func createAllFailNetworkManager() -> MockNetworkManager {
        class AllFailNetworkManager: MockNetworkManager {
            override func fetchPokemonDetail(id: Int) async throws -> Pokemon {
                throw NetworkError.invalidResponse
            }
        }
        
        let manager = AllFailNetworkManager()
        manager.shouldSucceed = true
        return manager
    }
    
    // MARK: - Network and State Tests
    // Tests the network fetch functionality and state transitions during fetch operations
    
    /// Test successful Pokemon list fetch
    @MainActor
    func testFetchPokemonSuccess() async throws {
        // Given
        try await resetViewModelState()
        let mockPokemonList = createMockPokemonListResponse(range: 1..<152) // 151 Pokemon
        setupMockNetworkManager(success: true, mockData: mockPokemonList)
        
        // When
        Task { await sut.fetchPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, 151, "Should have 151 Pokemon")
        
        // Verify Pokemon details
        let pokemon = sut.filteredPokemon
        XCTAssertFalse(pokemon.isEmpty, "Should have Pokemon in the array")
        
        // Safely check Pokemon details by limiting to available elements
        let numberOfPokemonToCheck = min(pokemon.count, 10) // Check up to 10 Pokemon to avoid long tests
        for i in 0..<numberOfPokemonToCheck {
            XCTAssertEqual(pokemon[i].id, i + 1, "Pokemon ID should match index")
            XCTAssertEqual(pokemon[i].name, "pokemon\(i + 1)", "Pokemon name should match index")
        }
    }
    
    /// Test failed Pokemon list fetch
    /// Verifies error state is properly set when network fails
    @MainActor
    func testFetchPokemonFailure() async throws {
        // Given
        try await resetViewModelState()
        setupMockNetworkManager(success: false, mockData: nil)
        
        // When
        Task { await sut.fetchPokemon() }
        
        // Then
        let errorMessage = await waitForErrorState()
        XCTAssertNotNil(errorMessage, "Should have received an error message")
        XCTAssertTrue(sut.filteredPokemon.isEmpty, "Filtered Pokemon should be empty")
    }
    
    // MARK: - Cache Tests
    // Tests the fundamental cache operations like saving and retrieving data
    
    /// Test caching a Pokemon and retrieving it
    @MainActor
    func testCacheBasicPokemon() async throws {
        // Given
        try await resetViewModelState()
        let mockPokemon = createMockPokemon(id: 1)
        
        // When
        await sut.cachePokemon([mockPokemon])
        
        // Then
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        
        XCTAssertEqual(cachedItems.count, 1, "Should have cached 1 Pokemon")
        XCTAssertEqual(cachedItems.first?.id, 1, "Cached Pokemon should have ID 1")
        XCTAssertEqual(cachedItems.first?.name, "pokemon1", "Cached Pokemon should have name 'pokemon1'")
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
        let testId = Int.random(in: 100...999)
        let mockPokemon = createMockPokemon(id: testId)
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
    }
    
    /// Test loading from cache with multiple Pokemon
    @MainActor
    func testLoadFromCacheWithMultiplePokemon() async throws {
        // Given
        try await resetViewModelState()
        
        // Create multiple Pokemon and add to cache
        let baseId = Int.random(in: 500...900)
        let mockPokemonList = (0..<5).map { createMockPokemon(id: baseId + $0) }
        
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
                let expectedId = baseId + i
                XCTAssertEqual(sut.filteredPokemon[i].id, expectedId, "Pokemon should be sorted by ID")
                XCTAssertEqual(sut.filteredPokemon[i].name, "pokemon\(expectedId)", "Pokemon name should match ID")
            }
        }
    }
    
    /// Test loading Pokemon when cache is expired
    @MainActor
    func testLoadFromExpiredCache() async throws {
        // Given
        try await resetViewModelState()
        
        // Create a Pokemon and expired cache entry
        let testId = Int.random(in: 1000...1999)
        let pokemon = createMockPokemon(id: testId)
        let cache = createExpiredCacheEntry(from: pokemon)
                
        // Insert the expired cache
        Self.modelContainer.mainContext.insert(cache)
        try Self.modelContainer.mainContext.save()
        
        // Set up mock for network that will be used after expired cache
        let mockPokemonList = createMockPokemonListResponse(range: 1..<4) // 3 Pokemon
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockPokemonList = mockPokemonList
        
        // When
        Task { await sut.loadCachedPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // Verify network fetch happened by checking for 3 Pokemon
        XCTAssertEqual(sut.filteredPokemon.count, 3, "Should have fetched 3 Pokemon from network after expired cache")
        
        // Verify the cache was updated with new data
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(cachedItems.count, 3, "Should have 3 updated cache entries")
        XCTAssertTrue(cachedItems.allSatisfy { $0.isValid }, "All cache entries should be valid")
    }
    
    /// Test loading when cache is empty
    @MainActor
    func testLoadFromEmptyCache() async throws {
        // Given
        try await resetViewModelState()
        
        // Verify the cache is empty
        let initialDescriptor = FetchDescriptor<PokemonCache>()
        let initialCache = try Self.modelContainer.mainContext.fetch(initialDescriptor)
        XCTAssertEqual(initialCache.count, 0, "Cache should be empty before test")
        
        // Set up mock for network
        let mockPokemonList = createMockPokemonListResponse(range: 1..<4) // 3 Pokemon
        mockNetworkManager.shouldSucceed = true
        mockNetworkManager.mockPokemonList = mockPokemonList
        
        // When
        Task { await sut.loadCachedPokemon() }
    
        // Then
        _ = await waitForLoadedState()
        
        // Verify Pokemon count
        XCTAssertEqual(sut.filteredPokemon.count, 3, "Should have 3 Pokemon from network")
        
        // Verify the cache was created
        let descriptor = FetchDescriptor<PokemonCache>()
        let cachedItems = try Self.modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(cachedItems.count, 3, "Should have 3 new cache entries")
    }
    
    /// Test direct validation of cache entries
    @MainActor
    func testCacheValidation() throws {
        // Create a Pokemon
        let mockPokemon = createMockPokemon(id: 1)
        
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
    @MainActor func testSetPokemon() {
        // Given
        let mockPokemonList = (1...3).map { createMockPokemon(id: $0) }
        
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
    func testSearchWithMatches() {
        // Given
        let mockPokemonList = [
            createMockPokemon(id: 1),   // pokemon1
            createMockPokemon(id: 2),   // pokemon2
            createMockPokemon(id: 10),  // pokemon10
            createMockPokemon(id: 11),  // pokemon11
            createMockPokemon(id: 20)   // pokemon20
        ]
        
        // When/Then
        performSearchTest(initialPokemon: mockPokemonList, searchText: "1", expectedCount: 3) {
            XCTAssertTrue(self.sut.filteredPokemon.contains { $0.id == 1 }, "Should contain pokemon1")
            XCTAssertTrue(self.sut.filteredPokemon.contains { $0.id == 10 }, "Should contain pokemon10")
            XCTAssertTrue(self.sut.filteredPokemon.contains { $0.id == 11 }, "Should contain pokemon11")
        }
    }
    
    /// Test search functionality with no matches
    @MainActor
    func testSearchWithNoMatches() {
        // Given
        let mockPokemonList = [
            createMockPokemon(id: 1),
            createMockPokemon(id: 2),
            createMockPokemon(id: 3)
        ]
        
        // When/Then
        performSearchTest(initialPokemon: mockPokemonList, searchText: "xyz", expectedCount: 0) {
            // No additional assertions needed - the helper verifies the count is 0
        }
    }
    
    /// Test clearing search to show all Pokemon
    @MainActor
    func testClearSearch() {
        // Given
        let mockPokemonList = [
            createMockPokemon(id: 1),
            createMockPokemon(id: 2),
            createMockPokemon(id: 3)
        ]
        sut.setPokemon(mockPokemonList)
        
        // First filter
        let expectation1 = XCTestExpectation(description: "Initial filter")
        sut.searchText = "1"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.sut.filteredPokemon.count, 1, "Should filter to 1 Pokemon with '1' in name")
            
            // Then clear
            self.sut.searchText = ""
            
            let expectation2 = XCTestExpectation(description: "After clear")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.sut.filteredPokemon.count, 3, "Should show all 3 Pokemon when search is cleared")
                expectation2.fulfill()
            }
            
            XCTWaiter().wait(for: [expectation2], timeout: 1.0)
            expectation1.fulfill()
        }
        
        XCTWaiter().wait(for: [expectation1], timeout: 2.0)
    }
    
    // MARK: - Detail Fetching Tests
    // Tests fetching individual Pokemon details
    
    /// Test fetching individual Pokemon details
    @MainActor
    func testFetchPokemonDetails() async throws {
        // Given
        let testId = 25 // Pikachu's ID
        let mockPokemon = createMockPokemon(id: testId)
        mockNetworkManager.mockPokemonDetail = mockPokemon
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = try await sut.fetchPokemonDetails(id: testId)
        
        // Then
        XCTAssertEqual(result.id, testId, "Should fetch Pokemon with correct ID")
        XCTAssertEqual(result.name, "pokemon\(testId)", "Should fetch Pokemon with correct name")
        XCTAssertEqual(result.abilities.first?.ability.name, "ability\(testId)", "Should fetch Pokemon with correct ability")
    }
    
    /// Test partial Pokemon loading with network errors for specific Pokemon
    @MainActor
    func testPartialPokemonLoading() async throws {
        // Given
        try await resetViewModelState()
        
        // Use network manager that fails for even-numbered Pokemon
        let partialNetworkManager = createPartialFailureNetworkManager()
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: partialNetworkManager,
            cacheLoadingStrategy: TestCacheLoadingStrategy()
        )
        
        // Use 10 Pokemon for testing
        partialNetworkManager.mockPokemonList = createMockPokemonListResponse(range: 1..<11)
        
        // When
        Task { await sut.fetchPokemon() }
        
        // Then
        _ = await waitForLoadedState()
        
        // We should have loaded only the odd-numbered Pokemon (5 total)
        XCTAssertEqual(sut.filteredPokemon.count, 5, "Should have loaded only odd-numbered Pokemon")
        
        // Verify all IDs are odd
        for pokemon in sut.filteredPokemon {
            XCTAssertEqual(pokemon.id % 2, 1, "Only odd-numbered Pokemon should be loaded")
        }
    }
    
    /// Test the case where all Pokemon fetch operations fail
    @MainActor
    func testAllPokemonDetailsFail() async {
        do {
            // Given
            try await resetViewModelState()
            
            // Use network manager that fails for all Pokemon
            let failNetworkManager = createAllFailNetworkManager()
            sut = PokemonListViewModel(
                modelContainer: Self.modelContainer,
                networkManager: failNetworkManager,
                cacheLoadingStrategy: TestCacheLoadingStrategy()
            )
            
            // Use 3 Pokemon for testing
            failNetworkManager.mockPokemonList = createMockPokemonListResponse(range: 1..<4)
            
            // When
            Task { await sut.fetchPokemon() }
            
            // Then
            let errorMessage = await waitForErrorState()
            
            // We should have an error state and no Pokemon
            XCTAssertTrue(sut.filteredPokemon.isEmpty, "No Pokemon should be loaded when all details fail")
            XCTAssertEqual(errorMessage, "Failed to load Pokemon data", "Should have the correct error message")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

    }
    
    /// Test loading guard condition
    @MainActor
    func testLoadingGuardCondition() async {
        // Given - set up a way to track calls to our network manager
        class NetworkManagerSpy: MockNetworkManager {
            var fetchPokemonListCallCount = 0
            
            override func fetchPokemonList() async throws -> PokemonListResponse {
                fetchPokemonListCallCount += 1
                // Add a small delay to ensure we have time to test the guard condition
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                return try await super.fetchPokemonList()
            }
        }
        
        // Use our spy network manager
        let networkSpy = NetworkManagerSpy()
        networkSpy.shouldSucceed = true
        sut = PokemonListViewModel(
            modelContainer: Self.modelContainer,
            networkManager: networkSpy,
            cacheLoadingStrategy: TestCacheLoadingStrategy()
        )

        // When - start the first load
        Task { await sut.fetchPokemon() }
        
        // Wait a tiny bit for the operation to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Try to start second load while already loading
        await sut.loadCachedPokemon()
        
        // Then - verify only one network call was made
        XCTAssertEqual(networkSpy.fetchPokemonListCallCount, 1, 
                      "Should have called fetchPokemonList exactly once, indicating guard condition worked")
    }
    
    /// Test the loading behavior with empty results from the API
    @MainActor
    func testEmptyPokemonResults() async {
        do {
            // Given
            try await resetViewModelState()
            
            // Set up empty results
            let emptyList = PokemonListResponse(count: 0, results: [])
            setupMockNetworkManager(success: true, mockData: emptyList)
            
            // When
            Task { await sut.fetchPokemon() }
            
            // Then
            let errorMessage = await waitForErrorState()
            
            // No Pokemon should be loaded
            XCTAssertTrue(sut.filteredPokemon.isEmpty, "No Pokemon should be loaded with empty results")
            XCTAssertEqual(errorMessage, "Failed to load Pokemon data", "Should have correct error message")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

    }
} 

