import XCTest
import SnapshotTesting
import Combine
import SwiftData
import Kingfisher
@testable import pokedex_pci

class PokemonListViewControllerSnapshotTests: XCTestCase {
    
    // MARK: -  Set to true ONLY when you need to capture new reference images
    // Then set back to false for normal test runs
    let recordMode = false
    
    // Define a constant delay to ensure UI elements are fully loaded
    let renderDelay: TimeInterval = 1.0
    
    // Store created mocks to clean up properly
    private var mockViewModel: MockPokemonListViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        
        // Force light mode at the application level
        UIView.appearance().overrideUserInterfaceStyle = .light
    }
    
    override func tearDown() {
        // Reset global UI appearance changes
        UIView.appearance().overrideUserInterfaceStyle = .unspecified
        
        // Clean up resources
        cancellables.removeAll()
        mockViewModel = nil
        
        super.tearDown()
    }
    
    @MainActor
    func testPokemonListViewController() async {
        // Define the devices to test
        let devices: [(config: ViewImageConfig, name: String)] = [
            (.iPhone15, "iPhone15"), 
            (.iPhone16, "iPhone16")
        ]
        // Test all possible states
        let states: [PokemonListState] = await [
            .loading(progress: 5, total: 10),
            .loaded(createMockPokemonList()),
        ]
        
        for state in states {
            // Create mock Pokemon for the view model
            let mockPokemon = await createMockPokemonList()
            
            // Create mock view model with the appropriate state
            mockViewModel = MockPokemonListViewModel(mockPokemon: mockPokemon, initialState: state)
            
            // Test on each device configuration
            for (deviceConfig, deviceName) in devices {
                // Create the view controller with the mock view model
                let viewController = PokemonListViewController(viewModel: mockViewModel)
                
                // Create a navigation controller and embed the view controller
                let navigationController = UINavigationController(rootViewController: viewController)
                
                // Force light mode for both controllers
                navigationController.overrideUserInterfaceStyle = .light
                viewController.overrideUserInterfaceStyle = .light
                
                // Set title to be displayed in nav bar
                viewController.title = "Pokédex"
                navigationController.navigationBar.prefersLargeTitles = true
                
                // Set the navigation bar appearance to match the app's red color
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .systemRed
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
                navigationController.navigationBar.compactAppearance = appearance
                navigationController.navigationBar.tintColor = .white
                
                // Load views and force appearance lifecycle
                navigationController.loadViewIfNeeded()
                viewController.loadViewIfNeeded()
                navigationController.beginAppearanceTransition(true, animated: false)
                navigationController.endAppearanceTransition()
                
                // For loading state, ensure the view model properly publishes the state
                // This is crucial because the view responds to state changes through publishers
                if case .loading = state {
                    // Force a state change notification to ensure the progress view is shown
                    // We need to wait for the main thread to process this
                    let expectation = XCTestExpectation(description: "State update for loading")
                    DispatchQueue.main.async {
                        self.mockViewModel.setState(.loading(progress: 5, total: 10))
                        // Need a small delay after state change for UI to update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            expectation.fulfill()
                        }
                    }
                    await fulfillment(of: [expectation], timeout: 1.0)
                }
                // For loaded state, ensure the view model properly publishes the state
                else if case .loaded = state {
                    // Force a state change notification to ensure the data is loaded
                    let expectation = XCTestExpectation(description: "State update for loaded")
                    DispatchQueue.main.async {
                        // First set to loading briefly to trigger the UI update cycle
                        self.mockViewModel.setState(.loading(progress: 10, total: 10))
                        // Then set to loaded after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.mockViewModel.setState(.loaded(self.mockViewModel.pokemonList))
                            // Add extra delay to ensure UI fully updates
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                expectation.fulfill()
                            }
                        }
                    }
                    await fulfillment(of: [expectation], timeout: 1.5)
                }
                
                // Find and replace any async image loading with test images
                replaceImagesInViewController(viewController)
                
                // Special handling for loading state to ensure progress view is visible
                if case .loading = state {
                    // Directly access the progress view and make it visible if possible
                    if let progressView = findProgressView(in: viewController.view) {
                        progressView.isHidden = false
                        progressView.progress = 0.5 // 5/10 = 50%
                    }
                    
                    // Also try to find and update the progress label
                    if let progressLabel = findProgressLabel(in: viewController.view) {
                        progressLabel.isHidden = false
                        progressLabel.text = "Loading Pokémons... 5/10"
                    }
                }
                // Special handling for loaded state to ensure images are visible
                else if case .loaded = state {
                    // Find the collection view and force it to reload
                    if let collectionView = findCollectionView(in: viewController.view) {
                        collectionView.reloadData()
                        collectionView.layoutIfNeeded()
                        
                        // Force each cell to render its image
                        for cell in collectionView.visibleCells {
                            if let pokemonCell = cell as? PokemonCell, 
                               let nameLabel = findLabel(in: pokemonCell.contentView) {
                                let pokemonName = nameLabel.text?.lowercased() ?? "bulbasaur"
                                
                                // Find and directly set images in the cell
                                if let imageView = findImageView(in: pokemonCell.contentView) {
                                    imageView.setTestImage(for: pokemonName)
                                    imageView.setNeedsDisplay()
                                }
                            }
                        }
                    }
                }
                
                // Wait for view to fully load and layout
                navigationController.view.setNeedsLayout()
                navigationController.view.layoutIfNeeded()
                viewController.view.setNeedsLayout()
                viewController.view.layoutIfNeeded()
                
                // Use a longer delay for loading state to ensure UI updates
                let currentDelay = (state == .loading(progress: 5, total: 10)) ? renderDelay * 1.5 : renderDelay
                
                // Use expectation to ensure UI has time to fully render
                let expectation = XCTestExpectation(description: "Wait for UI to render")
                DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                    expectation.fulfill()
                }
                
                await fulfillment(of: [expectation], timeout: currentDelay + 1.0)
                
                // Take snapshot with device-specific naming
                assertSnapshot(
                    of: navigationController,
                    as: .image(on: deviceConfig),
                    named: "\(stateToString(state))_\(deviceName)",
                    record: recordMode
                )
            }
        }
    }
    
    // Helper method to force appearance style recursively on all subviews
    private func forceAppearanceRecursively(on view: UIView, style: UIUserInterfaceStyle) {
        view.overrideUserInterfaceStyle = style
        
        // Apply to all subviews recursively
        for subview in view.subviews {
            forceAppearanceRecursively(on: subview, style: style)
        }
    }
    
    // Helper method to recursively find and replace images in a view controller's view hierarchy
    @MainActor
    private func replaceImagesInViewController(_ viewController: UIViewController) {
        // Force light mode recursively
        forceAppearanceRecursively(on: viewController.view, style: .light)
        
        // Find all UICollectionViews and process their visible cells
        if let collectionView = viewController.view.subviews.first(where: { $0 is UICollectionView }) as? UICollectionView {
            // Force a layout to ensure cells are created
            collectionView.layoutIfNeeded()
            
            // Process visible cells
            for cell in collectionView.visibleCells {
                if let pokemonCell = cell as? PokemonCell {
                    // Get the pokemon name from the cell
                    if let nameLabel = findLabel(in: pokemonCell.contentView) {
                        let pokemonName = nameLabel.text?.lowercased() ?? "bulbasaur"
                        replaceImages(in: cell, pokemonName: pokemonName)
                    } else {
                        // Default fallback if we can't determine the pokemon
                        replaceImages(in: cell, pokemonName: "bulbasaur")
                    }
                }
            }
        }
    }
    
    // Helper to find a label in a view hierarchy
    private func findLabel(in view: UIView) -> UILabel? {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                return label
            }
            if let foundLabel = findLabel(in: subview) {
                return foundLabel
            }
        }
        return nil
    }
    
    // Helper method to recursively find and replace images in a view hierarchy
    @MainActor
    private func replaceImages(in view: UIView, pokemonName: String) {
        // If this is an image view, set our test image
        if let imageView = view as? UIImageView {
            // Stop any ongoing Kingfisher downloads
            imageView.kf.cancelDownloadTask()
            
            // Use the existing helper to set a test image
            imageView.setTestImage(for: pokemonName)
            
            // Mark as needing layout to ensure image is displayed
            imageView.setNeedsDisplay()
            imageView.setNeedsLayout()
        }
        
        // Recursively check all subviews
        for subview in view.subviews {
            replaceImages(in: subview, pokemonName: pokemonName)
        }
    }
    
    // Helper method to convert state to string for snapshot naming
    private func stateToString(_ state: PokemonListState) -> String {
        switch state {
        case .idle:
            return "idle"
        case .loading(let progress, let total):
            return "loading_\(progress)_of_\(total)"
        case .loaded:
            return "loaded"
        case .error:
            return "error"
        }
    }
    
    // Helper method to create mock Pokemon list
    private func createMockPokemonList() async -> [Pokemon] {
        return [
            createMockPokemon(name: "Bulbasaur", type: "grass", id: 1),
            createMockPokemon(name: "Charmander", type: "fire", id: 4),
            createMockPokemon(name: "Squirtle", type: "water", id: 7),
            createMockPokemon(name: "Pikachu", type: "electric", id: 25)
        ]
    }
    
    // Helper method to create a single mock Pokemon
    private func createMockPokemon(name: String, type: String, id: Int) -> Pokemon {
        return Pokemon(
            id: id,
            name: name.lowercased(),
            types: [
                PokemonTypes(
                    slot: 1,
                    type: PokemonType(name: type)
                )
            ],
            sprites: Sprites(frontDefault: "https://example.com/dummy.png"),
            abilities: [],
            moves: [],
            stats: []
        )
    }
    
    // Helper to find a progress view in the view hierarchy
    private func findProgressView(in view: UIView) -> UIProgressView? {
        for subview in view.subviews {
            if let progressView = subview as? UIProgressView {
                return progressView
            }
            if let foundProgressView = findProgressView(in: subview) {
                return foundProgressView
            }
        }
        return nil
    }
    
    // Helper to find a label that could be the progress label
    private func findProgressLabel(in view: UIView) -> UILabel? {
        for subview in view.subviews {
            if let label = subview as? UILabel, 
               label.text?.contains("Loading") == true || 
               label.text?.contains("Pokémon") == true {
                return label
            }
            if let foundLabel = findProgressLabel(in: subview) {
                return foundLabel
            }
        }
        return nil
    }
    
    // Helper to find a collection view in the view hierarchy
    private func findCollectionView(in view: UIView) -> UICollectionView? {
        for subview in view.subviews {
            if let collectionView = subview as? UICollectionView {
                return collectionView
            }
            if let foundCollectionView = findCollectionView(in: subview) {
                return foundCollectionView
            }
        }
        return nil
    }
    
    // Helper to find an image view in the view hierarchy
    private func findImageView(in view: UIView) -> UIImageView? {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView {
                return imageView
            }
            if let foundImageView = findImageView(in: subview) {
                return foundImageView
            }
        }
        return nil
    }
}

