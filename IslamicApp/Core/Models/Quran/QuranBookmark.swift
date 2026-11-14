//
//  QuranBookmark.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct QuranBookmark: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let surahNumber: Int
    let ayahNumberInSurah: Int
    let createdAt: Date
}

/// Stores only a reference and display metadata, never Quran or translation text.
struct QuranReadingPosition: Codable, Equatable, Sendable {
    let surah: Surah
    let ayahNumberInSurah: Int

    static let lastReadKey = "quran.lastRead.v1"

    static func storageKey(for surahNumber: Int) -> String {
        "quran.readingPosition.v1.\(surahNumber)"
    }

    var isValid: Bool {
        (1...114).contains(surah.id) && ayahNumberInSurah > 0 && ayahNumberInSurah <= surah.versesCount
    }
}

struct QuranFavoriteAyah: Identifiable, Codable, Equatable, Sendable {
    let surah: Surah
    let ayahNumberInSurah: Int

    var id: String { "\(surah.id):\(ayahNumberInSurah)" }
    var isValid: Bool {
        QuranReadingPosition(surah: surah, ayahNumberInSurah: ayahNumberInSurah).isValid
    }
}
