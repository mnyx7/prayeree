//
//  NetworkError.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

/// Underlying `Error` values are captured as descriptions rather than wrapped
/// directly, keeping this Equatable/testable and preventing raw SDK errors
/// from leaking past the Service layer into Stores and UI.
enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case transportError(String)
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(String)
    case cancelled
}
