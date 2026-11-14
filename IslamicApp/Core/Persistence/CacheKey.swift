//
//  CacheKey.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import CryptoKit

/// Deliberately feature-agnostic — repositories (e.g. PrayerTimesRepository)
/// compose the `identifier` from their own domain-specific parameters
/// (date, coordinates, calculation method, ...); this type only knows how
/// to turn that into a safe, deterministic filename.
struct CacheKey: Hashable, Sendable {
    let namespace: String
    let identifier: String

    var storageFileName: String {
        let digest = SHA256.hash(data: Data(identifier.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "\(namespace)_\(hex).json"
    }
}
