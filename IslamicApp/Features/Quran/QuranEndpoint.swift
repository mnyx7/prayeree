import Foundation

struct QuranChaptersEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.quran.com")!
    let languageCode: String

    var path: String { "/api/v4/chapters" }
    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "language", value: languageCode)]
    }
}

struct QuranVersesByChapterEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.quran.com")!
    let chapterNumber: Int
    let translationId: Int
    let languageCode: String
    var page: Int = 1

    var path: String { "/api/v4/verses/by_chapter/\(chapterNumber)" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: languageCode),
            URLQueryItem(name: "translations", value: String(translationId)),
            URLQueryItem(name: "fields", value: "text_uthmani"),
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "page", value: String(page))
        ]
    }
}

struct QuranRandomVerseEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.quran.com")!
    let translationId: Int
    let languageCode: String

    var path: String { "/api/v4/verses/random" }
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: languageCode),
            URLQueryItem(name: "translations", value: String(translationId)),
            URLQueryItem(name: "fields", value: "text_uthmani")
        ]
    }
}

struct QuranTranslationsEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.quran.com")!

    var path: String { "/api/v4/resources/translations" }
    var queryItems: [URLQueryItem] { [] }
}

struct QuranVerseByKeyEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.quran.com")!
    let verseKey: String
    let translationId: Int
    let languageCode: String
    var path: String { "/api/v4/verses/by_key/\(verseKey)" }
    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "language", value: languageCode),
         URLQueryItem(name: "translations", value: String(translationId)),
         URLQueryItem(name: "fields", value: "text_uthmani")]
    }
}
