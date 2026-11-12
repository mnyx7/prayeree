/// Raw values correspond to AlAdhan API's `method` parameter. V1 has a single
/// provider, so mirroring its IDs directly avoids a redundant lookup table;
/// revisit if a second provider is added (see Phase 0 assumptions).
enum PrayerCalculationMethod: Int, Codable, CaseIterable, Identifiable, Sendable {
    case karachi = 1
    case northAmerica = 2
    case muslimWorldLeague = 3
    case ummAlQura = 4
    case egyptianGeneralAuthority = 5
    case tehran = 7
    case dubai = 8
    case kuwait = 9
    case qatar = 10
    case singapore = 11
    case turkey = 13
    case moonsightingCommittee = 15

    var id: Int { rawValue }
}
