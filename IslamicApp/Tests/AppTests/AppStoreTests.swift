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

    func testWidgetSnapshotsRoundTripAndAvoidDuplicateWrites() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WidgetTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let shared = WidgetFileStore(directory: directory)
        let reading = WidgetReadingSnapshot(surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 25, versesCount: 286)
        XCTAssertTrue(shared.write(reading, named: "reading"))
        XCTAssertFalse(shared.write(reading, named: "reading"))
        XCTAssertTrue(shared.write(WidgetQuranPreferences(), named: "quranPreferences"))
        XCTAssertEqual(shared.read("reading", as: WidgetReadingSnapshot.self), reading)
        XCTAssertEqual(try XCTUnwrap(shared.read("quranPreferences", as: WidgetQuranPreferences.self)).translationID, 20)
    }

    func testMissingAppGroupFailsGracefully() {
        let shared = WidgetFileStore(directory: nil)
        XCTAssertNil(shared.read("reading", as: WidgetReadingSnapshot.self))
        XCTAssertFalse(shared.write(WidgetQuranPreferences(), named: "quranPreferences"))
    }

    func testWidgetPrayerForecastUsesSelectedCityAndContainsSevenDays() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WidgetPrayers-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let shared = WidgetFileStore(directory: directory)
        let publisher = AppWidgetPublisher(store: shared, reload: { _ in })
        var state = AppState.initial
        let city = City(id: "az-baku", name: "Baku", countryCode: "AZ", coordinates: Coordinates(latitude: 40.4093, longitude: 49.8671), timeZoneIdentifier: "Asia/Baku")
        state.selectedCity = city
        state.locationSourceMode = .manual(country: Country(code: "AZ"), city: city)
        state.resolvedCoordinates = city.coordinates
        publisher.publishPrayers(state: state)
        let snapshot = try XCTUnwrap(shared.read("prayers", as: WidgetPrayerSnapshot.self))
        XCTAssertEqual(snapshot.cityName, "Baku")
        XCTAssertEqual(snapshot.timeZoneIdentifier, "Asia/Baku")
        XCTAssertEqual(snapshot.days.count, 7)
        XCTAssertEqual(snapshot.days.flatMap(\.prayers).count, 35)
        let first = try XCTUnwrap(snapshot.days.first?.prayers.first)
        XCTAssertNotEqual(snapshot.nextPrayer(after: first.date)?.date, first.date)
        let last = try XCTUnwrap(snapshot.days.last?.prayers.last)
        XCTAssertNil(snapshot.nextPrayer(after: last.date))
        XCTAssertTrue(snapshot.timelineDates(from: first.date.addingTimeInterval(-60)).contains(snapshot.days[1].date), "The medium widget must switch schedules at midnight")
    }

    func testDailyWidgetNeverTreatsYesterdayOrAnotherTranslationAsToday() {
        let date = Date()
        let prefs = WidgetQuranPreferences()
        let value = WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(date), surahNumber: 1, ayahNumber: 1, arabicText: "آية", translation: nil, preferences: prefs)
        XCTAssertTrue(value.isCurrent(at: date, preferences: prefs))
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        XCTAssertFalse(value.isCurrent(at: tomorrow, preferences: prefs))
        XCTAssertFalse(value.isCurrent(at: date, preferences: WidgetQuranPreferences(translationID: 85, translationName: "Other", languageCode: "en")))
    }

    func testWidgetRoutesRoundTripAndRejectUntrustedOrInvalidURLs() {
        let routes: [WidgetRoute] = [.prayerTimes, .quran, .continueReading, .dailyAyah(surah: 2, ayah: 120)]
        for route in routes { XCTAssertEqual(WidgetRoute(url: route.url), route) }
        XCTAssertNil(WidgetRoute(url: URL(string: "https://continue-reading")!))
        XCTAssertNil(WidgetRoute(url: URL(string: "prayeree://unknown")!))
        XCTAssertNil(WidgetRoute(url: URL(string: "prayeree://daily-ayah?surah=999&ayah=1")!))
        XCTAssertNil(WidgetRoute(url: URL(string: "prayeree://daily-ayah?surah=1&ayah=-1")!))
    }

    func testReadingWidgetPublishesProgressImmediately() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WidgetReading-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let shared = WidgetFileStore(directory: directory)
        let publisher = AppWidgetPublisher(store: shared, reload: { _ in })
        let env = TestEnvironmentFactory.make()
        let quran = QuranStore(repository: QuranRepository(service: QuranService(apiClient: env.apiClient), cacheStore: env.cacheStore), preferencesStore: env.preferencesStore, widgetPublisher: publisher)
        let surah = Surah(id: 2, arabicName: "البقرة", transliteratedName: "Al-Baqarah", englishTranslatedName: "The Cow", versesCount: 286, revelationPlace: .madinah)
        quran.makeReaderStore(for: surah).send(.readingPositionChanged(120))
        let snapshot = try XCTUnwrap(shared.read("reading", as: WidgetReadingSnapshot.self))
        XCTAssertEqual(snapshot.surahName, "Al-Baqarah")
        XCTAssertEqual(snapshot.ayahNumber, 120)
        XCTAssertEqual(snapshot.progress, 120.0 / 286, accuracy: 0.001)
        quran.send(.widgetContinueReadingRequested)
        XCTAssertEqual(quran.state.readerRequest?.ayahNumberInSurah, 120)
        quran.send(.readerRequestHandled)
        XCTAssertNil(quran.state.readerRequest)
    }

    func testDailyWidgetFileStoreSavesReferencesButRejectsVerseText() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WidgetReference-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let shared = WidgetFileStore(directory: directory)
        let reference = WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(Date()), surahNumber: 1, ayahNumber: 1, arabicText: "", translation: nil, preferences: WidgetQuranPreferences())
        XCTAssertTrue(shared.write(reference, named: "dailyAyah"))
        let verse = WidgetAyahSnapshot(dayKey: reference.dayKey, surahNumber: 1, ayahNumber: 1, arabicText: "آية", translation: nil, preferences: WidgetQuranPreferences())
        XCTAssertFalse(shared.write(verse, named: "dailyAyah"))
        XCTAssertEqual(shared.read("dailyAyah", as: WidgetAyahSnapshot.self), reference)
    }

    func testLegacyWidgetVerseTextIsPurgedOnRead() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WidgetLegacy-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("dailyAyah.json")
        let verse = WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(Date()), surahNumber: 1, ayahNumber: 1, arabicText: "آية", translation: nil, preferences: WidgetQuranPreferences())
        try JSONEncoder().encode(verse).write(to: url)
        XCTAssertNil(WidgetFileStore(directory: directory).read("dailyAyah", as: WidgetAyahSnapshot.self))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
