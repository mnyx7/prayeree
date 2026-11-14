//
//  QuranRepositoryProtocol.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// Generic over the fetched value so one shape covers surahs, ayahs, the
/// daily ayah, and translations — `value` is nil only when there's no
/// usable cache AND the network call failed, mirroring PrayerTimesRepositoryResult.
struct QuranRepositoryResult<Value: Sendable>: Sendable {
    let value: Value?
    let freshness: DataFreshness
    let error: NetworkError?
}

protocol QuranRepositoryProtocol: Sendable {
    func surahs(languageCode: String) -> AsyncStream<QuranRepositoryResult<[Surah]>>
    func ayahs(surahNumber: Int, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<[Ayah]>>
    /// `date` only needs day-level granularity — it partitions the cache key
    /// so the same ayah is returned all day rather than re-randomizing per request.
    func dailyAyah(date: Date, translationId: Int, languageCode: String) -> AsyncStream<QuranRepositoryResult<Ayah>>
    func translations() -> AsyncStream<QuranRepositoryResult<[QuranTranslation]>>
}
