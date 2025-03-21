import Foundation
import SwiftData

/// A Swift Data model that represents basic cached Pokemon information.
/// This model is used to persist essential Pokemon data locally using Swift Data.
///
/// The cache stores only the essential Pokemon information:
/// - Basic information (id, name)
/// - Sprite URL
/// - Last update timestamp
/// - Cache expiration time (15 minutes)
///
/// This approach provides faster initial loading and reduces storage requirements.
@Model
final class PokemonBasicCache {
    /// The unique identifier of the Pokemon
    var id: Int
    
    /// The name of the Pokemon
    var name: String
    
    /// URL string for the Pokemon's sprite image
    var spriteURL: String
    
    /// Timestamp of when this cache entry was last updated
    var lastUpdated: Date
    
    /// The time when this cache entry expires (15 minutes from lastUpdated)
    var expiresAt: Date
    
    /// Creates a new cache entry from a Pokemon model
    /// - Parameter pokemon: The Pokemon model to cache
    init(from pokemon: Pokemon) {
        self.id = pokemon.id
        self.name = pokemon.name
        self.spriteURL = pokemon.sprites.frontDefault
        self.lastUpdated = Date()
        self.expiresAt = Date().addingTimeInterval(15 * 60) // 15 minutes
    }
    
    /// Converts the cached data back into a basic Pokemon model
    /// - Returns: A Pokemon model with only basic information
    func toBasicPokemon() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            types: [],
            sprites: .init(frontDefault: spriteURL),
            abilities: [],
            moves: []
        )
    }
    
    /// Checks if the cache entry is still valid
    /// - Returns: true if the cache hasn't expired, false otherwise
    var isValid: Bool {
        Date() < expiresAt
    }
} 