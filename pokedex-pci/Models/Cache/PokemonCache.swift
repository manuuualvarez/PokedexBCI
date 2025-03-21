import Foundation
import SwiftData

/// A Swift Data model that represents a cached Pokemon entity.
/// This model is used to persist Pokemon data locally using Swift Data.
///
/// The cache stores essential Pokemon information including:
/// - Basic information (id, name)
/// - Types
/// - Sprite URL
/// - Abilities
/// - Moves
/// - Last update timestamp
///
/// Example usage:
/// ```swift
/// let cache = PokemonCache(from: pokemon)
/// modelContext.insert(cache)
/// try modelContext.save()
/// ```
@Model
final class PokemonCache {
    /// The unique identifier of the Pokemon
    var id: Int
    
    /// The name of the Pokemon
    var name: String
    
    /// Array of Pokemon types (e.g., ["fire", "flying"])
    var types: [String]
    
    /// URL string for the Pokemon's sprite image
    var spriteURL: String
    
    /// Array of Pokemon ability names
    var abilities: [String]
    
    /// Array of Pokemon move names
    var moves: [String]
    
    /// Timestamp of when this cache entry was last updated
    var lastUpdated: Date
    
    /// Creates a new cache entry from a Pokemon model
    /// - Parameter pokemon: The Pokemon model to cache
    init(from pokemon: Pokemon) {
        self.id = pokemon.id
        self.name = pokemon.name
        self.types = pokemon.types.map { $0.type.name }
        self.spriteURL = pokemon.sprites.frontDefault
        self.abilities = pokemon.abilities.map { $0.ability.name }
        self.moves = pokemon.moves.map { $0.move.name }
        self.lastUpdated = Date()
    }
    
    /// Converts the cached data back into a Pokemon model
    /// - Returns: A Pokemon model with the cached data
    func toPokemon() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            types: types.map { Pokemon.PokemonType(slot: 1, type: .init(name: $0)) },
            sprites: .init(frontDefault: spriteURL),
            abilities: abilities.map { Pokemon.Ability(ability: .init(name: $0), isHidden: false, slot: 1) },
            moves: moves.map { Pokemon.Move(move: .init(name: $0)) }
        )
    }
} 