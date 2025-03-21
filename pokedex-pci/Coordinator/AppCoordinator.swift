import UIKit
import SwiftData

@MainActor
final class AppCoordinator {
    
    // MARK: - Properties:
    
    private let navigationController: UINavigationController
    private let modelContainer: ModelContainer
    
    init(navigationController: UINavigationController) throws {
        self.navigationController = navigationController
        self.modelContainer = try ModelContainer(for: PokemonBasicCache.self)
    }
    
    func start() {
        showPokemonList()
    }
    
    func showPokemonList() {
        let viewModel = PokemonListViewModel(modelContainer: modelContainer)
        let viewController = PokemonListViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showPokemonDetail(pokemon: Pokemon) {
        let viewModel = PokemonDetailViewModel(pokemon: pokemon)
        let viewController = PokemonDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
} 
