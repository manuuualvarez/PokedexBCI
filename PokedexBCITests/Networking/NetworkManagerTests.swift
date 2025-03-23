import XCTest
@testable import PokedexBCI

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
    
    // MARK: - Test Cases
    
    /// Test successful Pokemon list fetch
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
    
    /// Test Pokemon list fetch with NetworkError
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
    
    /// Test Pokemon list fetch with other error that gets mapped
    func testFetchPokemonList_OtherErrorMappedToNetworkError() async {
        // Given
        mockAPIService.shouldThrowOtherError = true
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonList()
            XCTFail("Should have thrown an error")
        } catch let error as NetworkError {
            if case .unknown = error {
                // This is expected
            } else {
                XCTFail("Error should be mapped to NetworkError.unknown")
            }
            XCTAssertEqual(mockAPIService.fetchPokemonListCallCount, 1)
        } catch {
            XCTFail("Error should be a NetworkError")
        }
    }
    
    /// Test successful Pokemon detail fetch
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
    
    /// Test Pokemon detail fetch with NetworkError
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
    
    /// Test Pokemon detail fetch with other error that gets mapped
    func testFetchPokemonDetail_OtherErrorMappedToNetworkError() async {
        // Given
        mockAPIService.shouldThrowOtherError = true
        
        // When/Then
        do {
            _ = try await sut.fetchPokemonDetail(id: 1)
            XCTFail("Should have thrown an error")
        } catch let error as NetworkError {
            if case .unknown = error {
                // This is expected
            } else {
                XCTFail("Error should be mapped to NetworkError.unknown")
            }
            XCTAssertEqual(mockAPIService.fetchPokemonDetailCallCount, 1)
            XCTAssertEqual(mockAPIService.lastPokemonDetailID, 1)
        } catch {
            XCTFail("Error should be a NetworkError")
        }
    }
    
    /// Test cancel all requests
    func testCancelAllRequests() {
        // When
        sut.cancelAllRequests()
        
        // Then
        XCTAssertTrue(mockAPIService.cancelAllRequestsCalled)
    }
    
    /// Test initialization with custom URL
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

/// Mock PokemonAPIService for testing NetworkManager
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