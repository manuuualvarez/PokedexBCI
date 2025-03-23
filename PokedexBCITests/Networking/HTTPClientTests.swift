import XCTest
import Combine
@testable import PokedexBCI

final class HTTPClientTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: HTTPClient!
    private var mockSession: URLSessionProtocolMock!
    private var mockDecoder: JSONDecoder!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSession = URLSessionProtocolMock()
        mockDecoder = JSONDecoder()
        sut = HTTPClient(session: mockSession, decoder: mockDecoder)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        mockDecoder = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test successful request with no retries
    func testPerformRequest_Success() async throws {
        // Given
        let mockData = """
        {
            "name": "bulbasaur",
            "id": 1
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // When
        let (data, response) = try await sut.performRequest(request, maxRetries: 0, retryDelay: 0.1)
        
        // Then
        XCTAssertEqual(data, mockData)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(mockSession.dataRequestCount, 1, "Request should be made exactly once")
    }
    
    /// Test client error with no retries (4xx)
    func testPerformRequest_ClientError() async {
        // Given
        let mockData = Data()
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // When & Then
        do {
            _ = try await sut.performRequest(request, maxRetries: 3, retryDelay: 0.1)
            XCTFail("Request should have failed with a client error")
        } catch let error as NetworkError {
            // Then
            if case .requestFailed(let statusCode) = error {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Wrong error type received: \(error)")
            }
            XCTAssertEqual(mockSession.dataRequestCount, 1, "Client errors should not be retried")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test server error with retries (5xx)
    func testPerformRequest_ServerError_WithRetries() async {
        // Given
        let failResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let successResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockData = """
        {
            "name": "bulbasaur",
            "id": 1
        }
        """.data(using: .utf8)!
        
        // Set up to fail twice then succeed
        mockSession.responseSequence = [
            (Data(), failResponse),
            (Data(), failResponse),
            (mockData, successResponse)
        ]
        
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // When
        do {
            // Use short retry delay for faster tests
            let (data, response) = try await sut.performRequest(request, maxRetries: 3, retryDelay: 0.05)
            
            // Then
            XCTAssertEqual(data, mockData)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertEqual(mockSession.dataRequestCount, 3, "Request should be made 3 times (2 failures, 1 success)")
        } catch {
            XCTFail("Should have succeeded after retries: \(error)")
        }
    }
    
    /// Test cancellation
    func testPerformRequest_Cancellation() async {
        // Given
        let mockData = Data()
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        mockSession.simulateCancellation = true
        
        let url = URL(string: "https://example.com")!
        let request = URLRequest(url: url)
        
        // Create a task that will be cancelled
        let task = Task<(Data, URLResponse), Error> {
            return try await sut.performRequest(request, maxRetries: 0, retryDelay: 0.1)
        }
        
        // Cancel the task immediately
        task.cancel()
        
        // When & Then
        do {
            _ = try await task.value
            XCTFail("Request should have been cancelled")
        } catch is CancellationError {
            // This is expected
            XCTAssertTrue(true, "Task was properly cancelled")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test get method
    func testGet() async throws {
        // Given
        let mockData = """
        {
            "name": "bulbasaur",
            "id": 1
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        
        let url = URL(string: "https://example.com")!
        
        // When
        let data = try await sut.get(from: url, maxRetries: 0, retryDelay: 0.1)
        
        // Then
        XCTAssertEqual(data, mockData)
        XCTAssertEqual(mockSession.dataRequestCount, 1, "Request should be made exactly once")
    }
    
    /// Test generic get with decoding
    func testGenericGet() async throws {
        // Given
        struct TestPokemon: Decodable, Equatable {
            let name: String
            let id: Int
        }
        
        let expectedPokemon = TestPokemon(name: "bulbasaur", id: 1)
        let mockData = """
        {
            "name": "bulbasaur",
            "id": 1
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        
        let url = URL(string: "https://example.com")!
        
        // When
        let pokemon = try await sut.get(from: url, as: TestPokemon.self, maxRetries: 0, retryDelay: 0.1)
        
        // Then
        XCTAssertEqual(pokemon, expectedPokemon)
        XCTAssertEqual(mockSession.dataRequestCount, 1, "Request should be made exactly once")
    }
    
    /// Test decoding error handling
    func testGenericGet_DecodingError() async {
        // Given
        struct TestPokemon: Decodable, Equatable {
            let name: String
            let type: String // This field is missing in the response
        }
        
        let mockData = """
        {
            "name": "bulbasaur",
            "id": 1
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession.mockDataResponse = (mockData, mockResponse)
        
        let url = URL(string: "https://example.com")!
        
        // When & Then
        do {
            _ = try await sut.get(from: url, as: TestPokemon.self, maxRetries: 0, retryDelay: 0.1)
            XCTFail("Decoding should have failed")
        } catch let error as NetworkError {
            if case .decodingFailed = error {
                // This is expected
            } else {
                XCTFail("Wrong error type received: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Helpers

/// Mock implementation of URLSessionProtocol for testing
final class URLSessionProtocolMock: URLSessionProtocol {
    var mockDataResponse: (Data, URLResponse)!
    var dataRequestCount = 0
    var simulateCancellation = false
    var responseSequence: [(Data, URLResponse)] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataRequestCount += 1
        
        if simulateCancellation {
            throw CancellationError()
        }
        
        // If we have a sequence of responses, use those
        if !responseSequence.isEmpty {
            if dataRequestCount <= responseSequence.count {
                return responseSequence[dataRequestCount - 1]
            }
        }
        
        return mockDataResponse
    }
} 
