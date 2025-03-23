import Foundation

/// Protocol defining the network operations for Pokemon data
public protocol NetworkManagerProtocol {
    /// Fetches a list of Pokemon
    /// - Returns: PokemonListResponse containing Pokemon data
    func fetchPokemonList() async throws -> PokemonListResponse
    
    /// Fetches detailed information about a specific Pokemon
    /// - Parameter id: The ID of the Pokemon to fetch
    /// - Returns: Pokemon model with complete details
    func fetchPokemonDetail(id: Int) async throws -> Pokemon
    
    /// Cancels all ongoing network requests
    func cancelAllRequests()
} 