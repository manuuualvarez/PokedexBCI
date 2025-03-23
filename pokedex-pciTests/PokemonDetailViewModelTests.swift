import XCTest
@testable import pokedex_pci

// MARK: - Test Suite

/// Test suite for validating the PokemonDetailViewModel implementation
final class PokemonDetailViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    // Test view model instances
    private var grassViewModel: PokemonDetailViewModel!
    private var fireViewModel: PokemonDetailViewModel!
    private var waterViewModel: PokemonDetailViewModel!
    private var emptyViewModel: PokemonDetailViewModel!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create Pokemon instances for testing
        let grassPokemon = createMockPokemon(
            id: 1,
            name: "bulbasaur",
            types: [
                createPokemonTypes(name: "grass", slot: 1)
            ],
            abilities: [
                createAbility(name: "overgrow", isHidden: false, slot: 1),
                createAbility(name: "chlorophyll", isHidden: true, slot: 2)
            ],
            moves: [
                createMove(name: "razor-leaf"),
                createMove(name: "vine-whip"),
                createMove(name: "solar-beam"),
                createMove(name: "growth"),
                createMove(name: "tackle"),
                createMove(name: "seed-bomb")
            ],
            stats: [
                createStat(name: "hp", baseStat: 45, effort: 0),
                createStat(name: "attack", baseStat: 49, effort: 0),
                createStat(name: "defense", baseStat: 49, effort: 0),
                createStat(name: "special-attack", baseStat: 65, effort: 1),
                createStat(name: "special-defense", baseStat: 65, effort: 0),
                createStat(name: "speed", baseStat: 45, effort: 0)
            ]
        )
        
        let firePokemon = createMockPokemon(
            id: 4,
            name: "charmander",
            types: [
                createPokemonTypes(name: "fire", slot: 1)
            ],
            abilities: [
                createAbility(name: "blaze", isHidden: false, slot: 1),
                createAbility(name: "solar-power", isHidden: true, slot: 2)
            ],
            moves: [
                createMove(name: "ember"),
                createMove(name: "flamethrower")
            ],
            stats: [
                createStat(name: "hp", baseStat: 39, effort: 0),
                createStat(name: "attack", baseStat: 52, effort: 0),
                createStat(name: "defense", baseStat: 43, effort: 0),
                createStat(name: "special-attack", baseStat: 60, effort: 0),
                createStat(name: "special-defense", baseStat: 50, effort: 0),
                createStat(name: "speed", baseStat: 65, effort: 1)
            ]
        )
        
        let waterPokemon = createMockPokemon(
            id: 7,
            name: "squirtle",
            types: [
                createPokemonTypes(name: "water", slot: 1),
                createPokemonTypes(name: "ice", slot: 2)
            ],
            abilities: [
                createAbility(name: "torrent", isHidden: false, slot: 1)
            ],
            moves: [
                createMove(name: "water-gun")
            ],
            stats: [
                createStat(name: "hp", baseStat: 44, effort: 0),
                createStat(name: "attack", baseStat: 48, effort: 0),
                createStat(name: "defense", baseStat: 65, effort: 1),
                createStat(name: "special-attack", baseStat: 50, effort: 0),
                createStat(name: "special-defense", baseStat: 64, effort: 0),
                createStat(name: "speed", baseStat: 43, effort: 0)
            ]
        )
        
        // Empty Pokemon for edge case testing
        let emptyPokemon = createMockPokemon(
            id: 999,
            name: "missingno",
            types: [],
            abilities: [],
            moves: [],
            stats: []
        )
        
        // Create view models using concrete implementation
        grassViewModel = PokemonDetailViewModel(pokemon: grassPokemon)
        fireViewModel = PokemonDetailViewModel(pokemon: firePokemon)
        waterViewModel = PokemonDetailViewModel(pokemon: waterPokemon)
        emptyViewModel = PokemonDetailViewModel(pokemon: emptyPokemon)
    }
    
    override func tearDown() {
        // Clean up test data
        grassViewModel = nil
        fireViewModel = nil
        waterViewModel = nil
        emptyViewModel = nil
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockPokemon(id: Int, name: String, types: [PokemonTypes], abilities: [Ability], moves: [Move], stats: [Stat]) -> Pokemon {
        return Pokemon(
            id: id,
            name: name,
            types: types,
            sprites: Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"),
            abilities: abilities,
            moves: moves,
            stats: stats
        )
    }
    
    private func createPokemonTypes(name: String, slot: Int) -> PokemonTypes {
        return PokemonTypes(
            slot: slot,
            type: PokemonType(name: name)
        )
    }
    
    private func createAbility(name: String, isHidden: Bool, slot: Int) -> Ability {
        return Ability(ability: Ability.AbilityDetail(name: name), isHidden: isHidden, slot: slot)
    }
    
    private func createMove(name: String) -> Move {
        return Move(move: MoveDetail(name: name))
    }
    
    private func createStat(name: String, baseStat: Int, effort: Int) -> Stat {
        return Stat(baseStat: baseStat, effort: effort, stat: StatDetail(name: name, url: ""))
    }
    
    // MARK: - Basic Property Tests
    
    func testBasicProperties() {
        // Test ID property
        XCTAssertEqual(grassViewModel.id, 1)
        XCTAssertEqual(fireViewModel.id, 4)
        XCTAssertEqual(waterViewModel.id, 7)
        XCTAssertEqual(emptyViewModel.id, 999)
        
        // Test name property (should be capitalized)
        XCTAssertEqual(grassViewModel.name, "Bulbasaur")
        XCTAssertEqual(fireViewModel.name, "Charmander")
        XCTAssertEqual(waterViewModel.name, "Squirtle")
        XCTAssertEqual(emptyViewModel.name, "Missingno")
        
        // Test image URL property
        XCTAssertEqual(grassViewModel.imageURL?.absoluteString, "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")
        XCTAssertEqual(fireViewModel.imageURL?.absoluteString, "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png")
        XCTAssertEqual(waterViewModel.imageURL?.absoluteString, "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png")
        XCTAssertEqual(emptyViewModel.imageURL?.absoluteString, "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/999.png")
    }
    
    // MARK: - Type Tests
    
    func testTypeProperties() {
        // Test type names array
        XCTAssertEqual(grassViewModel.typeNames, ["Grass"])
        XCTAssertEqual(fireViewModel.typeNames, ["Fire"])
        XCTAssertEqual(waterViewModel.typeNames, ["Water", "Ice"])
        XCTAssertEqual(emptyViewModel.typeNames, [])
        
        // Test type-based color assignment
        XCTAssertEqual(grassViewModel.colorName, .green)
        XCTAssertEqual(fireViewModel.colorName, .red)
        XCTAssertEqual(waterViewModel.colorName, .blue)
    }
    
    // MARK: - Ability Tests
    
    func testAbilityProperties() {
        // Test abilities array property
        XCTAssertEqual(grassViewModel.abilitiesArray, ["Overgrow", "Chlorophyll (Hidden)"])
        XCTAssertEqual(fireViewModel.abilitiesArray, ["Blaze", "Solar-Power (Hidden)"])
        XCTAssertEqual(waterViewModel.abilitiesArray, ["Torrent"])
        XCTAssertEqual(emptyViewModel.abilitiesArray, [])
    }
    
    // MARK: - Move Tests
    
    func testMoveProperties() {
        // Test moves array property (should only include first 5)
        XCTAssertEqual(grassViewModel.movesArray.count, 5)
        XCTAssertEqual(grassViewModel.movesArray[0], "Razor-Leaf")
        XCTAssertEqual(grassViewModel.movesArray[4], "Tackle")
        XCTAssertEqual(fireViewModel.movesArray, ["Ember", "Flamethrower"])
        XCTAssertEqual(waterViewModel.movesArray, ["Water-Gun"])
        XCTAssertEqual(emptyViewModel.movesArray, [])
    }
    
    // MARK: - Stat Tests
    
    func testStatProperties() {
        // Test real stats parsing
        let grassStats = grassViewModel.stats
        XCTAssertEqual(grassStats.count, 6, "Should have 6 stats for Bulbasaur")
        
        // Verify specific stats by name and value
        let hpStat = grassStats.first { $0.name == "Hp" }
        XCTAssertNotNil(hpStat, "HP stat should exist")
        XCTAssertEqual(hpStat?.value, 45)
        
        let specialAttackStat = grassStats.first { $0.name == "Special-Attack" }
        XCTAssertNotNil(specialAttackStat, "Special Attack stat should exist")
        XCTAssertEqual(specialAttackStat?.value, 65)
        
        // Test that fire Pokemon stats are correct
        let fireStats = fireViewModel.stats
        XCTAssertEqual(fireStats.count, 6, "Should have 6 stats for Charmander")
        
        // Verify specific speed stat
        let speedStat = fireStats.first { $0.name.lowercased() == "speed" }
        XCTAssertNotNil(speedStat, "Speed stat should exist")
        XCTAssertEqual(speedStat?.value, 65)
        
        // Test that water Pokemon stats are correct
        let waterStats = waterViewModel.stats
        XCTAssertEqual(waterStats.count, 6, "Should have 6 stats for Squirtle")
        
        // Verify defense stat is highest for water type
        let defenseStat = waterStats.first { $0.name.lowercased() == "defense" }
        XCTAssertNotNil(defenseStat, "Defense stat should exist")
        XCTAssertEqual(defenseStat?.value, 65)
        
        // Test empty stats when no stats are provided
        let emptyStats = emptyViewModel.stats
        XCTAssertTrue(emptyStats.isEmpty, "Stats should be empty when Pokemon has no stats")
    }
    
    // MARK: - Edge Case Tests
    
    func testEdgeCaseHandling() {
        // Test with invalid/empty data
        let invalidPokemon = createMockPokemon(
            id: -1,
            name: "",
            types: [],
            abilities: [],
            moves: [],
            stats: []
        )
        let invalidViewModel = PokemonDetailViewModel(pokemon: invalidPokemon)
        
        // Name should be capitalized even when empty
        XCTAssertEqual(invalidViewModel.name, "")
        
        // Types should be empty array but not nil
        XCTAssertEqual(invalidViewModel.typeNames, [])
        
        // Stats should match the input - if no stats are provided, we don't show stats
        XCTAssertTrue(invalidViewModel.stats.isEmpty, "Stats should be empty when Pokemon has no stats")
    }
} 
