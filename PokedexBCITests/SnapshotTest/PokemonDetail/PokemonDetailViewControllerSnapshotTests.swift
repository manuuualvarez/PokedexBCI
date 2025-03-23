import XCTest
import SnapshotTesting
@testable import PokedexBCI

class PokemonDetailViewControllerSnapshotTests: XCTestCase {
    
    let recordMode = false
    // Define a constant delay to ensure UI elements are fully loaded
    let renderDelay: TimeInterval = 1.0
    override func setUp() {
        super.setUp()
        // Force light mode at the application level
        UIView.appearance().overrideUserInterfaceStyle = .light
    }
    
    override func tearDown() {
        // Reset global UI appearance changes
        UIView.appearance().overrideUserInterfaceStyle = .unspecified
        super.tearDown()
    }
    
    @MainActor
    func testPokemonDetailViewController() {
        // Test with different Pokemon types
        let pokemonNames = ["Bulbasaur", "Charmander", "Squirtle", "Pikachu"]
        
        for pokemonName in pokemonNames {
            // Create a detailed mock Pokemon for the view model
            let pokemon = createDetailedMockPokemon(name: pokemonName)
            // Create a dedicated test container view controller to isolate styling
            let testContainer = UIViewController()
            testContainer.view.backgroundColor = .white
            testContainer.overrideUserInterfaceStyle = .light
            // Create the view model and controller
            let viewModel = PokemonDetailViewModel(pokemon: pokemon)
            let viewController = PokemonDetailViewController(viewModel: viewModel)
            // Force light mode at all levels
            testContainer.addChild(viewController)
            testContainer.view.addSubview(viewController.view)
            viewController.view.frame = testContainer.view.bounds
            viewController.didMove(toParent: testContainer)
            // Explicitly force light mode on the view controller and all its subviews
            forceAppearanceRecursively(on: viewController.view, style: .light)
            // Wait for view to fully load and layout
            viewController.loadViewIfNeeded()
            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()
            viewController.view.layoutIfNeeded()
            
            replaceImages(in: viewController.view, pokemonName: pokemonName)
            
            // Use expectation to ensure UI has time to fully render
            let expectation = XCTestExpectation(description: "Wait for UI to render")
            DispatchQueue.main.asyncAfter(deadline: .now() + renderDelay) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: renderDelay + 1.0)
            
            // Take a snapshot with consistent size - using iPhone 16 dimensions
            let size = CGSize(width: 390, height: 844) 
            
            // Remove any existing images that might interfere
            if let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] {
                print("Running on simulator: \(simulatorName)")
            }
            
            assertSnapshot(
                of: viewController,
                as: .image(size: size),
                named: pokemonName.lowercased(),
                record: recordMode
            )
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
    
    // Helper method to recursively find and replace images in a view hierarchy
    @MainActor
    private func replaceImages(in view: UIView, pokemonName: String) {
        // If this is an image view, set our test image
        if let imageView = view as? UIImageView {
            // Stop any ongoing Kingfisher downloads
            imageView.kf.cancelDownloadTask()
            imageView.setTestImage(for: pokemonName)
            imageView.contentMode = .scaleAspectFit
            
            // Mark as needing layout to ensure image is displayed
            imageView.setNeedsDisplay()
            imageView.setNeedsLayout()
        }
        
        // Recursively check all subviews
        for subview in view.subviews {
            replaceImages(in: subview, pokemonName: pokemonName)
        }
    }
    
    // Helper method to create a detailed mock Pokemon with all necessary fields
    private func createDetailedMockPokemon(name: String) -> Pokemon {
        // Extract ID and type from common Pokemon names
        let id: Int
        let type: String
        
        switch name.lowercased() {
        case "bulbasaur":
            id = 1
            type = "grass"
        case "charmander":
            id = 4
            type = "fire"
        case "squirtle":
            id = 7
            type = "water"
        case "pikachu":
            id = 25
            type = "electric"
        default:
            id = 1
            type = "normal"
        }
        
        // Create detailed stat array
        let stats = [
            Stat(baseStat: 45, effort: 0, stat: StatDetail(name: "hp", url: "")),
            Stat(baseStat: 49, effort: 0, stat: StatDetail(name: "attack", url: "")),
            Stat(baseStat: 49, effort: 0, stat: StatDetail(name: "defense", url: "")),
            Stat(baseStat: 65, effort: 1, stat: StatDetail(name: "special-attack", url: "")),
            Stat(baseStat: 65, effort: 0, stat: StatDetail(name: "special-defense", url: "")),
            Stat(baseStat: 45, effort: 0, stat: StatDetail(name: "speed", url: ""))
        ]
        
        // Create abilities
        let abilities = [
            Ability(
                ability: Ability.AbilityDetail(name: "Power"),
                isHidden: false,
                slot: 1
            ),
            Ability(
                ability: Ability.AbilityDetail(name: "Secret Power"),
                isHidden: true,
                slot: 2
            )
        ]
        
        // Create moves
        let moves = [
            Move(move: MoveDetail(name: "Move 1")),
            Move(move: MoveDetail(name: "Move 2")),
            Move(move: MoveDetail(name: "Move 3")),
            Move(move: MoveDetail(name: "Move 4")),
            Move(move: MoveDetail(name: "Move 5"))
        ]
        
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
            abilities: abilities,
            moves: moves,
            stats: stats
        )
    }
}

