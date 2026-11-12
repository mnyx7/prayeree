import Foundation

// Matches Quran.com API v4's response shapes. Only fields the domain layer
// needs are declared; JSONDecoder ignores the rest (pages, bismillah_pre,
// revelation_order, pagination metadata, etc.).

struct QuranChaptersResponseDTO: Decodable, Sendable {
    let chapters: [QuranChapterDTO]
}

struct QuranChapterDTO: Decodable, Sendable {
    let id: Int
    let revelationPlace: String
    let versesCount: Int
    let nameSimple: String
    let nameArabic: String
    let translatedName: QuranTranslatedNameDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case revelationPlace = "revelation_place"
        case versesCount = "verses_count"
        case nameSimple = "name_simple"
        case nameArabic = "name_arabic"
        case translatedName = "translated_name"
    }
}

struct QuranTranslatedNameDTO: Decodable, Sendable {
    let name: String
}

struct QuranVersesResponseDTO: Decodable, Sendable {
    let verses: [QuranVerseDTO]
    var pagination: QuranPaginationDTO? = nil
}

struct QuranPaginationDTO: Decodable, Sendable {
    let nextPage: Int?
    enum CodingKeys: String, CodingKey { case nextPage = "next_page" }
}

struct QuranRandomVerseResponseDTO: Decodable, Sendable {
    let verse: QuranVerseDTO
}

struct QuranVerseDTO: Decodable, Sendable {
    let verseNumber: Int
    let verseKey: String
    let textUthmani: String
    let translations: [QuranVerseTranslationDTO]?

    enum CodingKeys: String, CodingKey {
        case verseNumber = "verse_number"
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
        case translations
    }
}

struct QuranVerseTranslationDTO: Decodable, Sendable {
    let resourceId: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id"
        case text
    }
}

struct QuranTranslationsResponseDTO: Decodable, Sendable {
    let translations: [QuranTranslationResourceDTO]
}

struct QuranTranslationResourceDTO: Decodable, Sendable {
    let id: Int
    let languageName: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case languageName = "language_name"
        case name
    }
}