// MARK: - Mock ViewModel for Testing

@MainActor
class MockPokemonListViewModel: PokemonListViewModelProtocol, ObservableObject {
    var pokemonList: [Pokemon] = []
    @Published private(set) var filteredPokemon: [Pokemon] = []
    @Published var searchText: String = ""
    @Published private(set) var state: PokemonListState
    
    // MARK: - Published Publishers
    var statePublisher: Published<PokemonListState>.Publisher { $state }
    var filteredPokemonPublisher: Published<[Pokemon]>.Publisher { $filteredPokemon }
    var searchTextPublisher: Published<String>.Publisher { $searchText }
    
    init(mockPokemon: [Pokemon], initialState: PokemonListState) {
        self.pokemonList = mockPokemon
        self.filteredPokemon = mockPokemon
        self.state = initialState
        
        // Set up search text binding to filter Pokemon
        $searchText
            .sink { [weak self] query in
                self?.filterPokemon(with: query)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Protocol Methods
    func fetchPokemon() async {
        // No-op in mock - we already set the state in init
    }
    
    func fetchPokemonDetails(id: Int) async throws -> Pokemon {
        // Return a mock Pokemon if it exists in our list
        if let pokemon = pokemonList.first(where: { $0.id == id }) {
            return pokemon
        }
        // Otherwise throw an error
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Pokemon not found"])
    }
    
    func setPokemon(_ pokemon: [Pokemon]) {
        self.pokemonList = pokemon
        self.filteredPokemon = pokemon
    }
    
    func setState(_ state: PokemonListState) {
        self.state = state
    }
    
    func cachePokemon(_ pokemon: [Pokemon]) async {
        // No-op in mock - we don't need to actually cache
    }
    
    func loadCachedPokemon() async {
        // No-op in mock - we don't need to actually load from cache
    }
    
    func cancelAllRequests() {
        // No-op in mock - we don't have any actual network requests to cancel
        print("🧪 MockPokemonListViewModel: cancelAllRequests called (no-op)")
    }
    
    private func filterPokemon(with query: String) {
        if query.isEmpty {
            // When search is empty, show all Pokemon
            filteredPokemon = pokemonList
        } else {
            // Filter Pokemon whose names contain the search query (case-insensitive)
            filteredPokemon = pokemonList.filter { 
                $0.name.lowercased().contains(query.lowercased())
            }
        }
    }
}


