//
//  MockAPIClient.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
@testable import IslamicApp
/// `@unchecked Sendable`: mutable state here is only ever touched from the
/// single test thread driving a given test method, never from concurrent
/// tasks — a real production type would not get this exemption.
final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var handler: (@Sendable (any Endpoint) throws -> Any)?
    private(set) var requestedEndpoints: [any Endpoint] = []

    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, decodingTo type: Response.Type) async throws -> Response {
        requestedEndpoints.append(endpoint)
        guard let handler else {
            throw NetworkError.invalidResponse
        }
        guard let result = try handler(endpoint) as? Response else {
            throw NetworkError.decodingFailed("MockAPIClient handler returned an unexpected type")
        }
        return result
    }
}
