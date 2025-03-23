//
//  TestingInfrastructure.swift
//  PokedexBCI
//
//  Created by Manny Alvarez on 02/06/2025.
//

import Foundation
import SwiftData

/// Custom network errors for testing
public enum TestNetworkError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case configuredError
    case connectionFailed(String)
    case serverError(String)
    case detailFetchFailed(String)
    case dataNotFound(String)
    
    // Implement localized error description to ensure error messages appear in alerts
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unable to fetch Pokemon data. The server returned an invalid response."
        case .decodingError:
            return "Failed to decode Pokemon data."
        case .configuredError:
            return "A test error occurred."
        case .connectionFailed(let message):
            return message
        case .serverError(let message):
            return message
        case .detailFetchFailed(let message):
            return message
        case .dataNotFound(let message):
            return message
        }
    }
}

/// Testing network manager that can be used in both app and test targets
public class TestNetworkManager: NetworkManagerProtocol {
    
    // MARK: - Properties    
    /// The mock data provider for consistent testing
    internal let dataProvider: MockDataProvider
    
    /// Optional configured delay to simulate network latency
    internal let delay: TimeInterval
    
    // MARK: - Properties for Unit Testing Configurability
    
    /// Flag to control if the mock should succeed or fail
    var shouldSucceed: Bool = true
    
    /// Custom error that will be thrown if shouldSucceed is false
    var error: Error?
    
    /// Custom Pokemon list response that will be returned if provided
    internal var customPokemonList: PokemonListResponse?
    
    /// Custom Pokemon detail that will be returned if provided
    internal var customPokemonDetail: Pokemon?
    
    /// For error handling UI testing
    private var errorScenario: ErrorScenario?
    
    /// For tracking retry attempts in error scenario testing
    private var isRetryAttempt: Bool = false
    
    /// Date of the first attempt, used to detect retries
    private var firstAttemptDate: Date?
    
    /// Counter to track call count
    private var callCount: Int = 0
    
    /// Whether we're in a retry successful state across all methods
    private var isRetrySuccessState: Bool = false
    
    /// The type of error scenario to simulate
    public enum ErrorScenario {
        case offlineWithCache
        case errorNoCache
        case errorThenSuccess
    }
    
    // MARK: - Initialization
    
    /// Creates a test network manager with specified data and delay
    public init(dataProvider: MockDataProvider = DefaultMockDataProvider(), delay: TimeInterval = 0.1, errorScenario: ErrorScenario? = nil) {
        self.dataProvider = dataProvider
        self.delay = delay
        self.errorScenario = errorScenario
    }
    
    /// Convenience initializer with no parameters
    public convenience init() {
        self.init(dataProvider: DefaultMockDataProvider(), delay: 0.1)
    }
    
    // MARK: - NetworkManagerProtocol Methods
    
    public func fetchPokemonList() async throws -> PokemonListResponse {
        callCount += 1
        
        // For UI error testing
        if let scenario = errorScenario {
            // Simulate a network delay
            if delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            switch scenario {
            case .offlineWithCache:
                // Always throw an error - will trigger offline mode with cache
                throw TestNetworkError.connectionFailed(
                    "Network connection unavailable. Please check your internet connection."
                )
                
            case .errorNoCache:
                // Always throw an error - will trigger error with no cache
                throw TestNetworkError.invalidResponse
                
            case .errorThenSuccess:
                // First check if this is a retry attempt
                if callCount == 1 {
                    // This is the first attempt - should fail
                    firstAttemptDate = Date()
                    isRetryAttempt = false
                    throw TestNetworkError.serverError(
                        "Server error occurred. Please try again later."
                    )
                } else {
                    // This is a retry attempt - should succeed
                    let now = Date()
                    if let firstDate = firstAttemptDate {
                        let _ = now.timeIntervalSince(firstDate)
                    }
                    
                    isRetryAttempt = true
                    isRetrySuccessState = true
                    // For UI testing, we need to ensure data is returned
                    if ProcessInfo.processInfo.arguments.contains("UI-TESTING") {
                        // Use mock data that's guaranteed to work
                        let mockData = MockPokemonDataProvider().provideMockPokemonList(count: 10)
                        return mockData
                    }
                    
                    return try dataProvider.providePokemonList()
                }
            }
        }
        
        // For unit tests - handle failure case
        if !shouldSucceed {
            throw error ?? TestNetworkError.invalidResponse
        }
        
        // For unit tests - return custom data if provided
        if let customList = customPokemonList {
            return customList
        }
        
        // Simulate network delay
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Default behavior - get data from provider
        return try dataProvider.providePokemonList()
    }
    
