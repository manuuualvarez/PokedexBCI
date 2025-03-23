//
//  POkemonDetailViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import Combine
import UIKit

// MARK: - Protocol Definition

/// Protocol defining the interface for Pokemon detail presentation
protocol PokemonDetailViewModelProtocol {
    // Required Pokemon data
    var id: Int { get }
    var name: String { get }
    var imageURL: URL? { get }
    var typeNames: [String] { get }
    var abilitiesArray: [String] { get }
    var movesArray: [String] { get }
    var stats: [SimpleStat] { get }
    
    // UI-related properties
    var colorName: PokemonColorName { get }
}

// MARK: - ViewModel Implementation

final class PokemonDetailViewModel: PokemonDetailViewModelProtocol {
    
    // MARK: - Properties
    
    let pokemon: Pokemon
    
    // MARK: - Initializers
    
    init(pokemon: Pokemon) {
        self.pokemon = pokemon
    }
    
    // MARK: - Protocol Implementation
    
    var id: Int { pokemon.id }
    
    var name: String { pokemon.name.capitalized }
    
    var imageURL: URL? { URL(string: pokemon.sprites.frontDefault) }
    
    var typeNames: [String] {
        pokemon.types.map { $0.type.name.capitalized }
    }
    
    var abilitiesArray: [String] {
        pokemon.abilities.map { ability in
            let name = ability.ability.name.capitalized
            return ability.isHidden ? "\(name) (Hidden)" : name
        }
    }
    
    var movesArray: [String] {
        pokemon.moves
            .prefix(5)
            .map { $0.move.name.capitalized }
    }
    
    var stats: [SimpleStat] {
        var result: [SimpleStat] = []
        
        if !pokemon.stats.isEmpty {
            for stat in pokemon.stats {
                let statName = stat.stat.name.capitalized
                let value = min(100, stat.baseStat)
                let colorName = getColorNameForStatName(statName)
                result.append(SimpleStat(name: statName, value: value, colorName: colorName))
            }
        }
        return result
    }
    
    // UI Properties
    var colorName: PokemonColorName { pokemon.colorName }
    
    // MARK: - Private Helpers
    
    private func getColorNameForStatName(_ statName: String) -> PokemonColorName {
        switch statName.lowercased() {
        case "hp": return .green
        case "attack": return .red
        case "defense": return .blue
        case "special-attack", "special attack": return .purple
        case "special-defense", "special defense": return .teal
        case "speed": return .yellow
        default: return .gray
        }
    }
} 
