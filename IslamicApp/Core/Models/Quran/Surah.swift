struct Surah: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: Int
    let arabicName: String
    let transliteratedName: String
    let englishTranslatedName: String
    let versesCount: Int
    let revelationPlace: RevelationPlace
}

enum RevelationPlace: String, Codable, Sendable {
    case makkah
    case madinah
}