    public func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        // For UI error testing
        if let scenario = errorScenario {
            // Simulate a network delay
            if delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            switch scenario {
            case .offlineWithCache, .errorNoCache:
                // Always throw an error
                throw TestNetworkError.detailFetchFailed(
                    "Failed to fetch Pokemon details. Please try again later."
                )
                
            case .errorThenSuccess:
                // Check if we're already in the retry success state (after list fetch)
                if isRetrySuccessState {
                    return MockPokemonDataProvider().provideMockPokemon(id: id)
                }
                
                if isRetryAttempt {
                    // On retry, succeed with mock data
                    isRetrySuccessState = true
                    // For UI testing, we need to ensure data is returned
                    if ProcessInfo.processInfo.arguments.contains("UI-TESTING") {
                        // Use mock data that's guaranteed to work
                        let mockPokemon = MockPokemonDataProvider().provideMockPokemon(id: id)
                        return mockPokemon
                    }
                    return try dataProvider.providePokemonDetail(id: id)
                } else {
                    // On first attempt, fail
                    throw TestNetworkError.detailFetchFailed(
                        "Failed to fetch Pokemon details. Please try again later."
                    )
                }
            }
        }
        
        // For unit tests - handle failure case
        if !shouldSucceed {
            throw error ?? TestNetworkError.invalidResponse
        }
        
        // For unit tests - return custom data if provided
        if let customPokemon = customPokemonDetail {
            return customPokemon
        }
        
        // Simulate network delay
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Default behavior - get data from provider
        return try dataProvider.providePokemonDetail(id: id)
    }
    
    /// Cancels all ongoing network requests
    /// This is a no-op in the test implementation, as there are no actual network requests to cancel
    public func cancelAllRequests() {
        print("🧪 Test environment: cancelAllRequests() called")
        // No-op in test environment
    }
    
    // MARK: - Helper Methods for Unit Tests
    
    /// Factory method to create a failing manager
    public static func createFailing(with error: Error? = nil) -> TestNetworkManager {
        let manager = TestNetworkManager(delay: 0) // No delay for unit tests
        manager.shouldSucceed = false
        manager.error = error
        return manager
    }
    
    /// Factory method to create a manager with custom responses
    public static func createWithCustomResponses(
        pokemonList: PokemonListResponse? = nil,
        pokemonDetail: Pokemon? = nil
    ) -> TestNetworkManager {
        let manager = TestNetworkManager(delay: 0) // No delay for unit tests
        manager.customPokemonList = pokemonList
        manager.customPokemonDetail = pokemonDetail
        return manager
    }
    
    /// Factory method to create a manager for error testing scenarios
    public static func createWithErrorScenario(scenario: ErrorScenario) -> TestNetworkManager {
        return TestNetworkManager(delay: 1.0, errorScenario: scenario)
    }
}

/// A strategy for testing that never loads cache
public struct TestCacheStrategy: CacheLoadingStrategy {
    public var shouldLoadCacheOnInit: Bool { false }
    
    /// Default initializer
    public init() {}
}

// MARK: - Mock Data Provider Protocol

/// Protocol for providing mock data
public protocol MockDataProvider {
    /// Provides mock Pokemon list data
    func providePokemonList() throws -> PokemonListResponse
    
    /// Provides mock Pokemon detail data
    func providePokemonDetail(id: Int) throws -> Pokemon
}

/// Default implementation of mock data provider
public class DefaultMockDataProvider: MockDataProvider {
    
    /// Default initializer
    public init() {}
    
