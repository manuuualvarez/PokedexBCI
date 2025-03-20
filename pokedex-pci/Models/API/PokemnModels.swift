//
//  PokemnModels.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation

struct Pokemon: Codable, Identifiable {
    let id: Int
    let name: String
    let types: [PokemonType]
    let sprites: Sprites
    let abilities: [Ability]
    let moves: [Move]
    
    struct PokemonType: Codable {
        let slot: Int
        let type: PokemonType
        
        struct PokemonType: Codable {
            let name: String
        }
    }
    
    struct Sprites: Codable {
        let frontDefault: String
        
        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
        }
    }
    
    struct Ability: Codable {
        let ability: AbilityDetail
        let isHidden: Bool
        let slot: Int
        
        enum CodingKeys: String, CodingKey {
            case ability
            case isHidden = "is_hidden"
            case slot
        }
        
        struct AbilityDetail: Codable {
            let name: String
        }
    }
    
    struct Move: Codable {
        let move: MoveDetail
        
        struct MoveDetail: Codable {
            let name: String
        }
    }
}

// API Response models
struct PokemonListResponse: Codable {
    let count: Int
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable {
    let name: String
    let url: String
}
