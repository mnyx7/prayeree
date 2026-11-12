struct QuranTranslation: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: Int
    let languageCode: String
    let name: String
}

extension QuranTranslation {
    /// Quran.com resource ID for Saheeh International (English) — used as
    /// the V1 default until the user picks another translation.
    static let defaultID = 20
}
