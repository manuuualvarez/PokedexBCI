//
//  POkemonDetailViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import Combine

final class PokemonDetailViewModel {
    private let pokemon: Pokemon
    @Published private(set) var state: PokemonListState = .idle
    
    init(pokemon: Pokemon) {
        self.pokemon = pokemon
    }
    
    var name: String {
        pokemon.name.capitalized
    }
    
    var imageURL: URL? {
        URL(string: pokemon.sprites.frontDefault)
    }
    
    var types: String {
        pokemon.types.map { $0.type.name.capitalized }.joined(separator: " / ")
    }
    
    var abilities: String {
        pokemon.abilities
            .map { ability in
                let name = ability.ability.name.capitalized
                return ability.isHidden ? "\(name) (Hidden)" : name
            }
            .joined(separator: "\n")
    }
    
    var moves: String {
        pokemon.moves
            .prefix(5)
            .map { $0.move.name.capitalized }
            .joined(separator: "\n")
    }
}


