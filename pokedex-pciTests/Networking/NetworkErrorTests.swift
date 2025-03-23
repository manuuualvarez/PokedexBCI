import XCTest
@testable import pokedex_pci

final class NetworkErrorTests: XCTestCase {
    
    // MARK: - Test User Messages
    
    func testUserMessages() {
        // Test all error types have appropriate user messages
        XCTAssertEqual(NetworkError.invalidURL.userMessage, 
                      "Invalid URL. Please contact technical support.")
        
        XCTAssertEqual(NetworkError.requestFailed(statusCode: 404).userMessage, 
                      "Request failed with status code 404. Please try again later.")
        
        XCTAssertEqual(NetworkError.decodingFailed(description: "Test error").userMessage, 
                      "Could not process server response.")
        
        XCTAssertEqual(NetworkError.noData.userMessage, 
                      "No data received from server.")
        
        XCTAssertEqual(NetworkError.noInternet.userMessage, 
                      "No internet connection. Please check your connection and try again.")
        
        XCTAssertEqual(NetworkError.timeout.userMessage, 
                      "Request timed out. Please try again later.")
        
        XCTAssertEqual(NetworkError.serverError.userMessage, 
                      "Server error. Please try again later.")
        
        XCTAssertEqual(NetworkError.unknown(description: "Test description").userMessage, 
                      "An unexpected error occurred. Please try again later.")
    }
    
    // MARK: - Test Retryable Errors
    
    func testRetryableErrors() {
        // Test retryable errors
        XCTAssertTrue(NetworkError.timeout.isRetryable, "Timeout errors should be retryable")
        XCTAssertTrue(NetworkError.noInternet.isRetryable, "No internet errors should be retryable")
        XCTAssertTrue(NetworkError.serverError.isRetryable, "Server errors should be retryable")
        XCTAssertTrue(NetworkError.requestFailed(statusCode: 500).isRetryable, "500 errors should be retryable")
        XCTAssertTrue(NetworkError.requestFailed(statusCode: 503).isRetryable, "503 errors should be retryable")
        XCTAssertTrue(NetworkError.requestFailed(statusCode: 429).isRetryable, "429 errors should be retryable")
        
        // Test non-retryable errors
        XCTAssertFalse(NetworkError.invalidURL.isRetryable, "Invalid URL errors should not be retryable")
        XCTAssertFalse(NetworkError.decodingFailed(description: "Test").isRetryable, "Decoding errors should not be retryable")
        XCTAssertFalse(NetworkError.noData.isRetryable, "No data errors should not be retryable")
        XCTAssertFalse(NetworkError.unknown(description: "Test").isRetryable, "Unknown errors should not be retryable")
        XCTAssertFalse(NetworkError.requestFailed(statusCode: 400).isRetryable, "400 errors should not be retryable")
        XCTAssertFalse(NetworkError.requestFailed(statusCode: 401).isRetryable, "401 errors should not be retryable")
        XCTAssertFalse(NetworkError.requestFailed(statusCode: 404).isRetryable, "404 errors should not be retryable")
    }
    
    // MARK: - Test Error Mapping
    
    func testMapError() {
        // Test mapping NSURLErrorDomain errors
        let notConnectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        XCTAssertEqual(NetworkError.mapError(notConnectedError), .noInternet)
        
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        XCTAssertEqual(NetworkError.mapError(timeoutError), .timeout)
        
        let badURLError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
        XCTAssertEqual(NetworkError.mapError(badURLError), .invalidURL)
        
        let unsupportedURLError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
        XCTAssertEqual(NetworkError.mapError(unsupportedURLError), .invalidURL)
        
        // Test mapping other NSURLErrorDomain errors
        let otherURLError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: [NSLocalizedDescriptionKey: "Cannot find host"])
        if case .unknown(let description) = NetworkError.mapError(otherURLError) {
            XCTAssertEqual(description, "Cannot find host")
        } else {
            XCTFail("Should map to .unknown with description")
        }
        
        // Test mapping non-NSURLErrorDomain errors
        let otherError = NSError(domain: "OtherDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Other error"])
        if case .unknown(let description) = NetworkError.mapError(otherError) {
            XCTAssertEqual(description, "Other error")
        } else {
            XCTFail("Should map to .unknown with description")
        }
    }
    
    // MARK: - Test Equatable
    
    func testEquality() {
        // Test simple cases
        XCTAssertEqual(NetworkError.invalidURL, NetworkError.invalidURL)
        XCTAssertEqual(NetworkError.noData, NetworkError.noData)
        XCTAssertEqual(NetworkError.noInternet, NetworkError.noInternet)
        XCTAssertEqual(NetworkError.timeout, NetworkError.timeout)
        XCTAssertEqual(NetworkError.serverError, NetworkError.serverError)
        
        // Test cases with associated values
        XCTAssertEqual(NetworkError.requestFailed(statusCode: 404), NetworkError.requestFailed(statusCode: 404))
        XCTAssertNotEqual(NetworkError.requestFailed(statusCode: 404), NetworkError.requestFailed(statusCode: 500))
        
        XCTAssertEqual(NetworkError.decodingFailed(description: "Test"), NetworkError.decodingFailed(description: "Test"))
        XCTAssertNotEqual(NetworkError.decodingFailed(description: "Test"), NetworkError.decodingFailed(description: "Different"))
        
        XCTAssertEqual(NetworkError.unknown(description: "Test"), NetworkError.unknown(description: "Test"))
        XCTAssertNotEqual(NetworkError.unknown(description: "Test"), NetworkError.unknown(description: "Different"))
        
        // Test different error types
        XCTAssertNotEqual(NetworkError.invalidURL, NetworkError.timeout)
        XCTAssertNotEqual(NetworkError.requestFailed(statusCode: 404), NetworkError.decodingFailed(description: "Test"))
    }
} 