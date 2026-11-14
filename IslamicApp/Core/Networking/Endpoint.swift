//
//  Endpoint.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

protocol Endpoint: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
}

extension Endpoint {
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
}
