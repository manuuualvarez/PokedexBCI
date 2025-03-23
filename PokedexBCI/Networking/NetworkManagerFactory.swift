//
//  NetworkManagerFactory.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 22/03/2025.
//
import Foundation

/// Environment for network manager creation
public enum NetworkEnvironment {
    case production
    case uiTest
}

/// Protocol for creating network managers
public protocol NetworkManagerFactoryProtocol {
    func createNetworkManager(for environment: NetworkEnvironment) -> NetworkManagerProtocol
}

/// Default implementation of the network manager factory
class DefaultNetworkManagerFactory: NetworkManagerFactoryProtocol {
    func createNetworkManager(for environment: NetworkEnvironment) -> NetworkManagerProtocol {
        // Check for UI testing mode with error scenarios
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("UI-TESTING") {
            if processInfo.arguments.contains("ERROR-TESTING") {
                if processInfo.arguments.contains("OFFLINE-WITH-CACHE") {
                    return TestNetworkManager.createWithErrorScenario(scenario: .offlineWithCache)
                } else if processInfo.arguments.contains("ERROR-NO-CACHE") {
                    return TestNetworkManager.createWithErrorScenario(scenario: .errorNoCache)
                } else if processInfo.arguments.contains("ERROR-THEN-SUCCESS") {
                    return TestNetworkManager.createWithErrorScenario(scenario: .errorThenSuccess)
                }
            }
            return TestNetworkManager()
        }
        
        // Default to production environment
        switch environment {
        case .production:
            return NetworkManager()
        case .uiTest:
            return TestNetworkManager()
        }
    }
}
