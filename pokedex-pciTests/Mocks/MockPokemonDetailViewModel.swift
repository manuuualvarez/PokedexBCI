//
//  MockPokemonDetailViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 22/03/2025.
//
import Foundation
@testable import pokedex_pci


/// A mock implementation of PokemonDetailViewModelProtocol for testing purposes
class MockPokemonDetailViewModel: PokemonDetailViewModelProtocol {
    // Basic stored properties with hardcoded test values
    let id: Int = 1
    let name: String = "Test Pokemon"
    let imageURL: URL? = URL(string: "https://example.com/test.png")
    let typeNames: [String] = ["Fire", "Water"]
    let abilitiesArray: [String] = ["Test Ability", "Hidden Ability"]
    let movesArray: [String] = ["Test Move"]
    let stats: [SimpleStat] = [
        SimpleStat(name: "Test Stat", value: 50, colorName: .red)
    ]
    let colorName: PokemonColorName = .blue
    
    // Store the pokemon for reference but don't use it in initialization
    let mockPokemon: Pokemon
    
    init(pokemon: Pokemon) {
        self.mockPokemon = pokemon
        // No other initialization - all properties have default values
    }
    
    // Alternative factory method that doesn't use an initializer
    static func create(with pokemon: Pokemon) -> MockPokemonDetailViewModel {
        let mock = MockPokemonDetailViewModel(pokemon: pokemon)
        return mock
    }
}
