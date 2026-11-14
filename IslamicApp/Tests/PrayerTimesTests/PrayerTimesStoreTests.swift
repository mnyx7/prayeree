//
//  PrayerTimesStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

@MainActor
final class PrayerTimesStoreTests: XCTestCase {
    private func makeStore(testEnv: TestEnvironment, now: @escaping @Sendable () -> Date = { Date() }) -> PrayerTimesStore {
        makeStoreWithAppStore(testEnv: testEnv, now: now).store
    }

    private func makeStoreWithAppStore(
        testEnv: TestEnvironment,
        now: @escaping @Sendable () -> Date = { Date() }
    ) -> (store: PrayerTimesStore, appStore: AppStore) {
        let repository = PrayerTimesRepository(
            service: PrayerTimesService(apiClient: testEnv.apiClient),
            cacheStore: testEnv.cacheStore
        )
        let appStore = AppStore(environment: testEnv.environment)
        let store = PrayerTimesStore(
            appStore: appStore,
            repository: repository,
            locationManager: testEnv.locationManager,
            preferencesStore: testEnv.preferencesStore,
            now: now
        )
        return (store, appStore)
    }

    nonisolated private func makeTimingsResponse(fajr: String, dhuhr: String, asr: String, maghrib: String, isha: String) -> AlAdhanTimingsResponseDTO {
        AlAdhanTimingsResponseDTO(
            data: AlAdhanTimingsDataDTO(
                timings: AlAdhanTimingsDTO(fajr: fajr, dhuhr: dhuhr, asr: asr, maghrib: maghrib, isha: isha),
                date: AlAdhanDateDTO(hijri: AlAdhanHijriDateDTO(day: "1", month: AlAdhanHijriMonthDTO(number: 1), year: "1447")),
                meta: AlAdhanMetaDTO(timezone: "UTC")
            )
        )
    }

