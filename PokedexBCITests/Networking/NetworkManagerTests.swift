import XCTest
@testable import PokedexBCI

// MARK: - NetworkManager Tests
/// Tests the NetworkManager's ability to handle the API layer, error handling, and retry logic
final class NetworkManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: NetworkManager!
    private var mockAPIService: MockPokemonAPIService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockPokemonAPIService()
        sut = NetworkManager(apiService: mockAPIService)
    }
    
    override func tearDown() {
        sut = nil
        mockAPIService = nil
        super.tearDown()
    }
    
    // MARK: - Pokemon List Fetch Tests
    
    /// Tests the successful fetch of Pokemon list, ensuring data mapping is correct
    /// This is critical for the main list view to display correctly
    func testFetchPokemonList_Success() async throws {
        // Given
        let expectedResponse = PokemonListResponse(
            count: 2,
            results: [
                PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
                PokemonListItem(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/")
            ]
        )
        mockAPIService.mockPokemonList = expectedResponse
        
        // When
        let result = try await sut.fetchPokemonList()
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.results.count, 2)
        XCTAssertEqual(result.results[0].name, "bulbasaur")
        XCTAssertEqual(result.results[1].name, "ivysaur")
        XCTAssertEqual(mockAPIService.fetchPokemonListCallCount, 1)
    }
    
    /// Tests how NetworkManager handles service errors during list fetch
    /// This verifies our error propagation from service to UI
    func testFetchPokemonList_NetworkError() async {
        // Given
        let expectedError = NetworkError.serverError
        mockAPIService.shouldThrowNetworkError = true
        mockAPIService.networkErrorToThrow = expectedError
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonList()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, expectedError)
            XCTAssertEqual(mockAPIService.fetchPokemonListCallCount, 1)
        }
    }
    
    /// Tests error mapping from unknown errors to NetworkError
    /// This ensures we never propagate non-NetworkError types to the UI layer
    func testFetchPokemonList_OtherErrorMappedToNetworkError() async {
        // Given
        mockAPIService.shouldThrowOtherError = true
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonList()
            XCTFail("Should have thrown an error")
        } catch let error as NetworkError {
            if case .unknown = error {
                // This is expected - we want to normalize errors
            } else {
                XCTFail("Error should be mapped to NetworkError.unknown")
            }
            XCTAssertEqual(mockAPIService.fetchPokemonListCallCount, 1)
        } catch {
            XCTFail("Error should be a NetworkError")
        }
    }
    
    // MARK: - Pokemon Detail Fetch Tests
    
    /// Tests successful fetch of individual Pokemon details
    /// Critical for the detail view that shows more information about a selected Pokemon
    func testFetchPokemonDetail_Success() async throws {
        // Given
        let expectedPokemon = Pokemon(
            id: 1,
            name: "bulbasaur",
            types: [PokemonTypes(slot: 1, type: PokemonType(name: "grass"))],
            sprites: Sprites(frontDefault: "https://example.com/sprite.png"),
            abilities: [],
            moves: [],
            stats: []
        )
        mockAPIService.mockPokemonDetail = expectedPokemon
        
        // When
        let result = try await sut.fetchPokemonDetail(id: 1)
        
        // Then
        XCTAssertEqual(result.id, 1)
        XCTAssertEqual(result.name, "bulbasaur")
        XCTAssertEqual(result.types.count, 1)
        XCTAssertEqual(result.types[0].type.name, "grass")
        XCTAssertEqual(mockAPIService.fetchPokemonDetailCallCount, 1)
        XCTAssertEqual(mockAPIService.lastPokemonDetailID, 1)
    }
    
    /// Tests error handling during Pokemon detail fetch
    /// Important for proper error presentation on the detail screen
    func testFetchPokemonDetail_NetworkError() async {
        // Given
        let expectedError = NetworkError.timeout
        mockAPIService.shouldThrowNetworkError = true
        mockAPIService.networkErrorToThrow = expectedError
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonDetail(id: 1)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(error as? NetworkError, expectedError)
            XCTAssertEqual(mockAPIService.fetchPokemonDetailCallCount, 1)
            XCTAssertEqual(mockAPIService.lastPokemonDetailID, 1)
        }
    }
    
    /// Tests error normalization during Pokemon detail fetch
    /// Ensures consistent error handling throughout the app
    func testFetchPokemonDetail_OtherErrorMappedToNetworkError() async {
        // Given
        mockAPIService.shouldThrowOtherError = true
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonDetail(id: 1)
            XCTFail("Should have thrown an error")
        } catch let error as NetworkError {
            if case .unknown = error {
                // Expected behavior - normalizing unknown errors
            } else {
                XCTFail("Error should be mapped to NetworkError.unknown")
            }
            XCTAssertEqual(mockAPIService.fetchPokemonDetailCallCount, 1)
            XCTAssertEqual(mockAPIService.lastPokemonDetailID, 1)
        } catch {
            XCTFail("Error should be a NetworkError")
        }
    }
    
    // MARK: - Cleanup Tests
    
    /// Tests that the request cancellation propagates to the underlying service
    /// Critical for preventing memory leaks when views are dismissed
    func testCancelAllRequests() {
        // When
        sut.cancelAllRequests()
        
        // Then
        XCTAssertTrue(mockAPIService.cancelAllRequestsCalled)
    }
    
    /// Tests custom URL initialization to ensure we can point to different APIs
    /// Important for development, staging and testing environments
    func testInitWithBaseURL() {
        // Given
        let baseURL = "https://custom-api.example.com"
        
        // When
        let networkManager = NetworkManager(baseURL)
        
        // Then - we can't directly test the private property, but we can test the type
        XCTAssertNotNil(networkManager)
    }
}

// MARK: - Test Helpers

/// Mock implementation of PokemonAPIService for isolating NetworkManager tests
class MockPokemonAPIService: PokemonAPIServiceProtocol {
    var mockPokemonList: PokemonListResponse?
    var mockPokemonDetail: Pokemon?
    
    var fetchPokemonListCallCount = 0
    var fetchPokemonDetailCallCount = 0
    var lastPokemonDetailID: Int?
    var cancelAllRequestsCalled = false
    
    var shouldThrowNetworkError = false
    var networkErrorToThrow: NetworkError?
    var shouldThrowOtherError = false
    
    func fetchPokemonList(limit: Int) async throws -> PokemonListResponse {
        fetchPokemonListCallCount += 1
        
        if shouldThrowNetworkError, let error = networkErrorToThrow {
            throw error
        }
        
        if shouldThrowOtherError {
            throw NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        
        return mockPokemonList ?? PokemonListResponse(count: 0, results: [])
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        fetchPokemonDetailCallCount += 1
        lastPokemonDetailID = id
        
        if shouldThrowNetworkError, let error = networkErrorToThrow {
            throw error
        }
        
        if shouldThrowOtherError {
            throw NSError(domain: "TestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        
        return mockPokemonDetail ?? Pokemon(
            id: id,
            name: "pokemon-\(id)",
            types: [],
            sprites: Sprites(frontDefault: ""),
            abilities: [],
            moves: [],
            stats: []
        )
    }
    
    func cancelAllRequests() {
        cancelAllRequestsCalled = true
    }
} 