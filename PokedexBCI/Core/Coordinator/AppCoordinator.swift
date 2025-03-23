import UIKit
import SwiftData

@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - Properties
    
    private let navigationController: UINavigationController
    private let networkManagerFactory: NetworkManagerFactoryProtocol = DefaultNetworkManagerFactory()
    /// Detects if the app is running in UI testing mode
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI-TESTING")
    }
    let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController) throws {
        self.navigationController = navigationController
        self.modelContainer = try ModelContainer(for: PokemonCache.self)
        navigationController.navigationBar.backgroundColor = .red
    }
    
    // MARK: - Navigation Methods
    
    func start() {
        showPokemonList()
    }
    
    func showPokemonList() {
        // Create ViewModel with real or mocked data based on testing mode
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
    
    // MARK: - Helpers
    
    /// Creates a strategy that disables caching for UI tests
    private func createNoCacheStrategy() -> CacheLoadingStrategy {
        return TestCacheStrategy()
    }
}
