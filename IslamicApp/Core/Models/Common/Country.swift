import Foundation

struct Country: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// ISO 3166-1 alpha-2 country code (e.g. "SA"), also used as the stable identifier.
    let id: String
    let name: String
}

extension Country {
    init(code: String) {
        self.init(id: code, name: Locale.current.localizedString(forRegionCode: code) ?? code)
    }

    /// The full country list, derived from Foundation rather than a bundled
    /// dataset — always accurate, and localizes automatically with the app.
    static var all: [Country] {
        Locale.isoRegionCodes
            .map { Country(code: $0) }
            .sorted { $0.name < $1.name }
    }
}
