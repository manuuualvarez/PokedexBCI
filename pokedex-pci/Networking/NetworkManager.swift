import Foundation

/// Network manager for handling Pokemon API requests
final class NetworkManager: NetworkManagerProtocol {
    private let apiService: PokemonAPIServiceProtocol
    
    init(_ baseURL: String = "https://pokeapi.co/api/v2") {
        self.apiService = PokemonAPIService(baseURL: baseURL)
    }
    
    // For dependency injection in tests
    init(apiService: PokemonAPIServiceProtocol) {
        self.apiService = apiService
    }
    
    func fetchPokemonList() async throws -> PokemonListResponse {
        do {
            return try await apiService.fetchPokemonList(limit: 151)
        } catch let error as NetworkError {
            print("❌ Network error fetching Pokemon list: \(error.userMessage)")
            throw error
        } catch {
            let networkError = NetworkError.mapError(error)
            print("❌ Error fetching Pokemon list: \(networkError.userMessage)")
            throw networkError
        }
    }
    
    func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        do {
            return try await apiService.fetchPokemonDetail(id: id)
        } catch let error as NetworkError {
            print("❌ Network error fetching Pokemon detail #\(id): \(error.userMessage)")
            throw error
        } catch {
            let networkError = NetworkError.mapError(error)
            print("❌ Error fetching Pokemon detail #\(id): \(networkError.userMessage)")
            throw networkError
        }
    }
    
    func cancelAllRequests() {
        apiService.cancelAllRequests()
    }
} 
