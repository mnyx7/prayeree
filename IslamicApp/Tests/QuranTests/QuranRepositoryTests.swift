//
//  QuranRepositoryTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

final class QuranRepositoryTests: XCTestCase {
    private func makeChaptersResponse() -> QuranChaptersResponseDTO {
        QuranChaptersResponseDTO(chapters: [
            QuranChapterDTO(id: 1, revelationPlace: "makkah", versesCount: 7, nameSimple: "Al-Fatihah", nameArabic: "الفاتحة", translatedName: QuranTranslatedNameDTO(name: "The Opener"))
        ])
    }

    @MainActor
    private func makeRepository() -> (QuranRepository, MockAPIClient, InMemoryCacheStore) {
        let apiClient = MockAPIClient()
        let cacheStore = InMemoryCacheStore()
        let repository = QuranRepository(service: QuranService(apiClient: apiClient), cacheStore: cacheStore)
        return (repository, apiClient, cacheStore)
    }

    private func collectAll(_ stream: AsyncStream<QuranRepositoryResult<[Surah]>>) async -> [QuranRepositoryResult<[Surah]>] {
        var results: [QuranRepositoryResult<[Surah]>] = []
        for await result in stream { results.append(result) }
        return results
    }

    @MainActor
    func testFirstFetchWithNoCacheYieldsSingleFreshResult() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeChaptersResponse() }

        let results = await collectAll(repository.surahs(languageCode: "en"))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].value?.count, 1)
        if case .fresh = results[0].freshness {} else { XCTFail("Expected .fresh freshness") }
    }

    @MainActor
    func testRepeatedFetchDoesNotPersistProviderContent() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeChaptersResponse() }
        _ = await collectAll(repository.surahs(languageCode: "en"))

        let results = await collectAll(repository.surahs(languageCode: "en"))

        XCTAssertEqual(results.count, 1)
        if case .fresh = results[0].freshness {} else { XCTFail("Expected fresh network content") }
    }

    @MainActor
    func testNetworkFailureDoesNotReuseOfflineProviderContent() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeChaptersResponse() }
        _ = await collectAll(repository.surahs(languageCode: "en"))

        apiClient.handler = { _ in throw NetworkError.httpStatus(500) }
        let results = await collectAll(repository.surahs(languageCode: "en"))

        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].value)
        XCTAssertNotNil(results[0].error)
    }

    @MainActor
    func testNoCacheAndNetworkFailureYieldsNilWithError() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in throw NetworkError.httpStatus(404) }

        let results = await collectAll(repository.surahs(languageCode: "en"))

        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].value)
        XCTAssertNotNil(results[0].error)
    }

    @MainActor
    func testDifferentLanguageCodesUseDistinctCacheEntries() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeChaptersResponse() }
        _ = await collectAll(repository.surahs(languageCode: "en"))

        // A different language code must not hit the "en" cache entry — expect
        // a fresh-only fetch (1 emission), not a cached-then-fresh pair.
        let results = await collectAll(repository.surahs(languageCode: "ar"))

        XCTAssertEqual(results.count, 1)
        if case .fresh = results[0].freshness {} else { XCTFail("Expected .fresh freshness for a different language's first fetch") }
    }

    @MainActor
    func testServiceLoadsEveryPageOfALongSurah() async throws {
        let client = MockAPIClient()
        client.handler = { endpoint in
            let endpoint = endpoint as! QuranVersesByChapterEndpoint
            let verse = QuranVerseDTO(verseNumber: endpoint.page, verseKey: "2:\(endpoint.page)", textUthmani: "آية", translations: nil)
            return QuranVersesResponseDTO(verses: [verse], pagination: QuranPaginationDTO(nextPage: endpoint.page == 1 ? 2 : nil))
        }
        let ayahs = try await QuranService(apiClient: client).fetchAyahs(surahNumber: 2, translationId: 20, languageCode: "en")
        XCTAssertEqual(ayahs.map(\.ayahNumberInSurah), [1, 2])
        XCTAssertEqual(client.requestedEndpoints.count, 2)
    }

    @MainActor
    func testDailyAyahStaysTheSameAcrossVisitsAndTranslationsThenChangesNextDay() async throws {
        let (repository, client, _) = makeRepository()
        client.handler = { endpoint in
            if endpoint is QuranChaptersEndpoint { return self.makeChaptersResponse() }
            let endpoint = endpoint as! QuranVerseByKeyEndpoint
            return QuranRandomVerseResponseDTO(verse: QuranVerseDTO(
                verseNumber: Int(endpoint.verseKey.split(separator: ":")[1])!,
                verseKey: endpoint.verseKey, textUthmani: "آية", translations: nil))
        }
        let today = Date()
        var first: Ayah?
        for await result in repository.dailyAyah(date: today, translationId: 20, languageCode: "en") { first = result.value }
        let count = client.requestedEndpoints.count
        var repeated: Ayah?
        for await result in repository.dailyAyah(date: today, translationId: 20, languageCode: "en") { repeated = result.value }
        XCTAssertEqual(repeated, first)
        XCTAssertGreaterThan(client.requestedEndpoints.count, count, "Daily selection stays deterministic while content is fetched online")
        var translated: Ayah?
        for await result in repository.dailyAyah(date: today, translationId: 85, languageCode: "en") { translated = result.value }
        XCTAssertEqual(translated?.id, first?.id)
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: today))
        var next: Ayah?
        for await result in repository.dailyAyah(date: tomorrow, translationId: 20, languageCode: "en") { next = result.value }
        XCTAssertNotEqual(next?.id, first?.id)
    }

    func testDailyAyahUsesTheLocalCalendarDay() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-12T22:00:00Z"))
        XCTAssertEqual(QuranRepository.dayKey(for: date, timeZone: TimeZone(identifier: "Asia/Baku")!), "2026-11-13")
        XCTAssertEqual(QuranRepository.dayKey(for: date, timeZone: TimeZone(secondsFromGMT: 0)!), "2026-11-12")
    }

    @MainActor
    func testReferenceOnlyWidgetDoesNotFetchVerseText() async throws {
        let client = MockAPIClient()
        client.handler = { endpoint in
            guard endpoint is QuranChaptersEndpoint else { throw NetworkError.invalidResponse }
            return self.makeChaptersResponse()
        }
        let reference = try await QuranService(apiClient: client).dailyAyahReference(date: Date(), languageCode: "en")
        XCTAssertEqual(reference.surah, 1)
        XCTAssertTrue((1...7).contains(reference.ayah))
        XCTAssertEqual(client.requestedEndpoints.count, 1)
        XCTAssertTrue(client.requestedEndpoints.allSatisfy { $0 is QuranChaptersEndpoint })
    }
}
