//
//  PokemonListViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import Combine
import SwiftData

/// Represents the different states of the Pokemon list
enum PokemonListState {
    case idle
    case loading(progress: Int, total: Int)
    case loaded([Pokemon])
    case error(String)
}

/// A view model that manages the Pokemon list, including caching and network operations.
/// This class implements a caching strategy using Swift Data to improve performance and offline capabilities.
///
/// The caching strategy works as follows:
/// 1. On initialization, it attempts to load cached basic Pokemon data
/// 2. If cached data exists and hasn't expired (15 minutes), it's displayed immediately
/// 3. If cache is expired or doesn't exist, it fetches fresh basic data from the network
/// 4. New basic data is cached for future use with a 15-minute expiration
///
/// This approach provides:
/// - Fast initial load with cached basic data
/// - Reduced network usage
/// - Better performance
/// - Automatic cache refresh after 15 minutes
///
@MainActor
final class PokemonListViewModel {
    
    // MARK: - Published Properties:
    /// These properties are observed using Combine's @Published property wrapper
    /// When these values change, subscribers will be notified
    @Published private(set) var state: PokemonListState = .idle
    @Published private(set) var filteredPokemon: [Pokemon] = []
    @Published var searchText: String = ""
    
    // MARK: - Private Properties:
    
    private var pokemon: [Pokemon] = []
    private var cancellables = Set<AnyCancellable>()
    private let modelContainer: ModelContainer
    private var isLoading = false
    
