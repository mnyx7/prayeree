//
//  QuranServiceProtocol.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

protocol QuranServiceProtocol: Sendable {
    func fetchSurahs(languageCode: String) async throws -> [Surah]
    func fetchAyahs(surahNumber: Int, translationId: Int, languageCode: String) async throws -> [Ayah]
    func fetchDailyAyah(date: Date, translationId: Int, languageCode: String) async throws -> Ayah
    func fetchTranslations() async throws -> [QuranTranslation]
}
