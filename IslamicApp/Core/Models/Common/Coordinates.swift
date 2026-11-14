//
//  Coordinates.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct Coordinates: Codable, Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Used to build stable cache keys from otherwise high-precision GPS readings.
    func rounded(toDecimalPlaces places: Int) -> Coordinates {
        let factor = pow(10, Double(places))
        return Coordinates(
            latitude: (latitude * factor).rounded() / factor,
            longitude: (longitude * factor).rounded() / factor
        )
    }
}