    /// Provides a consistent mock Pokemon list response
    public func providePokemonList() throws -> PokemonListResponse {
        return PokemonListResponse(
            count: 6,
            results: [
                PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
                PokemonListItem(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/"),
                PokemonListItem(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon/3/"),
                PokemonListItem(name: "charmander", url: "https://pokeapi.co/api/v2/pokemon/4/"),
                PokemonListItem(name: "charmeleon", url: "https://pokeapi.co/api/v2/pokemon/5/"),
                PokemonListItem(name: "charizard", url: "https://pokeapi.co/api/v2/pokemon/6/")
            ]
        )
    }
    
    /// Provides a mock Pokemon detail - either matched by ID or a default one
    public func providePokemonDetail(id: Int) throws -> Pokemon {
        // Could be extended to load from JSON files for more complex data
        return Pokemon(
            id: id,
            name: getPokemonName(for: id),
            types: getTypes(for: id),
            sprites: Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"),
            abilities: [
                Ability(ability: Ability.AbilityDetail(name: "ability-\(id)"), isHidden: false, slot: 1)
            ],
            moves: [
                Move(move: MoveDetail(name: "move-\(id)"))
            ],
            stats: [
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "hp", url: "https://pokeapi.co/api/v2/stat/1/"))
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    /// Returns a name for the Pokemon based on ID
    internal func getPokemonName(for id: Int) -> String {
        let names = ["bulbasaur", "ivysaur", "venusaur", "charmander", "charmeleon", "charizard"]
        let index = id - 1
        
        if index >= 0 && index < names.count {
            return names[index]
        }
        
        return "pokemon-\(id)"
    }
    
    /// Returns types based on Pokemon ID
    internal func getTypes(for id: Int) -> [PokemonTypes] {
        switch id {
        case 1, 2, 3:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "grass")),
                PokemonTypes(slot: 2, type: PokemonType(name: "poison"))
            ]
        case 4, 5, 6:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "fire")),
                PokemonTypes(slot: 2, type: PokemonType(name: "flying"))
            ]
        default:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "normal"))
            ]
        }
    }
}

// MARK: - Factory for Testing

/// A factory for creating test-specific implementations
public class TestNetworkManagerFactory: NetworkManagerFactoryProtocol {
    
    /// Shared instance
    public static let shared = TestNetworkManagerFactory()
    
    /// Provides the appropriate network manager based on environment
    public func createNetworkManager(for environment: NetworkEnvironment) -> NetworkManagerProtocol {
        let processInfo = ProcessInfo.processInfo
        let testArgs = processInfo.arguments
        
        // Check for UI testing mode and error testing flags
        let isUITesting = testArgs.contains("UI-TESTING")
        let isErrorTesting = testArgs.contains("ERROR-TESTING")
        // For UI testing with specific error scenarios
        if isUITesting && isErrorTesting {
            if testArgs.contains("OFFLINE-WITH-CACHE") {
                return TestNetworkManager.createWithErrorScenario(scenario: .offlineWithCache)
            } 
            else if testArgs.contains("ERROR-NO-CACHE") {
                return TestNetworkManager.createWithErrorScenario(scenario: .errorNoCache)
            }
            else if testArgs.contains("ERROR-THEN-SUCCESS") {
                return TestNetworkManager.createWithErrorScenario(scenario: .errorThenSuccess)
            }
            // Default error testing behavior if no specific scenario
            return TestNetworkManager.createWithErrorScenario(scenario: .errorThenSuccess)
        }
        
        // For regular UI testing
        if isUITesting {
            return TestNetworkManager()
        }
        // Handle production environment
        return TestNetworkManager()
    }
}

// MARK: - Mock Pokemon Data Provider

/// A simpler provider specifically for UI tests that need guaranteed data
public class MockPokemonDataProvider {
    
    /// Default initializer
    public init() {}
    
    /// Provides a mock Pokemon list with the specified number of items
    public func provideMockPokemonList(count: Int) -> PokemonListResponse {
        var results: [PokemonListItem] = []
        
        for i in 1...count {
            results.append(
                PokemonListItem(
                    name: "pokemon-\(i)",
                    url: "https://pokeapi.co/api/v2/pokemon/\(i)/"
                )
            )
        }
        
        return PokemonListResponse(count: results.count, results: results)
    }
    
    /// Provides a mock Pokemon with the specified ID
    public func provideMockPokemon(id: Int) -> Pokemon {
        return Pokemon(
            id: id,
            name: "pokemon-\(id)",
            types: [
                PokemonTypes(slot: 1, type: PokemonType(name: "normal"))
            ],
            sprites: Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"),
            abilities: [
                Ability(ability: Ability.AbilityDetail(name: "mock-ability"), isHidden: false, slot: 1)
            ],
            moves: [
                Move(move: MoveDetail(name: "mock-move"))
            ],
            stats: [
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "hp", url: "https://pokeapi.co/api/v2/stat/1/")),
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "attack", url: "https://pokeapi.co/api/v2/stat/2/"))
            ]
        )
    }
}

// MARK: - UI Testing Helper

/// Helper for UI testing scenarios
@MainActor
public struct UITestHelper {
    /// The shared instance
    public static let shared = UITestHelper()
    
    /// Check if we should pre-populate the cache for testing
    public var shouldPrepopulateCache: Bool {
        ProcessInfo.processInfo.arguments.contains("PREPOPULATE-CACHE")
    }
} 
