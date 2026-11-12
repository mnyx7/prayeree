enum QuranReadingMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case arabicOnly
    case arabicWithTranslation

    var id: String { rawValue }
}
