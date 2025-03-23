import Foundation

/// Protocol defining HTTP client capabilities
public protocol HTTPClientProtocol {
    /// Performs a data task with built-in retry capability
    /// - Parameters:
    ///   - request: The URLRequest to perform
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - retryDelay: Base delay between retries in seconds (default: 1.0)
    ///   - task: Task for cancellation support
    /// - Returns: Tuple containing Data and URLResponse
    func performRequest(_ request: URLRequest, 
                     maxRetries: Int,
                     retryDelay: TimeInterval) async throws -> (Data, URLResponse)
    
    /// Makes a GET request to the specified URL
    /// - Parameters:
    ///   - url: The URL to request
    ///   - maxRetries: Maximum number of retry attempts
    ///   - retryDelay: Base delay between retries in seconds
    /// - Returns: The Data returned from the request
    func get(from url: URL, 
             maxRetries: Int,
             retryDelay: TimeInterval) async throws -> Data
    
    /// Decodes data from a GET request to the specified URL
    /// - Parameters:
    ///   - url: The URL to request
    ///   - type: The type to decode into
    ///   - maxRetries: Maximum number of retry attempts
    ///   - retryDelay: Base delay between retries in seconds
    /// - Returns: The decoded value
    func get<T: Decodable>(from url: URL, 
                        as type: T.Type,
                        maxRetries: Int,
                        retryDelay: TimeInterval) async throws -> T
}

/// Protocol that matches URLSession's async data method
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Make standard URLSession conform to our protocol
extension URLSession: URLSessionProtocol {}

/// Default implementation of HTTPClient
public class HTTPClient: HTTPClientProtocol {
    
    // MARK: - Properties
    
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(session: URLSessionProtocol = URLSession.shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    // MARK: - Public methods
    
    public func performRequest(_ request: URLRequest, 
                            maxRetries: Int = 3,
                            retryDelay: TimeInterval = 1.0) async throws -> (Data, URLResponse) {
        
        var currentRetries = 0
        var lastError: Error?
        
        while currentRetries <= maxRetries {
            do {
                // Check if task was cancelled before making request
                if Task.isCancelled {
                    throw CancellationError()
                }
                
                let (data, response) = try await session.data(for: request)
                
                // Check if task was cancelled after receiving response
                if Task.isCancelled {
                    throw CancellationError()
                }
                
                // Handle HTTP errors
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown(description: "Not an HTTP response")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return (data, response)
                case 400...499:
                    // Client errors - typically not worth retrying
                    throw NetworkError.requestFailed(statusCode: httpResponse.statusCode)
                case 500...599:
                    // Server errors - might be worth retrying
                    throw NetworkError.serverError
                default:
                    throw NetworkError.unknown(description: "Unexpected status code: \(httpResponse.statusCode)")
                }
                
            } catch let error as NetworkError {
                lastError = error
                
                // Only retry if the error is retryable
                if error.isRetryable && currentRetries < maxRetries {
                    // Exponential backoff with jitter
                    let delay = calculateBackoff(attempt: currentRetries, baseDelay: retryDelay)
                    print("🔄 Request failed with error: \(error). Retrying in \(delay) seconds... (\(currentRetries+1)/\(maxRetries))")
                    
                    // Delay before retrying
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    currentRetries += 1
                    continue
                } else {
                    throw error
                }
            } catch {
                // For other errors (including CancellationError), don't retry
                if error is CancellationError {
                    throw error
                }
                
                // Map other errors to NetworkError
                let networkError = NetworkError.mapError(error)
                lastError = networkError
                
                if networkError.isRetryable && currentRetries < maxRetries {
                    let delay = calculateBackoff(attempt: currentRetries, baseDelay: retryDelay)
                    print("🔄 Request failed with error: \(networkError). Retrying in \(delay) seconds... (\(currentRetries+1)/\(maxRetries))")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    currentRetries += 1
                    continue
                } else {
                    throw networkError
                }
            }
        }
        
        // If we've exhausted retries
        throw lastError ?? NetworkError.unknown(description: "Request failed after \(maxRetries) retries")
    }
    
    public func get(from url: URL, 
                 maxRetries: Int = 3,
                 retryDelay: TimeInterval = 1.0) async throws -> Data {
        
        let request = URLRequest(url: url)
        let (data, _) = try await performRequest(request, maxRetries: maxRetries, retryDelay: retryDelay)
        
        return data
    }
    
    public func get<T: Decodable>(from url: URL, 
                               as type: T.Type,
                               maxRetries: Int = 3,
                               retryDelay: TimeInterval = 1.0) async throws -> T {
        
        let data = try await get(from: url, maxRetries: maxRetries, retryDelay: retryDelay)
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            throw NetworkError.decodingFailed(description: error.localizedDescription)
        }
    }
    
    // MARK: - Private methods
    
    /// Calculate backoff time with exponential delay and jitter
    private func calculateBackoff(attempt: Int, baseDelay: TimeInterval) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0.0...0.3) * exponentialDelay
        return exponentialDelay + jitter
    }
} 