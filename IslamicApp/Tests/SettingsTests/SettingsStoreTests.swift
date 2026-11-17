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
    func testLanguagePreferenceUpdatesResourcesAndLayoutDirection() {
        let key = LocalizationManager.languagePreferenceKey
        let original = UserDefaults.standard.object(forKey: key)
        defer {
            if let original { UserDefaults.standard.set(original, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }

        for language in ["en", "ar", "ru", "az"] {
            UserDefaults.standard.set(language, forKey: key)
            XCTAssertEqual(LocalizationManager.locale.identifier, language)
            XCTAssertEqual(LocalizedKey.Settings.language.locale.identifier, language)
            XCTAssertEqual(LocalizationManager.isRightToLeft, language == "ar")
        }

        for preference in ["", "unsupported"] {
            UserDefaults.standard.set(preference, forKey: key)
            XCTAssertEqual(LocalizationManager.locale, Locale.current)
        }
    }

    func testSunrisePreferencePersistsWithoutChangingPrayerPreferences() {
        let environment = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: environment)
        let prayers = store.state.prayerNotificationPreference.enabledByPrayer
        XCTAssertFalse(store.state.prayerNotificationPreference.isSunriseEnabled)
        store.send(.sunriseNotificationToggled)
        XCTAssertTrue(store.state.prayerNotificationPreference.isSunriseEnabled)
        XCTAssertEqual(store.state.prayerNotificationPreference.enabledByPrayer, prayers)
        let restored = makeStore(testEnv: environment)
        XCTAssertTrue(restored.state.prayerNotificationPreference.isSunriseEnabled)
        restored.send(.sunriseNotificationToggled)
        XCTAssertFalse(environment.preferencesStore.value(for: SettingsStore.prayerNotificationKey, as: PrayerNotificationPreference.self)!.isSunriseEnabled)
    }

    func testEnablingSunriseRequestsPermissionAndSchedulesFromSelectedSource() async {
        let environment = TestEnvironmentFactory.make()
        let appStore = AppStore(environment: environment.environment)
        let store = SettingsStore(appStore: appStore, preferencesStore: environment.preferencesStore,
                                  notificationManager: environment.notificationManager, locationManager: environment.locationManager)
        let city = City(id: "az-baku", name: "Baku", countryCode: "AZ", coordinates: Coordinates(latitude: 40.4093, longitude: 49.8671), timeZoneIdentifier: "Asia/Baku")
        store.send(.citySelected(city))
        store.send(.sunriseNotificationToggled)
        try? await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(environment.notificationManager.authorizationRequestCount, 1)
        XCTAssertTrue(environment.notificationManager.scheduledIdentifiers.contains { $0.hasPrefix("sunrise.") })
        store.send(.sunriseNotificationToggled)
        try? await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(environment.notificationManager.scheduledIdentifiers.contains { $0.hasPrefix("sunrise.") })
        XCTAssertTrue(environment.notificationManager.scheduledIdentifiers.contains { $0.hasPrefix("prayer.") })
    }

    func testSunriseOffCancelsPendingAlertAfterPermissionRevocation() async throws {
        let environment = TestEnvironmentFactory.make()
        environment.notificationManager.stubbedAuthorizationStatus = .denied
        var preference = PrayerNotificationPreference.allEnabled
        preference.isSunriseEnabled = true
        environment.preferencesStore.setValue(preference, for: SettingsStore.prayerNotificationKey)
        let store = makeStore(testEnv: environment)
        try await environment.notificationManager.schedule(identifier: "sunrise.20261118", title: "Sunrise", body: "", sound: nil, dateComponents: DateComponents(), repeats: false)
        try await environment.notificationManager.schedule(identifier: "quran.dailyAyah", title: "Quran", body: "", sound: nil, dateComponents: DateComponents(), repeats: true)
        store.send(.sunriseNotificationToggled)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertFalse(environment.notificationManager.scheduledIdentifiers.contains { $0.hasPrefix("sunrise.") })
        XCTAssertTrue(environment.notificationManager.scheduledIdentifiers.contains("quran.dailyAyah"))
        XCTAssertEqual(environment.notificationManager.authorizationRequestCount, 0)
    }

    private func makeStore(testEnv: TestEnvironment) -> SettingsStore {
        let appStore = AppStore(environment: testEnv.environment)
        return SettingsStore(
            appStore: appStore,
            preferencesStore: testEnv.preferencesStore,
            notificationManager: testEnv.notificationManager,
            locationManager: testEnv.locationManager
        )
    }

    func testMinberSelectionPreservesMadhabAndExistingMethodPreferences() {
        let environment = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: environment)
        store.send(.madhabChanged(.hanafi))
        store.send(.calculationMethodChanged(.qmiMinber))
        XCTAssertEqual(store.calculationMethod, .qmiMinber)
        XCTAssertEqual(store.madhab, .hanafi)
        let restored = AppStore(environment: environment.environment)
        XCTAssertEqual(restored.state.calculationMethod, .qmiMinber)
        XCTAssertEqual(restored.state.madhab, .hanafi)
        store.send(.calculationMethodChanged(.muslimWorldLeague))
        XCTAssertEqual(store.madhab, .hanafi)
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
