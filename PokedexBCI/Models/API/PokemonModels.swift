//
//  PokemnModels.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import UIKit

// MARK: -  API Response models:

public struct PokemonListResponse: Codable {
    public let count: Int
    public let results: [PokemonListItem]
}

public struct PokemonListItem: Codable {
    public let name: String
    public let url: String
}

public struct Pokemon: Codable, Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let types: [PokemonTypes]
    public let sprites: Sprites
    public let abilities: [Ability]
    public let moves: [Move]
    public let stats: [Stat]
    
    public static func == (lhs: Pokemon, rhs: Pokemon) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.sprites == rhs.sprites &&
        lhs.types == rhs.types &&
        lhs.abilities == rhs.abilities &&
        lhs.moves == rhs.moves
    }
    
    // MARK: - Computed Properties
    
    /// Returns the primary type of the Pokemon (first type or "normal" if no types)
    public var primaryType: String {
        types.first?.type.name.lowercased() ?? "normal"
    }
    
    /// Returns the color name associated with the Pokemon's primary type
    public var colorName: PokemonColorName {
        PokemonColorName.forType(primaryType)
    }
    
    /// Returns the UIColor associated with the Pokemon's primary type
    public var typeColor: UIColor {
        colorName.uiColor
    }
}

public struct PokemonTypes: Codable, Equatable {
    public let slot: Int
    public let type: PokemonType
}

public struct PokemonType: Codable, Equatable {
    public let name: String
}

public struct Ability: Codable, Equatable {
    public let ability: AbilityDetail
    public let isHidden: Bool
    public let slot: Int
    
    public enum CodingKeys: String, CodingKey {
        case ability
        case isHidden = "is_hidden"
        case slot
    }
    
    public struct AbilityDetail: Codable, Equatable {
        public let name: String
    }
}

public struct Move: Codable, Equatable {
    public let move: MoveDetail
}

public struct MoveDetail: Codable, Equatable {
    public let name: String
}

public struct Sprites: Codable, Equatable {
    public let frontDefault: String
    
    public enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

public struct Stat: Codable, Equatable {
    public let baseStat: Int
    public let effort: Int
    public let stat: StatDetail
    
    public enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case effort
        case stat
    }
}

public struct StatDetail: Codable, Equatable {
    public let name: String
    public let url: String
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
