//
//  CacheLoadingStrategy.swift
//  PokedexBCI
//
//  Created by Manny Alvarez on 21/03/2025.
//

/// Protocol defining the strategy for loading cache
public protocol CacheLoadingStrategy {
    /// Whether to load cache on initialization
    var shouldLoadCacheOnInit: Bool { get }
}

/// Default implementation that loads cache on initialization
/// This is the standard production behavior that enables the caching functionality.
struct DefaultCacheLoadingStrategy: CacheLoadingStrategy {
    var shouldLoadCacheOnInit: Bool { true }
}

