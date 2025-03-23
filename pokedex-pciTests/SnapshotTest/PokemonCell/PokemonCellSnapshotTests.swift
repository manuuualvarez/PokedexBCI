import XCTest
import SnapshotTesting
import Kingfisher
@testable import pokedex_pci

class PokemonCellSnapshotTests: XCTestCase {
    
    let recordMode = false
    
    // Define a constant delay to ensure UI elements are fully loaded
    let renderDelay: TimeInterval = 0.5
    
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
    func testPokemonCell() {
        // Create a simple mock Pokemon for each major type
        let pokemons = [
            createMockPokemon(name: "Bulbasaur", type: "grass"),
            createMockPokemon(name: "Charmander", type: "fire"),
            createMockPokemon(name: "Squirtle", type: "water"),
            createMockPokemon(name: "Pikachu", type: "electric")
        ]
        
        // Test cell dimensions for different device configurations
        let frameSizes: [(String, CGRect)] = [
            ("iPhone-Portrait", CGRect(x: 0, y: 0, width: 375, height: 225)), // iPhone portrait (0.6 height ratio)
            ("iPhone-Landscape", CGRect(x: 0, y: 0, width: 300, height: 180)), // iPhone landscape (0.6 height ratio)
            ("iPad", CGRect(x: 0, y: 0, width: 250, height: 175)) // iPad (0.7 height ratio)
        ]
        
        // Test each Pokemon with each frame size
        for pokemon in pokemons {
            for (configName, frame) in frameSizes {
                print("Testing cell for \(pokemon.name) with \(configName) configuration...")
                
                // Create the cell with the specified size
                let cell = PokemonCell(frame: frame)
                
                // Configure the cell
                cell.configure(with: pokemon)
                
                // Force light mode for consistent snapshots
                cell.overrideUserInterfaceStyle = .light
                
                // Apply light mode recursively to all subviews
                forceAppearanceRecursively(on: cell, style: .light)
                
                // Replace the async image loading with our test image
                replaceImages(in: cell, pokemonName: pokemon.name)
                
                // Wait for cell to fully load and layout
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                
                // Use expectation to ensure UI has time to fully render
                let expectation = XCTestExpectation(description: "Wait for UI to render")
                DispatchQueue.main.asyncAfter(deadline: .now() + renderDelay) {
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: renderDelay + 1.0)
                
                // Take a snapshot of the cell directly with a clearer naming convention
                assertSnapshot(
                    of: cell, 
                    as: .image, 
                    named: "\(configName)_\(pokemon.name.lowercased())",
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
    
    // Helper method to create a simple mock Pokemon
    private func createMockPokemon(name: String, type: String) -> Pokemon {
        // Extract ID from common Pokemon names
        let id: Int
        switch name.lowercased() {
        case "bulbasaur": id = 1
        case "charmander": id = 4
        case "squirtle": id = 7
        case "pikachu": id = 25
        default: id = 1
        }
        
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
}

