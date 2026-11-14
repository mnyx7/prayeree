//
//  SettingsStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

@MainActor
final class SettingsStoreTests: XCTestCase {
    private func makeStore(testEnv: TestEnvironment) -> SettingsStore {
        let appStore = AppStore(environment: testEnv.environment)
        return SettingsStore(
            appStore: appStore,
            preferencesStore: testEnv.preferencesStore,
            notificationManager: testEnv.notificationManager,
            locationManager: testEnv.locationManager
        )
    }

    func testLocationModeChangedToManualUpdatesAppStoreState() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let city = City(id: "AE-dubai", name: "Dubai", countryCode: "AE", coordinates: Coordinates(latitude: 25.2, longitude: 55.3), timeZoneIdentifier: "Asia/Dubai")
        let country = Country(code: "AE")

        store.send(.locationModeChanged(.manual(country: country, city: city)))

        XCTAssertEqual(store.selectedCity, city)
        XCTAssertEqual(store.locationSourceMode, .manual(country: country, city: city))
    }

    func testAppearanceModeChangedUpdatesAppStoreState() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)

        store.send(.appearanceModeChanged(.dark))

        XCTAssertEqual(store.appearanceMode, .dark)
    }

    func testPrayerNotificationToggledFlipsAndPersists() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        XCTAssertTrue(store.state.prayerNotificationPreference.isEnabled(.fajr))

        store.send(.prayerNotificationToggled(.fajr))

        XCTAssertFalse(store.state.prayerNotificationPreference.isEnabled(.fajr))
        XCTAssertEqual(
            testEnv.preferencesStore.value(for: "settings.prayerNotificationPreference", as: PrayerNotificationPreference.self)?.isEnabled(.fajr),
            false
        )
    }

    func testQuranNotificationToggledFlipsAndPersists() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        XCTAssertFalse(store.state.dailyQuranNotificationEnabled)

        store.send(.quranNotificationToggled)

        XCTAssertTrue(store.state.dailyQuranNotificationEnabled)
        XCTAssertEqual(testEnv.preferencesStore.value(for: "settings.dailyQuranNotificationEnabled", as: Bool.self), true)
    }

    func testTestNotificationRequestedSchedulesNotification() async {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)

        store.send(.testNotificationRequested)
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertTrue(testEnv.notificationManager.scheduledIdentifiers.contains("test.notification"))
    }

    func testCitySelectedSavesFavoriteAndKeepsSearchResultsStable() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let city = City(id: "TR-istanbul", name: "Istanbul", countryCode: "TR", coordinates: Coordinates(latitude: 41.0, longitude: 28.9), timeZoneIdentifier: "Europe/Istanbul")

        store.send(.citySearchQueryChanged("Istanbul"))
        store.send(.citySelected(city))

        XCTAssertEqual(store.recentCities.first, city)
        XCTAssertEqual(store.state.citySearchQuery, "Istanbul")
        XCTAssertEqual(store.favoriteCities.first, city)
    }

    func testEnablingQuranReminderRequestsPermissionAndSchedulesWithoutLocation() async {
        let env = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: env)
        store.send(.quranNotificationToggled)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(env.notificationManager.authorizationRequestCount, 1)
        XCTAssertTrue(env.notificationManager.scheduledIdentifiers.contains("quran.dailyAyah"))
    }

    func testDeniedPermissionProvidesFeedbackInsteadOfPretendingTestWasSent() async {
        let env = TestEnvironmentFactory.make()
        env.notificationManager.stubbedAuthorizationStatus = .denied
        let store = makeStore(testEnv: env)
        store.send(.testNotificationRequested)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertFalse(env.notificationManager.scheduledIdentifiers.contains("test.notification"))
        XCTAssertNotNil(store.state.notificationFeedback)
        XCTAssertEqual(env.notificationManager.authorizationRequestCount, 0)
    }

    func testTestNotificationSchedulingFailureProvidesFeedback() async {
        let env = TestEnvironmentFactory.make()
        env.notificationManager.stubbedAuthorizationStatus = .authorized
        env.notificationManager.schedulingError = NetworkError.httpStatus(500)
        let store = makeStore(testEnv: env)
        store.send(.testNotificationRequested)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertNotNil(store.state.notificationFeedback)
        XCTAssertFalse(store.state.isSendingTestNotification)
        XCTAssertFalse(env.notificationManager.scheduledIdentifiers.contains("test.notification"))
    }
}
