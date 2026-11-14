//
//  QuranRepository.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct QuranRepository: QuranRepositoryProtocol {
    let service: any QuranServiceProtocol
    let cacheStore: any CacheStore

    func surahs(languageCode: String) -> AsyncStream<QuranRepositoryResult<[Surah]>> {
        let key = CacheKey(namespace: "quran.surahs", identifier: languageCode)
        return networkStream(key: key) {
            try await service.fetchSurahs(languageCode: languageCode)
        }
    }

    func ayahs(surahNumber: Int, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<[Ayah]>> {
        let key = CacheKey(namespace: "quran.ayahs", identifier: "\(surahNumber)_\(translationId)_\(languageCode)")
        return networkStream(key: key) {
            try await service.fetchAyahs(surahNumber: surahNumber, translationId: translationId, languageCode: languageCode)
        }
    }

    func dailyAyah(date: Date, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<Ayah>> {
        let dayKey = Self.dayKey(for: date)
        let key = CacheKey(namespace: "quran.dailyAyah.v2", identifier: "\(dayKey)_\(translationId)_\(languageCode)")
        return networkStream(key: key) {
            try await service.fetchDailyAyah(date: date, translationId: translationId, languageCode: languageCode)
        }
    }

    func translations() -> AsyncStream<QuranRepositoryResult<[QuranTranslation]>> {
        let key = CacheKey(namespace: "quran.translations", identifier: "all")
        return networkStream(key: key) {
            try await service.fetchTranslations()
        }
    }

    static func dayKey(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    /// Network-only until an approved Content Sync integration is available.
    private func networkStream<Value: Codable & Sendable>(
        key: CacheKey,
        fetch: @escaping @Sendable () async throws -> Value
    ) -> AsyncStream<QuranRepositoryResult<Value>> {
        AsyncStream { continuation in
            let task = Task {
                // Regular Content API responses are display-only. Offline content
                // requires the provider's Content Sync integration.
                await cacheStore.removeValue(for: key)
                do {
                    let fresh = try await fetch()
                    continuation.yield(
                        QuranRepositoryResult(value: fresh, freshness: .fresh(fetchedAt: Date()), error: nil)
                    )
                } catch {
                    let networkError = (error as? NetworkError) ?? .transportError(error.localizedDescription)
                    continuation.yield(
                        QuranRepositoryResult(value: nil, freshness: .none, error: networkError)
                    )
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
