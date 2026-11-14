//
//  QuranReadingMode.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

enum QuranReadingMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case arabicOnly
    case arabicWithTranslation

    var id: String { rawValue }
}
