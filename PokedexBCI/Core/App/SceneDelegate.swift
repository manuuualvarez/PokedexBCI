//
//  SceneDelegate.swift
//  PokedexBCI
//
//  Created by Manny Alvarez on 20/03/2025.
//

import UIKit

/// SceneDelegate handles the setup and lifecycle of the app's window and root view controller
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Properties
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    // MARK: - Scene Lifecycle
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
    
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Configure navigation controller
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .white
        
        // Setup navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemRed
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        
        // Initialize coordinator
        Task { @MainActor in
            do {
                coordinator = try AppCoordinator(navigationController: navigationController)
                coordinator?.start()
                
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
            } catch {
                print("Failed to initialize AppCoordinator: \(error)")
            }
        }
    }
}
