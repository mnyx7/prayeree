//
//  QuranService.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct QuranService: QuranServiceProtocol {
    let apiClient: any APIClientProtocol

    func fetchSurahs(languageCode: String) async throws -> [Surah] {
        let endpoint = QuranChaptersEndpoint(languageCode: languageCode)
        let response = try await apiClient.send(endpoint, decodingTo: QuranChaptersResponseDTO.self)
        return response.chapters.map(QuranMapper.map(chapter:))
    }

    func fetchAyahs(surahNumber: Int, translationId: Int, languageCode: String) async throws -> [Ayah] {
        var ayahs: [Ayah] = []
        var page = 1
        while true {
            try Task.checkCancellation()
            let endpoint = QuranVersesByChapterEndpoint(
                chapterNumber: surahNumber,
                translationId: translationId,
                languageCode: languageCode,
                page: page
            )
            let response = try await apiClient.send(endpoint, decodingTo: QuranVersesResponseDTO.self)
            ayahs.append(contentsOf: response.verses.map { QuranMapper.map(verse: $0, translationId: translationId) })
            guard let next = response.pagination?.nextPage else { break }
            guard next > page, next <= 20 else { throw NetworkError.invalidResponse }
            page = next
        }
        guard !ayahs.isEmpty else { throw NetworkError.invalidResponse }
        return ayahs
    }

    func fetchDailyAyah(date: Date, translationId: Int, languageCode: String) async throws -> Ayah {
        let reference = try await dailyAyahReference(date: date, languageCode: languageCode)
        let endpoint = QuranVerseByKeyEndpoint(verseKey: "\(reference.surah):\(reference.ayah)", translationId: translationId, languageCode: languageCode)
        let response = try await apiClient.send(endpoint, decodingTo: QuranRandomVerseResponseDTO.self)
        return QuranMapper.map(verse: response.verse, translationId: translationId)
    }

    /// The reference-only widget uses chapter metadata without fetching or retaining verse text.
    func dailyAyahReference(date: Date, languageCode: String) async throws -> (surah: Int, ayah: Int) {
        let surahs = try await fetchSurahs(languageCode: languageCode).sorted { $0.id < $1.id }
        let total = surahs.reduce(0) { $0 + $1.versesCount }
        guard total > 0 else { throw NetworkError.invalidResponse }
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 1
        var index = (day * 1543) % total
        for surah in surahs {
            if index < surah.versesCount { return (surah.id, index + 1) }
            index -= surah.versesCount
        }
        throw NetworkError.invalidResponse
    }

    func fetchTranslations() async throws -> [QuranTranslation] {
        let endpoint = QuranTranslationsEndpoint()
        let response = try await apiClient.send(endpoint, decodingTo: QuranTranslationsResponseDTO.self)
        return response.translations.map(QuranMapper.map(translation:))
    }
}
