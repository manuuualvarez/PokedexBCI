import UIKit
import SwiftData

@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - Properties:
    
    private let navigationController: UINavigationController
    private let networkManagerFactory: NetworkManagerFactoryProtocol = DefaultNetworkManagerFactory()
    /// Boolean flag to indicate if the app is running in UI testing mode
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI-TESTING")
    }
    let modelContainer: ModelContainer
    
    // MARK: - Initialization:
    
    init(navigationController: UINavigationController) throws {
        self.navigationController = navigationController
        self.modelContainer = try ModelContainer(for: PokemonCache.self)
        navigationController.navigationBar.backgroundColor = .red
    }
    
    // MARK: - Public methods:
    
    func start() {
        showPokemonList()
    }
    
    func showPokemonList() {
        ///  If we're in UI testing mode, create a view model with mock network manager else use real API data
        let viewModel: any PokemonListViewModelProtocol
        
        if isUITesting {
            let networkManager = networkManagerFactory.createNetworkManager(for: .uiTest)
            
            viewModel = PokemonListViewModel(
                modelContainer: modelContainer,
                networkManager: networkManager,
                cacheLoadingStrategy: createNoCacheStrategy()
            )
        } else {
            viewModel = PokemonListViewModel(modelContainer: modelContainer)
        }
        
        let viewController = PokemonListViewController(viewModel: viewModel)
        viewController.coordinator = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showPokemonDetail(pokemon: Pokemon) {
        let viewModel = PokemonDetailViewModel(pokemon: pokemon)
        let viewController = PokemonDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Helper Methods
    /// Creates a cache strategy that doesn't load cache for UI testing
    private func createNoCacheStrategy() -> CacheLoadingStrategy {
        // Use the shared TestCacheStrategy from our testing infrastructure
        return TestCacheStrategy()
    }
}
