//
//  Country.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct Country: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2 country code (e.g. "SA"), also used as the stable identifier.
    let id: String
    let name: String
}

extension Country {
    init(code: String) {
        self.init(id: code, name: LocalizationManager.locale.localizedString(forRegionCode: code) ?? code)
    }

    /// The full country list, derived from Foundation rather than a bundled
    /// dataset — always accurate, and localizes automatically with the app.
    static var all: [Country] {
        Locale.Region.isoRegions
            .map { Country(code: $0.identifier) }
            .sorted { $0.name < $1.name }
    }
}
