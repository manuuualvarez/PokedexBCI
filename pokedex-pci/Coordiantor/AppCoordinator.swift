//
//  AppCoordinator.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    func start()
}

/// The main coordinator of the application that handles the primary navigation flow
/// - Note: This coordinator follows a strong ownership pattern where:
///   1. Coordinator strongly owns the navigation controller
///   2. Navigation controller strongly owns its view controllers
///   3. View controllers weakly reference back to the coordinator
///
/// This creates a clean ownership hierarchy without retain cycles:
/// ```
/// AppCoordinator (strong) → UINavigationController (strong) → ViewControllers
///         ↑                                                         |
///         |                                                        |
///         └────────────────── (weak) ────────────────────────────┘
/// ```

final class AppCoordinator: Coordinator {
    /// The navigation controller owned by this coordinator
    /// - Note: This is intentionally a strong reference because:
    ///   1. The coordinator is responsible for the navigation controller's lifecycle
    ///   2. The navigation controller must exist as long as the coordinator exists
    ///   3. Making this weak would risk premature deallocation
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemRed
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.prefersLargeTitles = true
    }
    
    func start() {
        let viewModel = PokemonListViewModel()
        let viewController = PokemonListViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: false)
    }
    
    func showPokemonDetail(pokemon: Pokemon) {
        let viewModel = PokemonDetailViewModel(pokemon: pokemon)
        let viewController = PokemonDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
