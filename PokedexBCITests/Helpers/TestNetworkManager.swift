//
//  TestNetworkError.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 22/03/2025.
//
import Foundation
@testable import PokedexBCI

// Custom TestNetworkManager implementation for tests
class TestNetworkManager: NetworkManagerProtocol {
    var shouldSucceed: Bool = true
    var customPokemonList: PokemonListResponse?
    var customPokemonDetail: Pokemon?
    var cancellationCalled = false
    
    init() {}
    
    /// Factory method to create a manager with custom responses
    static func createWithCustomResponses(
        pokemonList: PokemonListResponse? = nil,
        pokemonDetail: Pokemon? = nil
    ) -> TestNetworkManager {
        let manager = TestNetworkManager()
        manager.customPokemonList = pokemonList
        manager.customPokemonDetail = pokemonDetail
        return manager
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        if !shouldSucceed {
            throw TestNetworkError.configuredError
        }
        
        if let customList = customPokemonList {
            return customList
        }
        
        // Use DefaultMockDataProvider to get the standard mock data
        return try DefaultMockDataProvider().providePokemonList()
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        if !shouldSucceed {
            throw TestNetworkError.configuredError
        }
        
        if let customDetail = customPokemonDetail {
            return customDetail
        }
        
        // Use DefaultMockDataProvider to get proper Pokémon with correct names
        return try DefaultMockDataProvider().providePokemonDetail(id: id)
    }
    
    /// Cancels all ongoing network requests
    /// This is a mock implementation that sets a flag for testing purposes
    func cancelAllRequests() {
        cancellationCalled = true
        print("🧪 TestNetworkManager: cancelAllRequests called")
    }
}

// Define test-specific network errors
enum TestNetworkError: Error, LocalizedError {
    case configuredError
    case connectionFailed(String)
    case serverError(String)
    case detailFetchFailed(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .configuredError:
            return "A test error occurred."
        case .connectionFailed(let message):
            return message
        case .serverError(let message):
            return message
        case .detailFetchFailed(let message):
            return message
        case .invalidResponse:
            return "Invalid server response"
        }
    }
    
    // Add a userMessage for compatibility with NetworkError
    var userMessage: String {
        return errorDescription ?? "Unknown test error"
    }
}
