//
//  AppDelegate.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import UIKit
import SwiftData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var modelContainer: ModelContainer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MARK: - SwiftData Cache Setup
        /// SwiftData is used for caching layer with the following configuration:
        /// 1. Schema: Defines the data model (PokemonBasicCache) for storing Pokemon data
        /// 2. Storage: Data is persisted to disk (not in-memory only)
        /// 3. Saving: Allows writing new cache entries
        ///
        /// Cache Strategy:
        /// - Cache Duration: 15 minutes
        /// - Storage Location: Device's persistent storage
        /// - Invalidation: Automatic after expiration
        do {
            let schema = Schema([PokemonBasicCache.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("📱 SwiftData store initialized successfully")
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

