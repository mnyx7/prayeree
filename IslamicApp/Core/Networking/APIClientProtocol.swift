//
//  APIClientProtocol.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

protocol APIClientProtocol: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, decodingTo type: Response.Type) async throws -> Response
}
