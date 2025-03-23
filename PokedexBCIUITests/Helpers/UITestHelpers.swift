//
//  UITestHelpers.swift
//  pokedex-pciUITests
//
//  Created by Manny Alvarez on 23/03/2025.
//

import Foundation
import XCTest

/// Helper class for setting up UI test environment
class UITestHelper {
    /// Error scenarios for UI tests
    enum ErrorScenario {
        case offlineWithCache
        case errorNoCache
        case errorThenSuccess
    }
    
    /// Set up the app for UI testing with the selected environment
    static func setupUITestEnvironment(app: XCUIApplication, errorScenario: ErrorScenario? = nil) {
        // Add the UI testing flag
        app.launchArguments.append("UI-TESTING")
        
        // Configure behavior to be more resilient in UI tests
        app.launchArguments.append("UI-TESTING-SLOWER-ANIMATIONS")
        app.launchArguments.append("UI-TESTING-WAIT-LONGER")
        
        if let scenario = errorScenario {
            // Add error testing flag
            app.launchArguments.append("ERROR-TESTING")
            
            // Add specific scenario flag
            switch scenario {
            case .offlineWithCache:
                app.launchArguments.append("OFFLINE-WITH-CACHE")
            case .errorNoCache:
                app.launchArguments.append("ERROR-NO-CACHE")
            case .errorThenSuccess:
                app.launchArguments.append("ERROR-THEN-SUCCESS")
            }
        }
    }
    
    /// Helper method for waiting until an element exists with timeout
    static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Helper method to repeatedly attempt an operation until success or timeout
    static func retry(attempts: Int = 3, delay: TimeInterval = 1, operation: @escaping () -> Bool) -> Bool {
        for attempt in 1...attempts {
            if operation() {
                return true
            }
            
            if attempt < attempts {
                Thread.sleep(forTimeInterval: delay)
            }
        }
        return false
    }
} 