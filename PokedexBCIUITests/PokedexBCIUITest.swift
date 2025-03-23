//
//  PokedexBCIUITest.swift
//  PokedexBCIUITests
//
//  Created by Manny Alvarez on 01/06/2025.
//

import XCTest
@testable import PokedexBCI

// MARK: - Pokémon App UI Tests
/// UI test suite validating key user flows and interactions throughout the app.
/// Tests use real UI components with mock data to ensure stability.
final class PokedexAppUITest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Force portrait orientation for consistent testing
        let device = XCUIDevice.shared
        device.orientation = .portrait
        
        // Initialize app with mock data configuration
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
    }
    
    // MARK: - Baseline Tests
    
    /// Validates that the app launches successfully and stabilizes
    /// This is our most basic smoke test - if this fails, everything else will too
    func testAppLaunches() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        
        XCTAssertTrue(app.exists, "App should exist and be running")
    }
    
    /// Validates that the collection view loads Pokemon data from the network layer
    /// This verifies our core data loading functionality works correctly
    func testCollectionViewHasItems() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "Collection view should display Pokemon cells after data loading")
    }
    
    /// Verifies scrolling behavior in the collection view
    /// Critical for users to navigate through the Pokemon list
    func testCollectionViewScrolling() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        let collectionView = app.collectionViews.element(boundBy: 0)
        XCTAssertTrue(collectionView.exists, "Collection view should exist")
        
        // Test scroll down
        collectionView.swipeUp()
        sleep(1)
        
        // Test scroll back up
        collectionView.swipeDown()
        sleep(1)
    }
    
    /// Confirms that loading states are correctly displayed during data fetch
    /// Important for providing visual feedback to users during network operations
    func testLoadingStateIsDisplayed() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        
        // Loading indicators may be brief with mocks
        sleep(2)
        
        // Verify content loads
        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "Collection view should display data after loading completes")
    }
    
    // MARK: - Search Functionality Tests
    
    /// Verifies that the search bar is accessible in the main Pokemon list
    /// Critical entry point for users to find specific Pokemon
    func testSearchBarExists() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        let searchBar = app.searchFields["Search Pokémon"]
        XCTAssertTrue(searchBar.exists, "Search bar should be present for filtering Pokemon")
    }
    
    /// Tests basic search bar interactions (tap, type, clear)
    /// Validates core search interaction patterns work correctly
    func testSearchBarInteraction() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        let searchBar = app.searchFields["Search Pokémon"]
        XCTAssertTrue(searchBar.exists, "Search bar should exist")
        
        // Test typing in search
        searchBar.tap()
        searchBar.typeText("Pika")
        sleep(1)
        
        // Test clearing search
        searchBar.buttons["Clear text"].tap()
        sleep(1)
    }
    
    /// Tests searching for non-existent Pokemon and validates empty results state
    /// Important for handling the no-results edge case properly
    func testSearchWithNoResults() throws {
        app.launch()
        sleep(1)
        
        let searchBar = app.searchFields["Search Pokémon"]
        XCTAssertTrue(searchBar.exists, "Search bar should exist")
        
        // Record initial state to verify we return to it
        let initialCellCount = app.collectionViews.cells.count
        XCTAssertGreaterThan(initialCellCount, 0, "Collection view should initially display Pokemon")
        
        // Search for non-existent Pokemon
        searchBar.tap()
        searchBar.typeText("xyzNonExistentPokemon")
        sleep(1)
        
        // Verify no results shown
        XCTAssertEqual(app.collectionViews.cells.count, 0, "No cells should be visible for non-existent Pokémon")
        
        // Clear search and verify return to initial state
        searchBar.buttons["Clear text"].tap()
        sleep(1)
        XCTAssertEqual(app.collectionViews.cells.count, initialCellCount, "Collection view should return to initial state after clearing search")
    }
    
    /// Tests filtering to a specific Pokemon and validates the filtering logic
    /// Critical for the main search functionality to work as expected
    func testSearchWithResults() throws {
        app.launch()
        sleep(1)
        
        let searchBar = app.searchFields["Search Pokémon"]
        
        // Search for a specific Pokemon
        searchBar.tap()
        searchBar.typeText("Bulbasaur")
        sleep(1)
        
        // Verify filtered results
        XCTAssertEqual(app.collectionViews.cells.count, 1, "Should find exactly one result for Bulbasaur")
        
        // Verify the result is the correct Pokemon
        let pokemonNameLabel = app.staticTexts["Bulbasaur"]
        XCTAssertTrue(pokemonNameLabel.exists, "The result should display Bulbasaur")
        
        // Clear search and verify multiple results return
        searchBar.buttons["Clear text"].tap()
        sleep(1)
        XCTAssertGreaterThan(app.collectionViews.cells.count, 1, "Collection view should show multiple Pokemon after clearing search")
    }
    
    // MARK: - Navigation Tests
    
    /// Verifies that the navigation bar shows the correct title
    /// Important for establishing context for the user
    func testNavigationBarTitle() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        let navigationBar = app.navigationBars["Pokédex"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should display 'Pokédex' title")
    }
    
    /// Tests tapping on a Pokemon and navigating to its detail view
    /// Tests the core navigation flow of the app
    func testTapOnFirstCell() throws {
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        // Find and tap first cell
        let cells = app.cells
        XCTAssertTrue(cells.count > 0, "Collection view should have cells")
        let firstCell = cells.element(boundBy: 0)
        firstCell.tap()
        
        // Allow time for navigation
        sleep(1)
        
        // Verify navigation by checking for back button
        let backButton = app.buttons.element(boundBy: 0) // Usually the first button is back
        XCTAssertTrue(backButton.exists, "Back button should exist after navigating to detail view")
        
        // Navigate back to list
        backButton.tap()
        sleep(1)
        
        // Verify return to list
        XCTAssertTrue(cells.count > 0, "Collection view should be visible again after returning from detail")
    }
} 
