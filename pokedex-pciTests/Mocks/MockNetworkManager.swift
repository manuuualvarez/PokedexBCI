import Foundation
@testable import pokedex_pci

class MockNetworkManager: NetworkManagerProtocol {
    var shouldSucceed = true
    var mockPokemonList: PokemonListResponse?
    var mockPokemonDetail: Pokemon?
    var error: Error?
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        if !shouldSucceed {
            throw error ?? NetworkError.invalidResponse
        }
        
        if let mockList = mockPokemonList {
            return mockList
        }
        
        // Create a default mock response
        let defaultPokemonList = (1...3).map { id in
            PokemonListItem(name: "pokemon\(id)", url: "https://pokeapi.co/api/v2/pokemon/\(id)/")
        }
        
        return PokemonListResponse(count: 3, results: defaultPokemonList)
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        if !shouldSucceed {
            throw error ?? NetworkError.invalidResponse
        }
        
        // If we have a specific mock Pokemon detail, return it
        if let mockPokemon = mockPokemonDetail {
            return mockPokemon
        }
        
        // Create a Pokemon based on the ID
        return Pokemon(
            id: id,
            name: "pokemon\(id)",
            types: [
                PokemonTypes(
                    slot: 1,
                    type: PokemonType(name: "grass")
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
                Move(move: MoveDetail(name: "move\(id)"))
            ],
            stats: [
                Stat(baseStat: 100, effort: 0, stat: StatDetail(name: "defense", url: "https://pokeapi.co/api/v2/stat/3/"))
            ]
        )
    }
}

enum NetworkError: Error {
    case invalidResponse
    case decodingError
} 
