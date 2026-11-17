//
//  PrayerTimesRepositoryTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

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

// QMİ is an optional published timetable, not another AlAdhan calculation preset.
final class MinberPrayerTimetableTests: XCTestCase {
    private let coordinates = Coordinates(latitude: 40.4093, longitude: 49.8671)
    private let date = DateComponents(year: 2026, month: 11, day: 17)
    private var city: City { City(id: "az-baku", name: "Baku", countryCode: "AZ", coordinates: coordinates, timeZoneIdentifier: "Asia/Baku") }
    private func directory() throws -> MinberDirectoryDTO {
        try JSONDecoder().decode(MinberDirectoryDTO.self, from: Data(#"{"Cities":[{"city":"baki","name":"BAKI"},{"city":"sheki","name":"ŞƏKİ"}]}"#.utf8))
    }
    private func month(time: String = "06:06", day: String = "17 Noyabr 2026") throws -> MinberMonthDTO {
        let json = """
        {"Info":{"Status":"Success"},"CityInfo":{"name":"BAKI"},"PrayerTimes":[{"tarix":"\(day)","hicri":"8 Cəmadiyəlaxır 1448","subh":"\(time)","gunorta":"12:25","ikindi":"15:39","axsam":"17:41","yatsi":"18:43"}]}
        """
        return try JSONDecoder().decode(MinberMonthDTO.self, from: Data(json.utf8))
    }
    @MainActor func testRoutesOnlyNewMethodToMinberAndReusesMonth() async throws {
        let client = MockAPIClient()
        let directory = try directory(), month = try month()
        client.handler = { endpoint in
            if endpoint is MinberDirectoryEndpoint { return directory }
            XCTAssertEqual(endpoint.baseURL.host, "namaz.minber.az")
            XCTAssertEqual(endpoint.path, "/json/baki/2026/11")
            return month
        }
        let service = PrayerTimesService(apiClient: client)
        let standard = try await service.fetchPrayerTimes(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .shafiMalikiHanbali, adjustment: .zero, city: city)
        let hanafi = try await service.fetchPrayerTimes(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .hanafi, adjustment: .zero, city: city)
        XCTAssertEqual(standard.times, hanafi.times, "Madhab must not modify a published timetable")
        XCTAssertEqual(client.requestedEndpoints.count, 2, "Directory and month are reused")
        XCTAssertEqual(standard.calculationMethod, .qmiMinber)
        XCTAssertEqual(standard.timeZoneIdentifier, "Asia/Baku")
        XCTAssertEqual(standard.hijriDate, HijriDate(day: 8, month: .jumadaAlThani, year: 1448))
    }
    func testMapsBakuTimeAndAppliesExistingMinuteAdjustments() throws {
        let baseline = try MinberPrayerTimetable.map(month(), dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero)
        let adjusted = try MinberPrayerTimetable.map(month(), dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero.adjusting(.fajr, byMinutes: 3))
        XCTAssertEqual(adjusted.time(for: .fajr)!.date.timeIntervalSince(baseline.time(for: .fajr)!.date), 180)
        XCTAssertEqual(adjusted.time(for: .asr), baseline.time(for: .asr))
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(calendar.component(.hour, from: baseline.time(for: .fajr)!.date), 2)
        XCTAssertEqual(calendar.component(.minute, from: baseline.time(for: .fajr)!.date), 6)
    }
    func testRejectsMissingDateInvalidTimeAndInvalidCalendarDate() throws {
        XCTAssertThrowsError(try MinberPrayerTimetable.map(month(day: "17 Noyabr 2025"), dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero))
        XCTAssertThrowsError(try MinberPrayerTimetable.map(month(time: "25:06"), dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero))
        XCTAssertThrowsError(try MinberPrayerTimetable.map(month(), dateComponents: DateComponents(year: 2026, month: 13, day: 1), coordinates: coordinates, madhab: .hanafi, adjustment: .zero))
    }
    @MainActor func testPublishedTimetablePopulatesInitiallyEmptyWidgetSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileStore = WidgetFileStore(directory: directory)
        let publisher = AppWidgetPublisher(store: fileStore, reload: { _ in })
        let times = try MinberPrayerTimetable.map(month(), dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero)
        var state = AppState.initial
        state.calculationMethod = .qmiMinber
        state.resolvedCoordinates = coordinates
        state.selectedCity = city
        publisher.publishPrayers(state: state, now: times.date)
        XCTAssertEqual(fileStore.read("prayers", as: WidgetPrayerSnapshot.self)?.days.count, 0)
        publisher.publishPrayerTimes(times, now: times.date)
        let snapshot = try XCTUnwrap(fileStore.read("prayers", as: WidgetPrayerSnapshot.self))
        XCTAssertEqual(snapshot.days.count, 1)
        XCTAssertEqual(snapshot.days[0].prayers.count, 5)
        XCTAssertEqual(snapshot.timeZoneIdentifier, "Asia/Baku")
    }
    func testRecognizesProviderZilMonthSpellings() throws {
        let november = try month()
        for (raw, expected) in [("Zilqədə", HijriMonth.dhulQadah), ("Zilhiccə", HijriMonth.dhulHijjah)] {
            let row = november.PrayerTimes[0]
            let changed = MinberMonthDTO(Info: november.Info, CityInfo: november.CityInfo,
                PrayerTimes: [.init(tarix: row.tarix, hicri: "8 \(raw) 1448", subh: row.subh, gunorta: row.gunorta, ikindi: row.ikindi, axsam: row.axsam, yatsi: row.yatsi)])
            let result = try MinberPrayerTimetable.map(changed, dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero)
            XCTAssertEqual(result.hijriDate.month, expected)
        }
    }
    func testCityMatchingNeverDefaultsToBaku() throws {
        XCTAssertEqual(MinberPrayerTimetable.citySlug(for: city, coordinates: coordinates, directory: try directory()), "baki")
        let foreign = City(id: "gb-baku", name: "Baku", countryCode: "GB", coordinates: coordinates, timeZoneIdentifier: "UTC")
        XCTAssertNil(MinberPrayerTimetable.citySlug(for: foreign, coordinates: coordinates, directory: try directory()))
        let unknown = City(id: "az-village", name: "Unknown village", countryCode: "AZ", coordinates: coordinates, timeZoneIdentifier: "Asia/Baku")
        XCTAssertNil(MinberPrayerTimetable.citySlug(for: unknown, coordinates: coordinates, directory: try directory()))
        XCTAssertNil(MinberPrayerTimetable.citySlug(for: city, coordinates: Coordinates(latitude: 51, longitude: 0), directory: try directory()))
    }
    func testMinberHasNoApproximateLocalFallbackAndDistinctCache() {
        XCTAssertNil(LocalPrayerTimesCalculator.calculate(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .hanafi, adjustment: .zero, timeZoneIdentifier: "Asia/Baku"))
        let resolved = PrayerTimesRepository.cacheKey(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .hanafi, adjustment: .zero, city: city)
        let unresolved = PrayerTimesRepository.cacheKey(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .hanafi, adjustment: .zero)
        XCTAssertNotEqual(resolved, unresolved)
        XCTAssertEqual(PrayerCalculationMethod.muslimWorldLeague.rawValue, 3)
        XCTAssertEqual(PrayerCalculationMethod.dubai.aladhanID, 16)
    }
    @MainActor func testUnsupportedLocationMakesNoNetworkCall() async {
        let client = MockAPIClient()
        do {
            _ = try await PrayerTimesService(apiClient: client).fetchPrayerTimes(dateComponents: date, coordinates: coordinates, calculationMethod: .qmiMinber, madhab: .hanafi, adjustment: .zero)
            XCTFail("Unresolved city should not use a default timetable")
        } catch { XCTAssertTrue(client.requestedEndpoints.isEmpty) }
    }
}

final class SunriseTests: XCTestCase {
    private let coordinates = Coordinates(latitude: 40.4093, longitude: 49.8671)
    private let date = DateComponents(year: 2026, month: 11, day: 17)

