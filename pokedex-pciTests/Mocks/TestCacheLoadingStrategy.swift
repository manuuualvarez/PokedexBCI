//
//  TestCacheLoadingStrategy.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 21/03/2025.
//

@testable import pokedex_pci
/// A test-specific cache loading strategy that prevents automatic cache loading
///
/// This strategy is designed specifically for testing purposes. By returning false for
/// `shouldLoadCacheOnInit`, it prevents the automatic loading of cache data during
/// ViewModel initialization, which gives tests more control over when and how the cache
/// is loaded.
///
/// Benefits for testing:
/// - Avoids unwanted side effects from automatic cache loading
/// - Makes tests more predictable and isolated
/// - Allows explicit testing of cache loading behavior
/// - Prevents tests from interfering with each other through shared cache state
struct TestCacheLoadingStrategy: CacheLoadingStrategy {
    var shouldLoadCacheOnInit: Bool { false }
}
