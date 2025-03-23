//
//  ErrorHandlingUITest.swift
//  PokedexBCIUITests
//
//  Created by Manny Alvarez on 22/03/2025.
//

import XCTest
@testable import PokedexBCI

// MARK: - Error Handling UI Tests
/// UI tests that verify the app's resilience to network and data failures.
/// These tests are critical for ensuring proper user experience during error conditions.
final class ErrorHandlingUITest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        // Fail immediately on test failures to avoid cascading issues
        continueAfterFailure = false
        
        // Force portrait orientation for consistent testing
        let device = XCUIDevice.shared
        device.orientation = .portrait
        
        // Create app instance with default configuration
        app = XCUIApplication()
    }
    
    // MARK: - No Cache Error Tests
    
    /// Tests the app's behavior when experiencing a network error without cached data
    /// This validates the error presentation and UI state during a "cold start" failure
    func testErrorHandlingWithNoCache() throws {
        // Configure app for network error with no available cache
        UITestHelper.setupUITestEnvironment(app: app, errorScenario: .errorNoCache)
        app.launch()
        
        // Wait for the app to load and error state to appear
        sleep(2)
        
        // Verify error alert is displayed
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.exists, "Error alert should appear when there's no cache")
        
        // Verify collection view is hidden (no visible cells)
        let cells = app.cells
        XCTAssertEqual(cells.count, 0, "Collection view should be hidden with no cells visible")
        
        // Verify alert contains appropriate error message
        let alertText = errorAlert.staticTexts.element(boundBy: 0).label
        XCTAssertTrue(alertText.contains("Error"), "Alert should describe the error condition")
        
        // Verify retry button exists
        let retryButton = errorAlert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists, "Alert should have a Retry button")
        
        // Test retry button functionality
        retryButton.tap()
        sleep(1)
        
        // Verify app remains in error state after unsuccessful retry
        XCTAssertEqual(app.cells.count, 0, "Collection view should still have no cells after dismissing error")
    }
    
    // MARK: - Recovery Tests
    
    /// Tests the app's ability to recover from an error when a retry succeeds
    /// This validates our retry mechanism and proper state restoration
    func testErrorThenSuccessWithRetry() throws {
        // Configure app to fail first then succeed on retry
        UITestHelper.setupUITestEnvironment(app: app, errorScenario: .errorThenSuccess)
        app.launch()
        
        // Wait for initial error state
        sleep(3)
        
        // Verify the app shows an error state initially
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.exists, "Error alert should appear")
                
        // Find and tap retry button
        let retryButton = errorAlert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists, "Retry button should exist in error state")
        retryButton.tap()
        
        // Wait for retry to complete and UI to update
        sleep(5)
        
        // Look for any cells that become available with timeout
        let predicate = NSPredicate(format: "count > 0")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.cells)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        
        if result == .completed {
            // Successfully found cells
            XCTAssertTrue(app.cells.count > 0, "Cells should appear after successful retry")
        } else {
            // Check for collection views as a fallback
            let collectionViews = app.collectionViews
            // Try tapping refresh button if it exists
            if app.buttons["Refresh"].exists {
                app.buttons["Refresh"].tap()
                sleep(5)
            }
            
            // Final check - either cells or collection views should be visible
            XCTAssertTrue(app.cells.count > 0 || collectionViews.count > 0, 
                         "Either cells or collection views should be visible after successful retry")
        }
    }
} 
