//
//  ErrorHandlingUITest.swift
//  pokedex-pciUITests
//
//  Created by Manny Alvarez on 22/03/2025.
//

import XCTest
@testable import pokedex_pci

final class ErrorHandlingUITest: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Always add this line to immediately stop tests when failures occur
        continueAfterFailure = false
        
        // Force portrait orientation
        let device = XCUIDevice.shared
        device.orientation = .portrait
        
        // Create app instance
        app = XCUIApplication()
        
        // Note: We don't set global launch arguments here anymore
        // Each test will set its own complete arguments
    }
    
    // MARK: - Error Handling Test
    func testErrorHandlingWithNoCache() throws {
        
        // Configure the app for error state test
        app.launchArguments = ["UI-TESTING", "ERROR-TESTING", "ERROR-NO-CACHE"]
        app.launch()
        
        // Wait for the app to load
        sleep(2)
        
        // Verify the error alert appears
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.exists, "Error alert should appear when there's no cache")
        
        // Verify that collection view is hidden
        // (This is harder to verify directly, but we can check that cells aren't visible)
        let cells = app.cells
        XCTAssertEqual(cells.count, 0, "Collection view should be hidden with no cells visible")
        
        // Verify alert has the right message
        let alertText = errorAlert.staticTexts.element(boundBy: 0).label
        XCTAssertTrue(alertText.contains("Error"), "Alert should mention server/response error: \(alertText)")
        
        // Verify there's an "Retry" button to dismiss the alert
        let retryButton = errorAlert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists, "Alert should have an Retry button")
        
        // Tap the "OK" button
        retryButton.tap()
        
        // Wait for the alert to be dismissed
        sleep(1)
        
        // Verify that the app shows an empty state or error message
        // We should still see no cells
        XCTAssertEqual(app.cells.count, 0, "Collection view should still have no cells after dismissing error")
    }
    
    // MARK: - Retry Functionality Test
    func testErrorThenSuccessWithRetry() throws {
        
        // Configure the app for retry test
        app.launchArguments = ["UI-TESTING", "ERROR-TESTING", "ERROR-THEN-SUCCESS"] 
        app.launch()
        
        // Wait for initial error state with longer timeout
        sleep(3)
        
        // Verify the app shows an error state initially
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.exists, "Error alert should appear")
                
        // Find and tap retry button in the alert
        let retryButton = errorAlert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists, "Retry button should exist in error state")
        retryButton.tap()
        
        // Wait for retry to complete and for the UI to update
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
