import Foundation


/// Network manager for handling Pokemon API requests
final class NetworkManager: NetworkManagerProtocol {
    private let baseURL: String
    
    init(_ baseURL: String = "https://pokeapi.co/api/v2") {
        self.baseURL = baseURL
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        let url = URL(string: "\(baseURL)/pokemon?limit=151")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PokemonListResponse.self, from: data)
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        let url = URL(string: "\(baseURL)/pokemon/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Pokemon.self, from: data)
    }
} 
