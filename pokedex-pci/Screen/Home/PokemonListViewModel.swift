//
//  PokemonListViewModel.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//


import Foundation
import Combine

/// Represents the different states of the Pokemon list
enum PokemonListState {
    case idle
    case loading
    case loaded([Pokemon])
    case error(String)
}

final class PokemonListViewModel {
    // MARK: - Published Properties
    /// These properties are observed using Combine's @Published property wrapper
    /// When these values change, subscribers will be notified
    @Published private(set) var state: PokemonListState = .idle
    @Published private(set) var filteredPokemon: [Pokemon] = []
    @Published var searchText: String = ""
    
    // MARK: - Private Properties
    private var pokemon: [Pokemon] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterPokemon(with: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func filterPokemon(with query: String) {
        if query.isEmpty {
            filteredPokemon = pokemon
        } else {
            filteredPokemon = pokemon.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
    }
    
    // MARK: - Public Methods
    @MainActor
    func fetchPokemon() async {
        state = .loading
        
        do {
            let response = try await NetworkManager.shared.fetchPokemonList()
            
            var detailedPokemon: [Pokemon] = []
            for (index, _) in response.results.enumerated() {
                let pokemon = try await NetworkManager.shared.fetchPokemonDetail(id: index + 1)
                detailedPokemon.append(pokemon)
            }
                        
            pokemon = detailedPokemon
            filteredPokemon = detailedPokemon
            state = .loaded(detailedPokemon)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
