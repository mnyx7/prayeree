import Foundation

// Matches AlAdhan's /v1/timings/{date} response shape. Only the fields the
// domain layer actually needs are declared — JSONDecoder ignores the rest
// (Sunrise, Sunset, Imsak, Midnight, method metadata, etc.).

struct AlAdhanTimingsResponseDTO: Decodable, Sendable {
    let data: AlAdhanTimingsDataDTO
}

struct AlAdhanTimingsDataDTO: Decodable, Sendable {
    let timings: AlAdhanTimingsDTO
    let date: AlAdhanDateDTO
    let meta: AlAdhanMetaDTO
}

struct AlAdhanTimingsDTO: Decodable, Sendable {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
    }
}

struct AlAdhanDateDTO: Decodable, Sendable {
    let hijri: AlAdhanHijriDateDTO
}

struct AlAdhanHijriDateDTO: Decodable, Sendable {
    let day: String
    let month: AlAdhanHijriMonthDTO
    let year: String
}

struct AlAdhanHijriMonthDTO: Decodable, Sendable {
    let number: Int
}

struct AlAdhanMetaDTO: Decodable, Sendable {
    let timezone: String
}
