import XCTest
import Foundation
@testable import IslamicApp

private struct StubEndpoint: Endpoint {
    let baseURL = URL(string: "https://example.com")!
    let path = "/stub"
    var queryItems: [URLQueryItem] = []
}

private struct StubResponse: Decodable, Sendable, Equatable {
    let message: String
}

final class MockAPIClientTests: XCTestCase {
    func testHandlerStubReturnsConfiguredValue() async throws {
        let client = MockAPIClient()
        client.handler = { _ in StubResponse(message: "hello") }

        let result = try await client.send(StubEndpoint(), decodingTo: StubResponse.self)

        XCTAssertEqual(result, StubResponse(message: "hello"))
    }

    func testMissingHandlerThrowsInvalidResponse() async {
        let client = MockAPIClient()

        do {
            _ = try await client.send(StubEndpoint(), decodingTo: StubResponse.self)
            XCTFail("Expected send to throw when no handler is configured")
        } catch {
            XCTAssertEqual(error as? NetworkError, .invalidResponse)
        }
    }

    func testHandlerThrowingErrorPropagates() async {
        let client = MockAPIClient()
        client.handler = { _ in throw NetworkError.httpStatus(500) }

        do {
            _ = try await client.send(StubEndpoint(), decodingTo: StubResponse.self)
            XCTFail("Expected send to propagate the handler's error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .httpStatus(500))
        }
    }

    func testRequestedEndpointsAreRecorded() async throws {
        let client = MockAPIClient()
        client.handler = { _ in StubResponse(message: "ok") }

        _ = try await client.send(StubEndpoint(), decodingTo: StubResponse.self)

        XCTAssertEqual(client.requestedEndpoints.count, 1)
    }

    func testMismatchedStubTypeThrowsDecodingFailed() async {
        let client = MockAPIClient()
        client.handler = { _ in "not a StubResponse" }

        do {
            _ = try await client.send(StubEndpoint(), decodingTo: StubResponse.self)
            XCTFail("Expected send to throw when the stub type doesn't match Response")
        } catch {
            guard case .decodingFailed = error as? NetworkError else {
                return XCTFail("Expected NetworkError.decodingFailed, got \(error)")
            }
        }
    }
}
