//
//  Ayah.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

struct Ayah: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let surahNumber: Int
    let ayahNumberInSurah: Int
    let arabicText: String
    let translation: String?
    let translationId: Int?

    init(surahNumber: Int, ayahNumberInSurah: Int, arabicText: String, translation: String?, translationId: Int?) {
        self.id = "\(surahNumber):\(ayahNumberInSurah)"
        self.surahNumber = surahNumber
        self.ayahNumberInSurah = ayahNumberInSurah
        self.arabicText = arabicText
        self.translation = translation
        self.translationId = translationId
    }
}
