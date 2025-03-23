import Foundation
import Combine

/// Protocol defining the interface for Pokémon API operations
public protocol PokemonAPIServiceProtocol {
    /// Fetches a list of Pokémon with pagination
    /// - Parameter limit: Maximum number of Pokémon to fetch (default: 151)
    /// - Returns: PokemonListResponse containing Pokémon data
    func fetchPokemonList(limit: Int) async throws -> PokemonListResponse
    
    /// Fetches detailed information about a specific Pokémon
    /// - Parameter id: The ID of the Pokémon to fetch
    /// - Returns: Pokemon model with complete details
    func fetchPokemonDetail(id: Int) async throws -> Pokemon
    
    /// Cancels all ongoing requests
    func cancelAllRequests()
}

// Define protocols for type safety
public protocol TaskCancellable {
    func cancel()
}

// Make Task conform to our TaskCancellable protocol
extension Task: TaskCancellable {}

/// Implementation of the Pokémon API service using HTTPClient
final class PokemonAPIService: PokemonAPIServiceProtocol {
    
    // MARK: - Properties
    
    private let httpClient: HTTPClientProtocol
    private let baseURL: String
    private var activeTasks: [UUID: Any] = [:]
    private let taskLock = NSLock()
    
    // MARK: - Initializers
    
    init(httpClient: HTTPClientProtocol = HTTPClient(), baseURL: String = "https://pokeapi.co/api/v2") {
        self.httpClient = httpClient
        self.baseURL = baseURL
    }
    
    // MARK: - Public methods
    
    public func fetchPokemonList(limit: Int = 151) async throws -> PokemonListResponse {
        guard let url = URL(string: "\(baseURL)/pokemon?limit=\(limit)") else {
            throw NetworkError.invalidURL
        }
        
        let taskID = UUID()
        let task = Task<PokemonListResponse, Error> {
            return try await httpClient.get(from: url, as: PokemonListResponse.self, maxRetries: 2, retryDelay: 1.0)
        }
        
        registerTask(task, id: taskID)
        
        do {
            let result = try await task.value
            removeTask(id: taskID)
            return result
        } catch {
            removeTask(id: taskID)
            throw error
        }
    }
    
    public func fetchPokemonDetail(id: Int) async throws -> Pokemon {
        guard let url = URL(string: "\(baseURL)/pokemon/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        let taskID = UUID()
        let task = Task<Pokemon, Error> {
            return try await httpClient.get(from: url, as: Pokemon.self, maxRetries: 3, retryDelay: 1.0)
        }
        
        registerTask(task, id: taskID)
        
        do {
            let result = try await task.value
            removeTask(id: taskID)
            return result
        } catch {
            removeTask(id: taskID)
            throw error
        }
    }
    
    public func cancelAllRequests() {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        for (_, taskAny) in activeTasks {
            if let task = taskAny as? TaskCancellable {
                task.cancel()
            }
        }
        
        activeTasks.removeAll()
        print("🚫 All API requests cancelled")
    }
    
    // MARK: - Private methods
    
    private func registerTask<T>(_ task: Task<T, Error>, id: UUID) {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        activeTasks[id] = task
    }
    
    private func removeTask(id: UUID) {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        activeTasks.removeValue(forKey: id)
    }
} 
