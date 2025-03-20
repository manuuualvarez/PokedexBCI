//
//  NetworkingManager.swift
//  pokedex-pci
//
//  Created by Manny Alvarez on 20/03/2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(Int)
    case unknown
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://pokeapi.co/api/v2"
    
    private init() {}
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        let endpoint = "\(baseURL)/pokemon?limit=151"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(PokemonListResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        let endpoint = "\(baseURL)/pokemon/\(id)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(Pokemon.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
