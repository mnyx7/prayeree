//
//  LocationSourceMode.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum LocationSourceMode: Equatable, Hashable, Sendable {
    case automatic
    case manual(country: Country, city: City)
}

// Enums with associated values do not get synthesized Codable conformance,
// so persistence (via PreferencesStore) requires this manual implementation.
extension LocationSourceMode: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind, country, city
    }

    private enum Kind: String, Codable {
        case automatic, manual
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .automatic:
            self = .automatic
        case .manual:
            let country = try container.decode(Country.self, forKey: .country)
            let city = try container.decode(City.self, forKey: .city)
            self = .manual(country: country, city: city)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .automatic:
            try container.encode(Kind.automatic, forKey: .kind)
        case .manual(let country, let city):
            try container.encode(Kind.manual, forKey: .kind)
            try container.encode(country, forKey: .country)
            try container.encode(city, forKey: .city)
        }
    }
}