    private func aladhan(sunrise: String?) throws -> PrayerTimes {
        let response = AlAdhanTimingsResponseDTO(data: .init(
            timings: .init(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30", sunrise: sunrise),
            date: .init(hijri: .init(day: "8", month: .init(number: 6), year: "1448")),
            meta: .init(timezone: "Asia/Baku")))
        return try PrayerTimesMapper.map(response: response, dateComponents: date, coordinates: coordinates, calculationMethod: .muslimWorldLeague, madhab: .hanafi)
    }
    func testAlAdhanSunriseUsesLocationTimezoneAndIsNotNextPrayer() throws {
        let result = try aladhan(sunrise: "06:30 (+04)")
        let sunrise = try XCTUnwrap(result.sunrise)
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(utc.component(.hour, from: sunrise), 2)
        XCTAssertEqual(utc.component(.minute, from: sunrise), 30)
        XCTAssertEqual(result.times.count, 5)
        XCTAssertEqual(result.nextPrayer(after: result.time(for: .fajr)!.date)?.name, .dhuhr)
        XCTAssertFalse(result.times.contains { $0.date == sunrise })
    }
    func testMissingOrMalformedSunriseDoesNotBreakPrayerTimes() throws {
        XCTAssertNil(try aladhan(sunrise: nil).sunrise)
        let malformed = try aladhan(sunrise: "25:99")
        XCTAssertNil(malformed.sunrise)
        XCTAssertEqual(malformed.times.count, 5)
    }
    func testOldCachedSchedulesStillDecode() throws {
        let schedule = try aladhan(sunrise: "06:30")
        let data = try JSONEncoder().encode(schedule)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "sunrise")
        let legacy = try JSONDecoder().decode(PrayerTimes.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(legacy.sunrise)
        XCTAssertEqual(legacy.times, schedule.times)
        XCTAssertEqual(try JSONDecoder().decode(PrayerTimes.self, from: data).sunrise, schedule.sunrise)
    }
    func testLocalCalculationIncludesSunriseWithoutAddingAPrayer() throws {
        let result = try XCTUnwrap(LocalPrayerTimesCalculator.calculate(dateComponents: date, coordinates: coordinates, calculationMethod: .muslimWorldLeague, madhab: .hanafi, adjustment: .zero, timeZoneIdentifier: "Asia/Baku"))
        let sunrise = try XCTUnwrap(result.sunrise)
        XCTAssertGreaterThan(sunrise, result.time(for: .fajr)!.date)
        XCTAssertLessThan(sunrise, result.time(for: .dhuhr)!.date)
        XCTAssertEqual(result.times.count, 5)
    }
    func testMinberSunriseIsParsedAndUnaffectedByPrayerAdjustments() throws {
        let json = #"{"Info":{"Status":"Success"},"CityInfo":{"name":"BAKI"},"PrayerTimes":[{"tarix":"17 Noyabr 2026","hicri":"8 Cəmadiyəlaxır 1448","subh":"06:05","gunes":"07:29","gunorta":"12:25","ikindi":"15:41","axsam":"17:37","yatsi":"18:40"}]}"#
        let response = try JSONDecoder().decode(MinberMonthDTO.self, from: Data(json.utf8))
        let result = try MinberPrayerTimetable.map(response, dateComponents: date, coordinates: coordinates, madhab: .hanafi, adjustment: .zero.adjusting(.fajr, byMinutes: 4))
        let sunrise = try XCTUnwrap(result.sunrise)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = result.timeZone
        XCTAssertEqual(calendar.component(.hour, from: sunrise), 7)
        XCTAssertEqual(calendar.component(.minute, from: sunrise), 29)
        XCTAssertEqual(calendar.component(.minute, from: result.time(for: .fajr)!.date), 9)
        XCTAssertEqual(result.times.count, 5)
    }
}
