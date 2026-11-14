//
//  AppStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

@MainActor
final class AppStoreTests: XCTestCase {
    func testAppearanceModeChangedUpdatesStateImmediately() {
        let testEnv = TestEnvironmentFactory.make()
        let store = AppStore(environment: testEnv.environment)

        store.send(.appearanceModeChanged(.dark))

        XCTAssertEqual(store.state.appearanceMode, .dark)
    }

    func testAppearanceModePersistsAcrossStoreInstances() {
        let testEnv = TestEnvironmentFactory.make()
        let firstStore = AppStore(environment: testEnv.environment)
        firstStore.send(.appearanceModeChanged(.dark))

        // A second AppStore reading the same PreferencesStore should pick up
        // the persisted value rather than falling back to `.initial`.
        let secondStore = AppStore(environment: testEnv.environment)

        XCTAssertEqual(secondStore.state.appearanceMode, .dark)
    }

    func testCalculationSettingsPersistAcrossStoreInstances() {
        let testEnv = TestEnvironmentFactory.make()
        let firstStore = AppStore(environment: testEnv.environment)
        firstStore.send(.calculationMethodChanged(.karachi))
        firstStore.send(.madhabChanged(.hanafi))

        let secondStore = AppStore(environment: testEnv.environment)

        XCTAssertEqual(secondStore.state.calculationMethod, .karachi)
        XCTAssertEqual(secondStore.state.madhab, .hanafi)
    }

    func testNotificationAuthorizationStatusIsNeverPersisted() {
        let testEnv = TestEnvironmentFactory.make()
        let firstStore = AppStore(environment: testEnv.environment)
        firstStore.send(.notificationAuthorizationStatusChanged(.authorized))
        XCTAssertEqual(firstStore.state.notificationAuthorizationStatus, .authorized)

        // A fresh launch always re-queries the OS rather than trusting a
        // cached value that could have gone stale in system Settings.
        let secondStore = AppStore(environment: testEnv.environment)

        XCTAssertEqual(secondStore.state.notificationAuthorizationStatus, .notDetermined)
    }

    func testLocationSourceModeChangedToManualUpdatesCityCountryAndCoordinates() {
        let testEnv = TestEnvironmentFactory.make()
        let store = AppStore(environment: testEnv.environment)
        let city = City(id: "JP-tokyo", name: "Tokyo", countryCode: "JP", coordinates: Coordinates(latitude: 35.6, longitude: 139.6), timeZoneIdentifier: "Asia/Tokyo")
        let country = Country(code: "JP")

        store.send(.locationSourceModeChanged(.manual(country: country, city: city)))

        XCTAssertEqual(store.state.selectedCity, city)
        XCTAssertEqual(store.state.selectedCountry, country)
        XCTAssertEqual(store.state.resolvedCoordinates, city.coordinates)
        XCTAssertEqual(store.state.locationSourceMode, .manual(country: country, city: city))
    }

    func testLocationSourceModeChangedToAutomaticDoesNotClearExistingCoordinates() {
        let testEnv = TestEnvironmentFactory.make()
        let store = AppStore(environment: testEnv.environment)
        let city = City(id: "JP-tokyo", name: "Tokyo", countryCode: "JP", coordinates: Coordinates(latitude: 35.6, longitude: 139.6), timeZoneIdentifier: "Asia/Tokyo")
        store.send(.locationSourceModeChanged(.manual(country: Country(code: "JP"), city: city)))

        store.send(.locationSourceModeChanged(.automatic))

        XCTAssertEqual(store.state.locationSourceMode, .automatic)
        // Coordinates are only replaced once a fresh GPS fix resolves
        // (.coordinatesResolved), not wiped out just by switching modes.
        XCTAssertEqual(store.state.resolvedCoordinates, city.coordinates)
    }

    func testCoordinatesResolvedUpdatesState() {
        let testEnv = TestEnvironmentFactory.make()
        let store = AppStore(environment: testEnv.environment)
        let coordinates = Coordinates(latitude: 1.35, longitude: 103.8)

        store.send(.coordinatesResolved(coordinates))

        XCTAssertEqual(store.state.resolvedCoordinates, coordinates)
    }

    func testFavoritesAreSharedAcrossSettingsAndPrayerTimesAndPersisted() {
        let env = TestEnvironmentFactory.make()
        let app = AppStore(environment: env.environment)
        let settings = SettingsStore(appStore: app, preferencesStore: env.preferencesStore,
            notificationManager: env.notificationManager, locationManager: env.locationManager)
        let prayers = PrayerTimesStore(appStore: app,
            repository: PrayerTimesRepository(service: PrayerTimesService(apiClient: env.apiClient), cacheStore: env.cacheStore),
            locationManager: env.locationManager, preferencesStore: env.preferencesStore)
        let city = City(id: "az-baku", name: "Baku", countryCode: "AZ",
            coordinates: Coordinates(latitude: 40.4093, longitude: 49.8671), timeZoneIdentifier: "Asia/Baku")
        settings.send(.citySelected(city))
        settings.send(.citySelected(city))
        XCTAssertEqual(prayers.favoriteCities, [city])
        XCTAssertEqual(prayers.selectedCity, city)
        XCTAssertEqual(AppStore(environment: env.environment).favoriteCities, [city])
        prayers.send(.favoriteToggled(city))
        XCTAssertTrue(settings.favoriteCities.isEmpty)
        XCTAssertTrue(AppStore(environment: env.environment).favoriteCities.isEmpty)
    }

    func testReorderFavoritesPersistsAndRejectsUnrelatedCities() {
        let env = TestEnvironmentFactory.make()
        let app = AppStore(environment: env.environment)
        let a = City(id: "a", name: "A", countryCode: "AZ", coordinates: Coordinates(latitude: 40, longitude: 49), timeZoneIdentifier: "Asia/Baku")
        let b = City(id: "b", name: "B", countryCode: "AZ", coordinates: Coordinates(latitude: 41, longitude: 49), timeZoneIdentifier: "Asia/Baku")
        app.send(.favoriteCityToggled(a))
        app.send(.favoriteCityToggled(b))
        app.send(.favoriteCitiesReordered([b, a]))
        XCTAssertEqual(AppStore(environment: env.environment).favoriteCities, [b, a])
        app.send(.favoriteCitiesReordered([a, a]))
        XCTAssertEqual(app.favoriteCities, [b, a])
    }

    func testProvisionalAuthorizationSchedulesPrayerRemindersWithoutNetwork() async {
        let env = TestEnvironmentFactory.make()
        let app = AppStore(environment: env.environment)
        app.send(.coordinatesResolved(Coordinates(latitude: 40.4093, longitude: 49.8671)))
        app.send(.notificationAuthorizationStatusChanged(.provisional))
        try? await Task.sleep(for: .milliseconds(200))
        let prayers = env.notificationManager.scheduledIdentifiers.filter { $0.hasPrefix("prayer.") }
        XCTAssertGreaterThan(prayers.count, 25)
        XCTAssertLessThanOrEqual(prayers.count, 35)
        XCTAssertTrue(env.apiClient.requestedEndpoints.isEmpty)
    }

    func testForegroundRefreshRechecksChangedNotificationPermission() async {
        let env = TestEnvironmentFactory.make()
        let app = AppStore(environment: env.environment)
        env.preferencesStore.setValue(true, for: SettingsStore.quranNotificationKey)
        env.notificationManager.stubbedAuthorizationStatus = .authorized
        app.send(.appLaunched)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(app.state.notificationAuthorizationStatus, .authorized)
        XCTAssertTrue(env.notificationManager.scheduledIdentifiers.contains("quran.dailyAyah"))
    }
}
