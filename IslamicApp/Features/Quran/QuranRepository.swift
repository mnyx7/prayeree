import Foundation

struct QuranRepository: QuranRepositoryProtocol {
    let service: any QuranServiceProtocol
    let cacheStore: any CacheStore

    func surahs(languageCode: String) -> AsyncStream<QuranRepositoryResult<[Surah]>> {
        let key = CacheKey(namespace: "quran.surahs", identifier: languageCode)
        return cacheFirstStream(key: key) {
            try await service.fetchSurahs(languageCode: languageCode)
        }
    }

    func ayahs(surahNumber: Int, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<[Ayah]>> {
        let key = CacheKey(namespace: "quran.ayahs", identifier: "\(surahNumber)_\(translationId)_\(languageCode)")
        return cacheFirstStream(key: key) {
            try await service.fetchAyahs(surahNumber: surahNumber, translationId: translationId, languageCode: languageCode)
        }
    }

    func dailyAyah(date: Date, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<Ayah>> {
        let dayKey = Self.dayKey(for: date)
        let key = CacheKey(namespace: "quran.dailyAyah.v2", identifier: "\(dayKey)_\(translationId)_\(languageCode)")
        return cacheFirstStream(key: key, refreshCached: false) {
            try await service.fetchDailyAyah(date: date, translationId: translationId, languageCode: languageCode)
        }
    }

    func translations() -> AsyncStream<QuranRepositoryResult<[QuranTranslation]>> {
        let key = CacheKey(namespace: "quran.translations", identifier: "all")
        return cacheFirstStream(key: key) {
            try await service.fetchTranslations()
        }
    }

    static func dayKey(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    /// Shared cache-first orchestration (check cache → yield → fetch → save →
    /// yield, with stale-cache fallback on failure) — factored out since all
    /// four Quran resources follow the identical pattern PrayerTimesRepository
    /// uses; kept private/local rather than promoted to Core since it's an
    /// implementation detail of this one repository, not a shared service.
    private func cacheFirstStream<Value: Codable & Sendable>(
        key: CacheKey,
        refreshCached: Bool = true,
        fetch: @escaping @Sendable () async throws -> Value
    ) -> AsyncStream<QuranRepositoryResult<Value>> {
        AsyncStream { continuation in
            let task = Task {
                let cached = await cacheStore.value(for: key, as: Value.self)
                if let cached {
                    continuation.yield(
                        QuranRepositoryResult(value: cached.value, freshness: .cached(fetchedAt: cached.fetchedAt), error: nil)
                    )
                    if !refreshCached { continuation.finish(); return }
                }

                do {
                    let fresh = try await fetch()
                    await cacheStore.save(fresh, for: key)
                    continuation.yield(
                        QuranRepositoryResult(value: fresh, freshness: .fresh(fetchedAt: Date()), error: nil)
                    )
                } catch {
                    let networkError = (error as? NetworkError) ?? .transportError(error.localizedDescription)
                    if let cached {
                        continuation.yield(
                            QuranRepositoryResult(value: cached.value, freshness: .cached(fetchedAt: cached.fetchedAt), error: networkError)
                        )
                    } else {
                        continuation.yield(
                            QuranRepositoryResult(value: nil, freshness: .none, error: networkError)
                        )
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
