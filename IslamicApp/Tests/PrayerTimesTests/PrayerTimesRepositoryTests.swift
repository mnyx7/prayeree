import XCTest
@testable import IslamicApp

final class PrayerTimesRepositoryTests: XCTestCase {
    private let coordinates = Coordinates(latitude: 51.5, longitude: -0.12)
    private let dateComponents = DateComponents(year: 2026, month: 1, day: 15)

    private func makeResponse() -> AlAdhanTimingsResponseDTO {
        AlAdhanTimingsResponseDTO(
            data: AlAdhanTimingsDataDTO(
                timings: AlAdhanTimingsDTO(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30"),
                date: AlAdhanDateDTO(hijri: AlAdhanHijriDateDTO(day: "1", month: AlAdhanHijriMonthDTO(number: 1), year: "1447")),
                meta: AlAdhanMetaDTO(timezone: "UTC")
            )
        )
    }

    @MainActor
    private func makeRepository() -> (PrayerTimesRepository, MockAPIClient, InMemoryCacheStore) {
        let apiClient = MockAPIClient()
        let cacheStore = InMemoryCacheStore()
        let repository = PrayerTimesRepository(service: PrayerTimesService(apiClient: apiClient), cacheStore: cacheStore)
        return (repository, apiClient, cacheStore)
    }

    private func collectAll(_ stream: AsyncStream<PrayerTimesRepositoryResult>) async -> [PrayerTimesRepositoryResult] {
        var results: [PrayerTimesRepositoryResult] = []
        for await result in stream { results.append(result) }
        return results
    }

    @MainActor
    func testFirstFetchWithNoCacheYieldsSingleFreshResult() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeResponse() }

        let results = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        XCTAssertEqual(results.count, 1)
        XCTAssertNotNil(results[0].prayerTimes)
        if case .fresh = results[0].freshness {} else { XCTFail("Expected .fresh freshness") }
    }

    @MainActor
    func testCacheHitYieldsCachedThenFreshResults() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeResponse() }

        // Prime the cache first.
        _ = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        let results = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        XCTAssertEqual(results.count, 2)
        if case .cached = results[0].freshness {} else { XCTFail("Expected first emission to be .cached") }
        if case .fresh = results[1].freshness {} else { XCTFail("Expected second emission to be .fresh") }
    }

    @MainActor
    func testNetworkFailureFallsBackToStaleCache() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in self.makeResponse() }
        _ = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        apiClient.handler = { _ in throw NetworkError.httpStatus(500) }
        let results = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        XCTAssertEqual(results.count, 2)
        XCTAssertNotNil(results[0].prayerTimes) // cached, served immediately
        XCTAssertNotNil(results[1].prayerTimes) // network failed, stale cache preserved
        XCTAssertNotNil(results[1].error)
    }

    @MainActor
    func testNoCacheAndNetworkFailureYieldsNilWithError() async {
        let (repository, apiClient, _) = makeRepository()
        apiClient.handler = { _ in throw NetworkError.httpStatus(404) }

        let results = await collectAll(repository.prayerTimes(
            dateComponents: dateComponents, coordinates: coordinates,
            calculationMethod: .ummAlQura, madhab: .shafiMalikiHanbali, adjustment: .zero
        ))

        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].prayerTimes)
        XCTAssertNotNil(results[0].error)
        if case .none = results[0].freshness {} else { XCTFail("Expected .none freshness") }
    }

    @MainActor
    func testProviderOutageStillReturnsLocalTimesWithoutCache() async {
        let (repository, client, _) = makeRepository()
        client.handler = { _ in throw NetworkError.httpStatus(502) }
        let results = await collectAll(repository.prayerTimes(dateComponents: dateComponents,
            coordinates: coordinates, calculationMethod: .muslimWorldLeague,
            madhab: .hanafi, adjustment: .zero, timeZoneIdentifier: "Europe/London"))
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.prayerTimes?.times.count, 5)
        XCTAssertEqual(results.last?.prayerTimes?.timeZoneIdentifier, "Europe/London")
        if case .calculated = results.last?.freshness {} else { XCTFail("Expected local calculation") }
    }

    func testLocalCalculationHonorsMadhabAndMinuteAdjustments() throws {
        let standard = try XCTUnwrap(LocalPrayerTimesCalculator.calculate(dateComponents: dateComponents,
            coordinates: coordinates, calculationMethod: .muslimWorldLeague, madhab: .shafiMalikiHanbali,
            adjustment: .zero, timeZoneIdentifier: "Europe/London"))
        let hanafi = try XCTUnwrap(LocalPrayerTimesCalculator.calculate(dateComponents: dateComponents,
            coordinates: coordinates, calculationMethod: .muslimWorldLeague, madhab: .hanafi,
            adjustment: .zero.adjusting(.fajr, byMinutes: 7), timeZoneIdentifier: "Europe/London"))
        XCTAssertGreaterThan(try XCTUnwrap(hanafi.time(for: .asr)).date, try XCTUnwrap(standard.time(for: .asr)).date)
        XCTAssertEqual(try XCTUnwrap(hanafi.time(for: .fajr)).date.timeIntervalSince(try XCTUnwrap(standard.time(for: .fajr)).date), 420, accuracy: 1)
    }
}
