//
//  PokemonListViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation
import Combine
import SwiftData
// Import LocalizedError explicitly
import Foundation.NSError

/// Protocol defining the interface for PokemonListViewModel
@MainActor
protocol PokemonListViewModelProtocol: ObservableObject {
    // MARK: - PROPERTIES
    var state: PokemonListState { get }
    var filteredPokemon: [Pokemon] { get }
    var searchText: String { get set }
    
    // MARK: - Published Publishers
    var statePublisher: Published<PokemonListState>.Publisher { get }
    var filteredPokemonPublisher: Published<[Pokemon]>.Publisher { get }
    var searchTextPublisher: Published<String>.Publisher { get }
    
    // MARK: - Methods
    func fetchPokemon() async
    func fetchPokemonDetails(id: Int) async throws -> Pokemon
    func setPokemon(_ pokemon: [Pokemon])
    func setState(_ state: PokemonListState)
    func cachePokemon(_ pokemon: [Pokemon]) async
    func loadCachedPokemon() async
    func cancelAllRequests()
}

/// Represents the different states of the Pokemon list
enum PokemonListState: Equatable {
    case idle
    case loading(progress: Int, total: Int)
    case loaded([Pokemon])
    case error(String)
    
    static func == (lhs: PokemonListState, rhs: PokemonListState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let progress1, let total1), .loading(let progress2, let total2)):
            return progress1 == progress2 && total1 == total2
        case (.loaded(let pokemon1), .loaded(let pokemon2)):
            return pokemon1 == pokemon2
        case (.error(let message1), .error(let message2)):
            return message1 == message2
        default:
            return false
        }
    }
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
/// - Robust error handling and retry capabilities
///
@MainActor
final class PokemonListViewModel: PokemonListViewModelProtocol {
    
    // MARK: - Published Properties:
    /// These properties are observed using Combine's @Published property wrapper
    /// When these values change, subscribers will be notified
    @Published private(set) var state: PokemonListState = .idle
    @Published private(set) var filteredPokemon: [Pokemon] = []
    @Published var searchText: String = ""
    
    // MARK: - Published Publishers:
    var statePublisher: Published<PokemonListState>.Publisher { $state }
    var filteredPokemonPublisher: Published<[Pokemon]>.Publisher { $filteredPokemon }
    var searchTextPublisher: Published<String>.Publisher { $searchText }
    
    // MARK: - Private Properties:
    
    private(set) var pokemon: [Pokemon] = []
    private var cancellables = Set<AnyCancellable>()
    private let modelContainer: ModelContainer
    private let networkManager: NetworkManagerProtocol
    private let cacheLoadingStrategy: CacheLoadingStrategy
    private var isLoading = false
    
    // Regular stored property for the fetch task
    private var fetchTask: Task<Void, Never>?
    
    // MARK: - Initialization:
    
    init(modelContainer: ModelContainer, 
         networkManager: NetworkManagerProtocol = NetworkManager(),
         cacheLoadingStrategy: CacheLoadingStrategy = DefaultCacheLoadingStrategy()
    ) {
        self.modelContainer = modelContainer
        self.networkManager = networkManager
        self.cacheLoadingStrategy = cacheLoadingStrategy
        setupBindings()
        // Use the strategy to decide whether to load cache
        if cacheLoadingStrategy.shouldLoadCacheOnInit {
            Task {
                await loadCachedPokemon()
            }
        }
    }
    
    deinit {
        // Cancel all requests when this view model is deallocated
        fetchTask?.cancel()
        networkManager.cancelAllRequests()
    }
    
    // MARK: - Protocol Methods
    
    /// Sets the Pokemon array and updates the filtered array
    /// - Parameter pokemon: The array of Pokemon to set
    func setPokemon(_ pokemon: [Pokemon]) {
        self.pokemon = pokemon
        self.filteredPokemon = pokemon
    }
    
    /// Sets the view model's state
    /// - Parameter state: The new state to set
    func setState(_ state: PokemonListState) {
        self.state = state
    }
    
