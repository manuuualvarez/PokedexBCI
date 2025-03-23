//
//  DeviceConfiguration.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 23/03/2025.
//
import XCTest
import SnapshotTesting

// Extension to add multiple iPhone device configurations
extension ViewImageConfig {
    static let iPhone14 = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 390, height: 844),
        traits: UITraitCollection(mutations: { mutableTraits in
            mutableTraits.userInterfaceStyle = .light
            mutableTraits.horizontalSizeClass = .compact
            mutableTraits.verticalSizeClass = .regular
            mutableTraits.userInterfaceIdiom = .phone
        })
    )
    
    static let iPhone15 = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(mutations: { mutableTraits in
            mutableTraits.userInterfaceStyle = .light
            mutableTraits.horizontalSizeClass = .compact
            mutableTraits.verticalSizeClass = .regular
            mutableTraits.userInterfaceIdiom = .phone
        })
    )
    
    static let iPhone16 = ViewImageConfig(
        safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 393, height: 852),
        traits: UITraitCollection(mutations: { mutableTraits in
            mutableTraits.userInterfaceStyle = .light
            mutableTraits.horizontalSizeClass = .compact
            mutableTraits.verticalSizeClass = .regular
            mutableTraits.userInterfaceIdiom = .phone
        })
    )
}
