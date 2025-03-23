import Foundation

/// Network layer specific errors
public enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(description: String)
    case noData
    case noInternet
    case timeout
    case serverError
    case unknown(description: String)
    
    /// User-facing error message
    public var userMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please contact technical support."
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode). Please try again later."
        case .decodingFailed:
            return "Could not process server response."
        case .noData:
            return "No data received from server."
        case .noInternet:
            return "No internet connection. Please check your connection and try again."
        case .timeout:
            return "Request timed out. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again later."
        }
    }
    
    /// Returns true if the error is recoverable through retry
    public var isRetryable: Bool {
        switch self {
        case .timeout:
            return true
        case .noInternet:
            return true
        case .serverError:
            return true
        case .requestFailed(let code) where code >= 500 || code == 429:
            // 5xx status codes are server errors
            // 429 is Too Many Requests
            return true
        default:
            return false
        }
    }
    
    /// Map NSError to NetworkError
    public static func mapError(_ error: Error) -> NetworkError {
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .noInternet
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
                return .invalidURL
            default:
                return .unknown(description: nsError.localizedDescription)
            }
        default:
            return .unknown(description: nsError.localizedDescription)
        }
    }
    
    /// Equatable implementation
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.noInternet, .noInternet),
             (.timeout, .timeout),
             (.serverError, .serverError):
            return true
        case (.requestFailed(let lhsCode), .requestFailed(let rhsCode)):
            return lhsCode == rhsCode
        case (.decodingFailed(let lhsDesc), .decodingFailed(let rhsDesc)):
            return lhsDesc == rhsDesc
        case (.unknown(let lhsDesc), .unknown(let rhsDesc)):
            return lhsDesc == rhsDesc
        default:
            return false
        }
    }
} 