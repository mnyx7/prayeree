//
//  City.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct City: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Stable slug (e.g. "SA-mecca") so recents/favorites match across launches
    /// without depending on a remote geocoder returning identical results twice.
    let id: String
    let name: String
    let countryCode: String
    let coordinates: Coordinates
    let timeZoneIdentifier: String
}
