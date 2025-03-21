//
//  PokemnModels.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation

struct Pokemon: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let types: [PokemonType]
    let sprites: Sprites
    let abilities: [Ability]
    let moves: [Move]
    
    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.sprites == rhs.sprites &&
        lhs.types == rhs.types &&
        lhs.abilities == rhs.abilities &&
        lhs.moves == rhs.moves
    }
}

struct PokemonType: Codable, Equatable {
    let slot: Int
    let type: PokemonType
    
    struct PokemonType: Codable, Equatable {
        let name: String
    }
}

struct Sprites: Codable, Equatable {
    let frontDefault: String
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct Ability: Codable, Equatable {
    let ability: AbilityDetail
    let isHidden: Bool
    let slot: Int
    
    enum CodingKeys: String, CodingKey {
        case ability
        case isHidden = "is_hidden"
        case slot
    }
    
    struct AbilityDetail: Codable, Equatable {
        let name: String
    }
}

struct Move: Codable, Equatable {
    let move: MoveDetail
    
    struct MoveDetail: Codable, Equatable {
        let name: String
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
