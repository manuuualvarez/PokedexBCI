//
//  AccessibilityIdentifiers.swift
//  PokedexBCI
//
//  Created by Manny Alvarez on 31/05/2025.
//

import Foundation

/// This file contains accessibility identifiers that should be used in the application
/// to make UI testing more reliable.

struct AccessibilityIdentifiers {
    
    struct PokemonList {
        static let collectionView = "pokemon-collection-view"
        static let pokemonCell = "pokemon-cell"
        static let pokemonName = "pokemon-name"
        static let pokemonImage = "pokemon-image"
        static let searchBar = "pokemon-search-bar"
    }
    
    struct PokemonDetail {
        static let scrollView = "detail-scroll-view"
        static let backButton = "back-button"
        static let pokemonImage = "pokemon-image"
        static let pokemonName = "pokemon-name-label"
        static let pokemonId = "pokemon-id-label"
        static let typeContainer = "type-container"
        static let typeLabel = "type-label"
    }
    
    struct StatsSection {
        static let container = "stats-section-container"
        static let title = "stats-section-title"
        static let statName = "stat-name"
        static let statValue = "stat-value"
        static let statProgressBackground = "stat-progress-background"
        static let statProgressFill = "stat-progress-fill"
    }
    
    struct AbilitiesSection {
        static let container = "abilities-section-container"
        static let title = "abilities-section-title"
        static let abilityContainer = "ability-container"
        static let abilityLabel = "ability-label"
    }
    
    struct MovesSection {
        static let container = "moves-section-container"
        static let title = "moves-section-title"
        static let moveContainer = "move-container"
        static let moveLabel = "move-label"
    }
} 