    /// Caches Pokemon data for faster loading
    /// - Parameter pokemon: Array of Pokemon to cache
    func cachePokemon(_ pokemon: [Pokemon]) async {
        guard !pokemon.isEmpty else { return }
        
        do {
            let descriptor = FetchDescriptor<PokemonCache>()
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
                let cache = PokemonCache(from: pokemon)
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
    
    /// Loads Pokemon from cache if available and valid
    /// If the cache is invalid or expired, fetches fresh data from the network
    func loadCachedPokemon() async {
        guard !isLoading else { 
            print("⚠️ Already loading Pokemon data")
            return 
        }
        
        isLoading = true
        // Set the loading state
        self.setState(.loading(progress: 0, total: 0))
        
        do {
            var cacheDescriptor = FetchDescriptor<PokemonCache>()
            cacheDescriptor.sortBy = [SortDescriptor(\PokemonCache.id, order: .forward)]
            let cacheEntries = try modelContainer.mainContext.fetch(cacheDescriptor)
            
            let validCacheEntries = cacheEntries.filter { $0.isValid }
            if !validCacheEntries.isEmpty {
                handleValidCache(validCacheEntries)
                // isLoading is set to false in handleValidCache() method
                return
            }
            
            // If we reach here, there's no valid cache
            // Must set isLoading to false before calling fetchPokemon
            isLoading = false
            await fetchPokemon()
            
        } catch {
            print("❌ loadCachedPokemon() - Error: \(error.localizedDescription)")
            isLoading = false
            await fetchPokemon()
        }
    }
    
    /// Helper method to handle valid cache entries
    private func handleValidCache(_ validCache: [PokemonCache]) {
        print("✅ loadCachedPokemon() - Using \(validCache.count) valid cached entries")
        // Convert cache to Pokemon objects
        let cachedPokemon = validCache.map { $0.convertAsPokemon() }
        // Update properties first
        self.pokemon = cachedPokemon
        self.filteredPokemon = cachedPokemon
        // Then update state
        self.setState(.loaded(cachedPokemon))
        isLoading = false
        print("✅ loadCachedPokemon() - Successfully completed with \(cachedPokemon.count) Pokemon from cache")
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
    
    // MARK: - Public Methods:
    /// Cancels all ongoing network requests
    /// This is important for memory management and preventing unwanted updates
    /// when the view is no longer visible or the viewmodel is being deallocated
    func cancelAllRequests() {
        // Cancel active fetch task
        fetchTask?.cancel()
        fetchTask = nil
        
        // Cancel ongoing network requests
        networkManager.cancelAllRequests()
        
        // Update state if we're still loading
        if case .loading = state {
            if !pokemon.isEmpty {
                // If we have some data, show it
                state = .loaded(pokemon)
            } else {
                // Otherwise just go back to idle
                state = .idle
            }
        }
        
        isLoading = false
        print("🚫 All requests cancelled")
    }
    
    /// Fetches Pokemon data from the network
    func fetchPokemon() async {
        // Cancel any existing tasks before starting a new one
        cancelAllRequests()
        
        guard !isLoading else {
            print("⚠️ Network fetch already in progress")
            return
        }
        
        isLoading = true
        state = .loading(progress: 0, total: 151)
        
        // Create a new task for this fetch operation
        fetchTask = Task {
            do {
                // Try up to 2 times if the error is retryable
                let maxRetries = 1 // One retry attempt (2 total attempts)
                var lastError: Error? = nil
                
                for attempt in 0...maxRetries {
                    do {
                        // Break immediately if task was cancelled
                        if Task.isCancelled {
                            isLoading = false
                            return
                        }
                        
                        if attempt > 0 {
                            print("🔄 Retry attempt \(attempt) for Pokemon list fetch")
                            // Add a small delay before retry
                            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                        }
                        
                        let response = try await networkManager.fetchPokemonList()
                        print("📥 Fetched Pokemon list with \(response.results.count) entries")
                
                        // Check if task was cancelled after fetching the list
                        if Task.isCancelled {
                            isLoading = false
                            return
                        }
                        
                        var loadedPokemon: [Pokemon] = []
                        let total = response.results.count
                        
                        for (index, _ ) in response.results.enumerated() {
                            // Check if our task was cancelled in the middle of fetching
                            if Task.isCancelled {
                                isLoading = false
                                return
                            }
                            
                            do {
                                let pokemon = try await networkManager.fetchPokemonDetail(id: index + 1)
                                loadedPokemon.append(pokemon)
                                let progress = loadedPokemon.count
                                state = .loading(progress: progress, total: total)
                            } catch let error as NetworkError {
                                print("❌ Error fetching Pokemon #\(index + 1): \(error.userMessage)")
                                // Continue loading others even if one fails
                            } catch {
                                // Handle localized errors or any other errors
                                if let errorMsg = (error as? LocalizedError)?.errorDescription {
                                    print("❌ Error fetching Pokemon #\(index + 1): \(errorMsg)")
                                } else {
                                    print("❌ Unknown error fetching Pokemon #\(index + 1): \(error.localizedDescription)")
                                }
                                // Continue loading others even if one fails
                            }
                        }
                        
                        // Final check for cancellation before processing results
                        if Task.isCancelled {
                            isLoading = false
                            return
                        }
                        
                        loadedPokemon.sort { $0.id < $1.id }
                        pokemon = loadedPokemon
                        filteredPokemon = loadedPokemon
                        
                        if loadedPokemon.isEmpty {
                            state = .error("Failed to load Pokemon data")
                        } else {
                            print("🎉 Successfully loaded \(loadedPokemon.count) Pokemon")
                            state = .loaded(loadedPokemon)
                            await cachePokemon(loadedPokemon)
                        }
                        
                        // If we successfully completed, break out of retry loop
                        break
                        
                    } catch let error as NetworkError where error.isRetryable && attempt < maxRetries {
                        // If error is retryable and we haven't used all our retries, continue to next attempt
                        print("⚠️ Retryable network error: \(error.userMessage), will retry...")
                        lastError = error
                        continue
                    } catch let error {
                        // For non-retryable errors or if we've used all our retries, rethrow
                        lastError = error
                        throw error
                    }
                }
            } catch let error as NetworkError {
                // Handle specific network errors with user-friendly messages
                print("❌ Network error: \(error.userMessage)")
                state = .error(error.userMessage)
            } catch {
                // Handle localized errors first (including TestNetworkError)
                if let localizedError = error as? LocalizedError, 
                   let errorDescription = localizedError.errorDescription {
                    print("❌ Localized error: \(errorDescription)")
                    state = .error(errorDescription)
                } else {
                    // Last resort - any other non-localized errors
                    print("❌ Unexpected error: \(error.localizedDescription)")
                    state = .error("An unexpected error occurred. Please try again.")
                }
            }
            
            isLoading = false
        }
    }
    
    /// Fetches detailed Pokemon information for a specific Pokemon
    /// - Parameter id: The Pokemon's ID
    /// - Returns: A Pokemon model with full details
    func fetchPokemonDetails(id: Int) async throws -> Pokemon {
        print("🔍 Fetching detailed information for Pokemon #\(id)...")
        do {
            return try await networkManager.fetchPokemonDetail(id: id)
        } catch let error as NetworkError {
            print("❌ Network error fetching Pokemon #\(id): \(error.userMessage)")
            throw error
        } catch {
            // Handle any kind of localized error, including TestNetworkError
            if let localizedError = error as? LocalizedError {
                print("❌ Localized error fetching Pokemon #\(id): \(localizedError.errorDescription ?? "")")
                throw error // Preserve original error for test pattern matching
            } else {
                // Map unknown errors to NetworkError as a last resort
                let networkError = NetworkError.mapError(error)
                print("❌ Error fetching Pokemon #\(id): \(networkError.userMessage)")
                throw networkError
            }
        }
    }
}
