//
//  PokemnModels.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import UIKit

// MARK: -  API Response models:

struct PokemonListResponse: Codable {
    let count: Int
    let results: [PokemonListItem]
}

struct PokemonListItem: Codable {
    let name: String
    let url: String
}

struct Pokemon: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let types: [PokemonTypes]
    let sprites: Sprites
    let abilities: [Ability]
    let moves: [Move]
    let stats: [Stat]
    
    static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.sprites == rhs.sprites &&
        lhs.types == rhs.types &&
        lhs.abilities == rhs.abilities &&
        lhs.moves == rhs.moves
    }
    
    // MARK: - Computed Properties
    
    /// Returns the primary type of the Pokemon (first type or "normal" if no types)
    var primaryType: String {
        types.first?.type.name.lowercased() ?? "normal"
    }
    
    /// Returns the color name associated with the Pokemon's primary type
    var colorName: PokemonColorName {
        PokemonColorName.forType(primaryType)
    }
    
    /// Returns the UIColor associated with the Pokemon's primary type
    var typeColor: UIColor {
        colorName.uiColor
    }
}

struct PokemonTypes: Codable, Equatable {
    let slot: Int
    let type: PokemonType
}

struct PokemonType: Codable, Equatable {
    let name: String
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
}

struct MoveDetail: Codable, Equatable {
    let name: String
}

struct Sprites: Codable, Equatable {
    let frontDefault: String
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct Stat: Codable, Equatable {
    let baseStat: Int
    let effort: Int
    let stat: StatDetail
    
    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case effort
        case stat
    }
}

struct StatDetail: Codable, Equatable {
    let name: String
    let url: String
}

public struct SimpleStat: Equatable {
    public let name: String
    public let value: Int
    public let colorName: PokemonColorName
    
    public init(name: String, value: Int, colorName: PokemonColorName) {
        self.name = name
        self.value = value
        self.colorName = colorName
    }
    
    public static func == (lhs: SimpleStat, rhs: SimpleStat) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
    }
}

// MARK: - Type Color System:

public enum PokemonColorName: String {
    case green, red, blue, yellow, purple, brown, gray, orange, teal, cyan, indigo, darkGray, lightGray, pink
    
    public static func forType(_ type: String) -> PokemonColorName {
        switch type.lowercased() {
        case "grass", "bug": return .green
        case "fire": return .red
        case "water": return .blue
        case "electric": return .yellow
        case "poison", "ghost", "psychic": return .purple
        case "ground", "rock": return .brown
        case "normal": return .gray
        case "fighting": return .orange
        case "ice": return .cyan
        case "dragon": return .indigo
        case "dark": return .darkGray
        case "steel": return .lightGray
        case "fairy": return .pink
        case "flying": return .teal
        default: return .gray
        }
    }
    
    public var uiColor: UIColor {
        switch self {
        case .green: return .systemGreen
        case .red: return .systemRed
        case .blue: return .systemBlue
        case .yellow: return .systemYellow
        case .purple: return .systemPurple
        case .brown: return .brown
        case .gray: return .systemGray
        case .orange: return .systemOrange
        case .teal: return .systemTeal
        case .cyan: return .systemCyan
        case .indigo: return .systemIndigo
        case .darkGray: return .darkGray
        case .lightGray: return .lightGray
        case .pink: return .systemPink
        }
    }
}