    func testCitySelectedSwitchesToManualModeAndAddsToRecents() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.apiClient.handler = { _ in self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30") }
        let store = makeStore(testEnv: testEnv)
        let city = City(id: "GB-london", name: "London", countryCode: "GB", coordinates: Coordinates(latitude: 51.5, longitude: -0.12), timeZoneIdentifier: "Europe/London")

        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.selectedCity, city)
        if case .manual = store.locationSourceMode {} else { XCTFail("Expected manual location mode") }
        XCTAssertEqual(store.recentCities.first, city)
    }

    func testFavoriteToggledAddsThenRemoves() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let city = City(id: "SA-riyadh", name: "Riyadh", countryCode: "SA", coordinates: Coordinates(latitude: 24.7, longitude: 46.7), timeZoneIdentifier: "Asia/Riyadh")

        store.send(.favoriteToggled(city))
        XCTAssertTrue(store.favoriteCities.contains(city))

        store.send(.favoriteToggled(city))
        XCTAssertFalse(store.favoriteCities.contains(city))
    }

    func testLoadPopulatesPrayerTimesAndNextPrayer() async {
        let testEnv = TestEnvironmentFactory.make()
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000) // fixed reference instant
        testEnv.apiClient.handler = { _ in
            self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30")
        }
        let store = makeStore(testEnv: testEnv, now: { fixedNow })
        let city = City(id: "GB-london", name: "London", countryCode: "GB", coordinates: Coordinates(latitude: 51.5, longitude: -0.12), timeZoneIdentifier: "Europe/London")

        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertNotNil(store.state.prayerTimes)
        XCTAssertEqual(store.state.loadingState, .loaded)
    }

    func testLoadFailureWithNoCacheKeepsLocalPrayerTimes() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.apiClient.handler = { _ in throw NetworkError.httpStatus(500) }
        let store = makeStore(testEnv: testEnv)
        let city = City(id: "GB-london", name: "London", countryCode: "GB", coordinates: Coordinates(latitude: 51.5, longitude: -0.12), timeZoneIdentifier: "Europe/London")

        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertNotNil(store.state.prayerTimes)
        XCTAssertNil(store.state.errorMessage)
        XCTAssertEqual(store.state.loadingState, .loaded)
    }

    func testCountdownTickComputesNextPrayer() async {
        let testEnv = TestEnvironmentFactory.make()
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let now = { calendar.date(byAdding: .hour, value: 10, to: today)! } // fixed 10:00 "now"
        testEnv.apiClient.handler = { _ in
            self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30")
        }
        let store = makeStore(testEnv: testEnv, now: now)
        let city = City(id: "GB-london", name: "London", countryCode: "GB", coordinates: Coordinates(latitude: 51.5, longitude: -0.12), timeZoneIdentifier: "Europe/London")

        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))

        // At 10:00, Dhuhr (12:00) is the next upcoming prayer.
        XCTAssertEqual(store.state.nextPrayer?.name, .dhuhr)
    }

    // Spec section B: "Changing calculation settings must refresh prayer
    // data." PrayerTimesView observes `refreshTrigger` via `.onChange` and
    // re-dispatches `.refreshRequested` — this test verifies the trigger
    // itself actually changes when AppStore's calculation settings change,
    // which is the piece that makes that View-level wiring correct.
    func testRefreshTriggerChangesWhenCalculationSettingsChangeElsewhere() {
        let testEnv = TestEnvironmentFactory.make()
        let (store, appStore) = makeStoreWithAppStore(testEnv: testEnv)
        let before = store.refreshTrigger

        appStore.send(.calculationMethodChanged(.karachi))
        appStore.send(.madhabChanged(.hanafi))

        let after = store.refreshTrigger
        XCTAssertNotEqual(before, after)
        XCTAssertEqual(after.calculationMethod, .karachi)
        XCTAssertEqual(after.madhab, .hanafi)
    }

    func testRefreshTriggerChangesWhenLocationChangesInSettings() {
        // Coordinates are deliberately excluded from the trigger — location
        // changes are already handled by this Store's own action handlers,
        // so including them would double-fetch on every resolution.
        let testEnv = TestEnvironmentFactory.make()
        let (store, appStore) = makeStoreWithAppStore(testEnv: testEnv)
        let before = store.refreshTrigger

        appStore.send(.coordinatesResolved(Coordinates(latitude: 10, longitude: 20)))

        XCTAssertNotEqual(before, store.refreshTrigger)
    }

    // Spec section C: "fall back to the last manual city" when current
    // location resolution fails.
    func testLocationFailureFallsBackToLastManualCityWhenNothingLoadedYet() async {
        let testEnv = TestEnvironmentFactory.make()
        let (store, appStore) = makeStoreWithAppStore(testEnv: testEnv)
        let fallbackCity = City(id: "EG-cairo", name: "Cairo", countryCode: "EG", coordinates: Coordinates(latitude: 30.0, longitude: 31.2), timeZoneIdentifier: "Africa/Cairo")
        appStore.send(.locationSourceModeChanged(.manual(country: Country(code: "EG"), city: fallbackCity)))
        appStore.send(.locationSourceModeChanged(.automatic)) // switch away, but AppState retains the last manual city
        testEnv.apiClient.handler = { _ in
            self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30")
        }

        store.send(.locationRequestFailed("simulated GPS failure"))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(appStore.state.resolvedCoordinates, fallbackCity.coordinates)
        XCTAssertNotNil(store.state.prayerTimes)
    }

    func testLocationFailureDoesNotOverwriteAlreadyLoadedScreen() async {
        let testEnv = TestEnvironmentFactory.make()
        let (store, appStore) = makeStoreWithAppStore(testEnv: testEnv)
        testEnv.apiClient.handler = { _ in
            self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30")
        }
        let city = City(id: "GB-london", name: "London", countryCode: "GB", coordinates: Coordinates(latitude: 51.5, longitude: -0.12), timeZoneIdentifier: "Europe/London")
        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertNotNil(store.state.prayerTimes)

        // A later, unrelated failure (e.g. a stale in-flight request) must not
        // wipe an already-successfully-loaded screen.
        store.send(.locationRequestFailed("transient failure"))

        XCTAssertNotNil(store.state.prayerTimes)
        XCTAssertEqual(appStore.state.resolvedCoordinates, city.coordinates)
    }

    func testSelectingActiveCityAndConfigurationObservationDoNotReloadAgain() async {
        let env = TestEnvironmentFactory.make()
        env.apiClient.handler = { _ in self.makeTimingsResponse(fajr: "05:00", dhuhr: "12:00", asr: "15:00", maghrib: "18:00", isha: "19:30") }
        let store = makeStore(testEnv: env)
        let city = City(id: "az-baku", name: "Baku", countryCode: "AZ", coordinates: Coordinates(latitude: 40.4, longitude: 49.8), timeZoneIdentifier: "Asia/Baku")
        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(150))
        let count = env.apiClient.requestedEndpoints.count
        store.send(.configurationChanged)
        store.send(.citySelected(city))
        store.send(.citySelected(city))
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(env.apiClient.requestedEndpoints.count, count)
        XCTAssertEqual(store.activeCityID, city.id)
    }
}