    // MARK: - Initialization:
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        setupBindings()
        Task {
            await loadCachedPokemon()
        }
    }
        
    // MARK: - Search Bindings:
    /// Sets up the reactive binding for the search functionality using Combine.
    /// 
    /// The search implementation works as follows:
    /// 1. The `searchText` publisher emits values whenever the search text changes
    /// 2. `.debounce(for: .milliseconds(300))` prevents rapid-fire updates by waiting
    ///    300ms after the last keystroke before processing the search
    /// 3. The search is performed on the main queue to ensure thread safety
    /// 4. Uses [weak self] to prevent retain cycles in the closure
    ///
    /// Search behavior:
    /// - Empty search (`""`) shows all Pokemons
    /// - Non-empty search filters Pokemon by name (case-insensitive)
    /// - Updates are reflected immediately in the UI through the `filteredPokemon` binding
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterPokemon(with: query)
            }
            .store(in: &cancellables)
    }
    
    /// Filters the Pokemon array based on the search query
    /// - Parameter query: The search text entered by the user
    private func filterPokemon(with query: String) {
        if query.isEmpty {
            // When search is empty, show all Pokemon
            filteredPokemon = pokemon
        } else {
            // Filter Pokemon whose names contain the search query (case-insensitive)
            filteredPokemon = pokemon.filter { 
                $0.name.lowercased().contains(query.lowercased())
            }
        }
    }
    
    // MARK: - Private Methods:
    
    private func loadCachedPokemon() async {
        guard !isLoading else { 
            print("⚠️ Already loading Pokemon data")
            return 
        }
        isLoading = true
        print("🔍 Checking for cached Pokemon data...")
        /// FetchDescriptor is a SwiftData type that defines how to fetch data from the persistent store.
        /// It's similar to NSFetchRequest in Core Data, allowing you to:
        /// - Retrieve specific model types (like PokemonBasicCache)
        /// - Define sorting and filtering criteria
        /// - Configure fetch limits and offsets
        var descriptor = FetchDescriptor<PokemonBasicCache>()
        // Sort by Pokemon ID in descending order (lowest to lowest)
        descriptor.sortBy = [SortDescriptor(\PokemonBasicCache.id, order: .forward)]
        do {
            let cachedPokemon = try modelContainer.mainContext.fetch(descriptor)
            if !cachedPokemon.isEmpty {
                let validCache = cachedPokemon.filter { $0.isValid }
                if !validCache.isEmpty {
                    print("✅ Found \(validCache.count) valid cached Pokemon")
                    print("📅 Last updated: \(validCache.first?.lastUpdated.formatted() ?? "Unknown")")
                    print("⏰ Expires at: \(validCache.first?.expiresAt.formatted() ?? "Unknown")")
                    pokemon = validCache.map { $0.toBasicPokemon() }
                    filteredPokemon = pokemon
                    state = .loaded(pokemon)
                    isLoading = false
                    return
                }
            }
            // Only fetch if we don't have valid cache
            print("❌ No valid cache found, fetching fresh data...")
            isLoading = false
            await fetchPokemon()
        } catch {
            print("❌ Error loading cached Pokemon: \(error)")
            isLoading = false
            await fetchPokemon()
        }
    }
    
    private func cacheBasicPokemon(_ pokemon: [Pokemon]) async {
        guard !pokemon.isEmpty else { return }
        
        // Check if we already have valid cache
        let descriptor = FetchDescriptor<PokemonBasicCache>()
        do {
            let existingCache = try modelContainer.mainContext.fetch(descriptor)
            let validCache = existingCache.filter { $0.isValid }
            
            if !validCache.isEmpty {
                print("✅ Valid cache exists, skipping cache update")
                return
            }
            print("💾 Starting basic cache update...")
            // Clear expired cache
            existingCache.forEach { modelContainer.mainContext.delete($0) }
            print("🗑️ Cleared \(existingCache.count) expired cache entries")
            // Add new cache entries
            pokemon.forEach { pokemon in
                let cache = PokemonBasicCache(from: pokemon)
                modelContainer.mainContext.insert(cache)
            }
            try modelContainer.mainContext.save()
            print("✅ Successfully cached \(pokemon.count) Pokemon")
            print("📅 Cache updated at: \(Date().formatted())")
            print("⏰ Cache expires at: \(Date().addingTimeInterval(15 * 60).formatted())")
        } catch {
            print("❌ Error managing cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods:
    
    func fetchPokemon() async {
        guard !isLoading else {
            print("⚠️ Network fetch already in progress")
            return
        }
        state = .loading(progress: 0, total: 151)
        isLoading = true
        
        do {
            let response = try await NetworkManager.shared.fetchPokemonList()
            print("📥 Fetched Pokemon list with \(response.results.count) entries")
    
            var loadedPokemon: [Pokemon] = []
            let total = response.results.count
            
            for (index, _ ) in response.results.enumerated() {
                do {
                    let pokemon = try await NetworkManager.shared.fetchPokemonDetail(id: index + 1)
                    loadedPokemon.append(pokemon)
                    // Update loading progress
                    let progress = loadedPokemon.count
                    state = .loading(progress: progress, total: total)
                } catch {
                    print("❌ Error fetching Pokemon #\(index + 1): \(error.localizedDescription)")
                }
            }
            // Sort Pokemon by ID (keep the same order as he cached data)
            loadedPokemon.sort { $0.id < $1.id }
            // Update the main Pokemon arrays
            pokemon = loadedPokemon
            filteredPokemon = loadedPokemon
            
            if loadedPokemon.isEmpty {
                print("⚠️ No Pokemon were loaded")
                state = .error("Failed to load Pokemon data")
            } else {
                print("🎉 Successfully loaded \(loadedPokemon.count) Pokemon")
                state = .loaded(loadedPokemon)
                // Only update cache if we have new data
                await cacheBasicPokemon(loadedPokemon)
            }
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
        isLoading = false
    }
    
    /// Fetches detailed Pokemon information for a specific Pokemon
    /// - Parameter id: The Pokemon's ID
    /// - Returns: A Pokemon model with full details
    func fetchPokemonDetails(id: Int) async throws -> Pokemon {
        print("\n🔍 Fetching detailed information for Pokemon #\(id)...")
        return try await NetworkManager.shared.fetchPokemonDetail(id: id)
    }
}
