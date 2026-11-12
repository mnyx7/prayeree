import Foundation

struct QuranBookmark: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let surahNumber: Int
    let ayahNumberInSurah: Int
    let createdAt: Date
}
