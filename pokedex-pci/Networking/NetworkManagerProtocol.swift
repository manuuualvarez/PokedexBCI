import Foundation

/// Protocol defining the network operations for Pokemon data
protocol NetworkManagerProtocol {
    func fetchPokemonList() async throws -> PokemonListResponse
    func fetchPokemonDetail(id: Int) async throws -> Pokemon
} 