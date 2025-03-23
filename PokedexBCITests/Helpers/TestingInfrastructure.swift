//
//  TestingInfrastructure.swift
//  pokedex-pciTests
//
//  Created by Manny Alvarez on 23/03/2025.
//

import Foundation
import SwiftData
@testable import PokedexBCI


/// A strategy for testing that never loads cache
public struct TestCacheStrategy: CacheLoadingStrategy {
    public var shouldLoadCacheOnInit: Bool { false }
    
    /// Default initializer
    public init() {}
}

// MARK: - Mock Data Provider Protocol

/// Protocol for providing mock data
public protocol MockDataProvider {
    /// Provides mock Pokemon list data
    func providePokemonList() throws -> PokemonListResponse
    
    /// Provides mock Pokemon detail data
    func providePokemonDetail(id: Int) throws -> Pokemon
}

/// Default implementation of mock data provider
public class DefaultMockDataProvider: MockDataProvider {
    
    /// Default initializer
    public init() {}
    
    /// Provides a consistent mock Pokemon list response
    public func providePokemonList() throws -> PokemonListResponse {
        return PokemonListResponse(
            count: 6,
            results: [
                PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
                PokemonListItem(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon/2/"),
                PokemonListItem(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon/3/"),
                PokemonListItem(name: "charmander", url: "https://pokeapi.co/api/v2/pokemon/4/"),
                PokemonListItem(name: "charmeleon", url: "https://pokeapi.co/api/v2/pokemon/5/"),
                PokemonListItem(name: "charizard", url: "https://pokeapi.co/api/v2/pokemon/6/")
            ]
        )
    }
    
    /// Provides a mock Pokemon detail - either matched by ID or a default one
    public func providePokemonDetail(id: Int) throws -> Pokemon {
        // Could be extended to load from JSON files for more complex data
        return Pokemon(
            id: id,
            name: getPokemonName(for: id),
            types: getTypes(for: id),
            sprites: Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"),
            abilities: [
                Ability(ability: Ability.AbilityDetail(name: "ability-\(id)"), isHidden: false, slot: 1)
            ],
            moves: [
                Move(move: MoveDetail(name: "move-\(id)"))
            ],
            stats: [
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "hp", url: "https://pokeapi.co/api/v2/stat/1/"))
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    /// Returns a name for the Pokemon based on ID
    internal func getPokemonName(for id: Int) -> String {
        let names = ["bulbasaur", "ivysaur", "venusaur", "charmander", "charmeleon", "charizard"]
        let index = id - 1
        
        if index >= 0 && index < names.count {
            return names[index]
        }
        
        return "pokemon-\(id)"
    }
    
    /// Returns types based on Pokemon ID
    internal func getTypes(for id: Int) -> [PokemonTypes] {
        switch id {
        case 1, 2, 3:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "grass")),
                PokemonTypes(slot: 2, type: PokemonType(name: "poison"))
            ]
        case 4, 5, 6:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "fire")),
                PokemonTypes(slot: 2, type: PokemonType(name: "flying"))
            ]
        default:
            return [
                PokemonTypes(slot: 1, type: PokemonType(name: "normal"))
            ]
        }
    }
}

// MARK: - Mock Pokemon Data Provider

/// A simpler provider specifically for UI tests that need guaranteed data
public class MockPokemonDataProvider {
    
    /// Default initializer
    public init() {}
    
    /// Provides a mock Pokemon list with the specified number of items
    public func provideMockPokemonList(count: Int) -> PokemonListResponse {
        var results: [PokemonListItem] = []
        
        for i in 1...count {
            results.append(
                PokemonListItem(
                    name: "pokemon-\(i)",
                    url: "https://pokeapi.co/api/v2/pokemon/\(i)/"
                )
            )
        }
        
        return PokemonListResponse(count: results.count, results: results)
    }
    
    /// Provides a mock Pokemon with the specified ID
    public func provideMockPokemon(id: Int) -> Pokemon {
        return Pokemon(
            id: id,
            name: "pokemon-\(id)",
            types: [
                PokemonTypes(slot: 1, type: PokemonType(name: "normal"))
            ],
            sprites: Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"),
            abilities: [
                Ability(ability: Ability.AbilityDetail(name: "mock-ability"), isHidden: false, slot: 1)
            ],
            moves: [
                Move(move: MoveDetail(name: "mock-move"))
            ],
            stats: [
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "hp", url: "https://pokeapi.co/api/v2/stat/1/")),
                Stat(baseStat: 50, effort: 0, stat: StatDetail(name: "attack", url: "https://pokeapi.co/api/v2/stat/2/"))
            ]
        )
    }
}

// MARK: - UI Testing Helper

/// Helper for UI testing scenarios
@MainActor
public struct UITestHelper {
    /// The shared instance
    public static let shared = UITestHelper()
    
    /// Check if we should pre-populate the cache for testing
    public var shouldPrepopulateCache: Bool {
        ProcessInfo.processInfo.arguments.contains("PREPOPULATE-CACHE")
    }
} 
