//
//  CacheLoadingStrategy.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//

/// Protocol defining the cache loading strategy
///
/// This protocol allows for different caching behaviors to be injected into the PokemonListViewModel.
/// It decouples the caching policy from the ViewModel implementation, making it more flexible
/// and easier to test.
///
/// Use cases:
/// - Production: Use DefaultCacheLoadingStrategy which automatically loads cache on initialization
/// - Testing: Use a test-specific strategy to disable cache loading for more predictable tests
/// - Different app configurations: Create custom strategies for different app configurations
protocol CacheLoadingStrategy {
    /// Determines whether cache should be loaded automatically on ViewModel initialization
    /// - Returns: true if cache should be loaded during initialization, false otherwise
    var shouldLoadCacheOnInit: Bool { get }
}

/// Default implementation that loads cache on initialization
/// This is the standard production behavior that enables the caching functionality.
struct DefaultCacheLoadingStrategy: CacheLoadingStrategy {
    var shouldLoadCacheOnInit: Bool { true }
}

