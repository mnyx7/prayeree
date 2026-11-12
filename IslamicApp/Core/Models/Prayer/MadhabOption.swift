/// Raw values correspond to AlAdhan API's `school` parameter
/// (0 = Shafi/Maliki/Hanbali standard shadow factor, 1 = Hanafi).
enum MadhabOption: Int, Codable, CaseIterable, Identifiable, Sendable {
    case shafiMalikiHanbali = 0
    case hanafi = 1

    var id: Int { rawValue }
}
