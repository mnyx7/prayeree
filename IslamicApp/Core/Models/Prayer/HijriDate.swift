struct HijriDate: Codable, Equatable, Sendable {
    let day: Int
    let month: HijriMonth
    let year: Int
}

enum HijriMonth: Int, Codable, CaseIterable, Sendable {
    case muharram = 1
    case safar
    case rabiAlAwwal
    case rabiAlThani
    case jumadaAlAwwal
    case jumadaAlThani
    case rajab
    case shaban
    case ramadan
    case shawwal
    case dhulQadah
    case dhulHijjah
}
