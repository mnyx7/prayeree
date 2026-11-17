//
//  SettingsStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import Observation
import UserNotifications
import AudioToolbox

@Observable
@MainActor
final class SettingsStore {
    struct State: Equatable, Sendable {
        var prayerNotificationPreference: PrayerNotificationPreference
        var dailyQuranNotificationEnabled: Bool
        var selectedNotificationSound: String?
        var appVersion: String
        var activeDestination: Destination?
        var errorMessage: String?
        var notificationFeedback: String? = nil
        var isSendingTestNotification: Bool
        var citySearchQuery: String
        var citySearchResults: [City]
        var isSearchingCities: Bool
    }

    enum Destination: Identifiable, Equatable, Sendable {
        case prayerCalculationSettings
        case prayerAdjustments
        case aboutUs

        var id: Self { self }
    }

    enum Action: Sendable {
        case screenAppeared
        case locationModeChanged(LocationSourceMode)
        case citySelected(City)
        case favoriteToggled(City)
        case citySearchQueryChanged(String)
        case citySearchResultsLoaded([City])
        case sunriseNotificationToggled
        case prayerNotificationToggled(PrayerName)
        case quranNotificationToggled
        case notificationPermissionRequested
        case notificationSoundSelected(String?)
        case soundPreviewRequested(String?)
        case testNotificationRequested
        case appearanceModeChanged(AppAppearanceMode)
        case calculationMethodChanged(PrayerCalculationMethod)
        case madhabChanged(MadhabOption)
        case prayerAdjustmentChanged(PrayerName, Int)
        case aboutUsTapped
        case destinationTapped(Destination)
        case destinationDismissed
    }

    private(set) var state: State
    private let appStore: AppStore
    private let preferencesStore: any PreferencesStore
    private let notificationManager: any NotificationManaging
    private let locationManager: any LocationManaging

    private var citySearchTask: Task<Void, Never>?

    // Internal (not private): AppStore reads these directly when
    // recomputing the notification schedule (Phase 10).
    static let prayerNotificationKey = "settings.prayerNotificationPreference"
    static let quranNotificationKey = "settings.dailyQuranNotificationEnabled"
    static let notificationSoundKey = "settings.notificationSoundName"

    var locationSourceMode: LocationSourceMode { appStore.state.locationSourceMode }
    var selectedCity: City? { appStore.state.selectedCity }
    var favoriteCities: [City] { appStore.favoriteCities }
    var recentCities: [City] { appStore.recentCities }
    var appearanceMode: AppAppearanceMode { appStore.state.appearanceMode }
    var calculationMethod: PrayerCalculationMethod { appStore.state.calculationMethod }
    var madhab: MadhabOption { appStore.state.madhab }
    var prayerAdjustment: PrayerAdjustment { appStore.state.prayerAdjustment }
    var scheduledNotificationCount: Int { appStore.scheduledNotificationCount }
    var notificationAuthorizationStatus: UNAuthorizationStatus { appStore.state.notificationAuthorizationStatus }

    init(
        appStore: AppStore,
        preferencesStore: any PreferencesStore,
        notificationManager: any NotificationManaging,
        locationManager: any LocationManaging
    ) {
        self.appStore = appStore
        self.preferencesStore = preferencesStore
        self.notificationManager = notificationManager
        self.locationManager = locationManager
        self.state = State(
            prayerNotificationPreference: preferencesStore.value(for: Self.prayerNotificationKey, as: PrayerNotificationPreference.self) ?? .allEnabled,
            dailyQuranNotificationEnabled: preferencesStore.value(for: Self.quranNotificationKey, as: Bool.self) ?? false,
            selectedNotificationSound: preferencesStore.value(for: Self.notificationSoundKey, as: String.self),
            appVersion: Bundle.main.formattedAppVersion,
            activeDestination: nil,
            errorMessage: nil,
            isSendingTestNotification: false,
            citySearchQuery: "",
            citySearchResults: [],
            isSearchingCities: false
        )
    }

    func send(_ action: Action) {
        switch action {
        case .screenAppeared:
            Task { [weak self] in
                guard let self else { return }
                let status = await self.notificationManager.authorizationStatus()
                self.appStore.send(.notificationAuthorizationStatusChanged(status))
            }

        case .locationModeChanged(let mode):
            appStore.send(.locationSourceModeChanged(mode))
            if case .automatic = mode {
                resolveCurrentLocation()
            }

        case .favoriteToggled(let city):
            appStore.send(.favoriteCityToggled(city))

        case .citySelected(let city):
            let country = Country(code: city.countryCode)
            appStore.send(.locationSourceModeChanged(.manual(country: country, city: city)))

        case .citySearchQueryChanged(let query):
            searchCities(matching: query)

        case .citySearchResultsLoaded(let results):
            state.citySearchResults = results
            state.isSearchingCities = false

        case .prayerNotificationToggled(let prayer):
            state.prayerNotificationPreference = state.prayerNotificationPreference.toggling(prayer)
            preferencesStore.setValue(state.prayerNotificationPreference, for: Self.prayerNotificationKey)
            appStore.send(.notificationPreferencesChanged)
            if state.prayerNotificationPreference.isEnabled(prayer) { requestNotificationPermissionIfNeeded() }

        case .sunriseNotificationToggled:
            state.prayerNotificationPreference.isSunriseEnabled.toggle()
            preferencesStore.setValue(state.prayerNotificationPreference, for: Self.prayerNotificationKey)
            appStore.send(.notificationPreferencesChanged)
            if state.prayerNotificationPreference.isSunriseEnabled { requestNotificationPermissionIfNeeded() }

        case .quranNotificationToggled:
            state.dailyQuranNotificationEnabled.toggle()
            preferencesStore.setValue(state.dailyQuranNotificationEnabled, for: Self.quranNotificationKey)
            appStore.send(.notificationPreferencesChanged)
            if state.dailyQuranNotificationEnabled { requestNotificationPermissionIfNeeded() }

        case .notificationPermissionRequested:
            requestNotificationPermissionIfNeeded()

        case .notificationSoundSelected(let soundName):
            state.selectedNotificationSound = soundName
            preferencesStore.setValue(soundName, for: Self.notificationSoundKey)
            appStore.send(.notificationPreferencesChanged)

        case .soundPreviewRequested:
            // V1 ships no bundled custom sound assets (see Core/Notifications
            // documentation) — this plays a representative system sound rather
            // than a real notification sound file.
            AudioServicesPlaySystemSound(1007)

        case .testNotificationRequested:
            sendTestNotification()

        case .appearanceModeChanged(let mode):
            appStore.send(.appearanceModeChanged(mode))

        case .calculationMethodChanged(let method):
            appStore.send(.calculationMethodChanged(method))

        case .madhabChanged(let madhab):
            appStore.send(.madhabChanged(madhab))

        case .prayerAdjustmentChanged(let prayer, let minutes):
            let updated = appStore.state.prayerAdjustment.adjusting(prayer, byMinutes: minutes)
            appStore.send(.prayerAdjustmentChanged(updated))

        case .aboutUsTapped:
            state.activeDestination = .aboutUs

        case .destinationTapped(let destination):
            state.activeDestination = destination

        case .destinationDismissed:
            state.activeDestination = nil
        }
    }

    // MARK: - Location

    private func resolveCurrentLocation() {
        Task { [weak self] in
            guard let self else { return }
            await self.locationManager.requestWhenInUseAuthorization()
            guard let coordinates = try? await self.locationManager.requestCurrentLocation(),
                  case .automatic = self.locationSourceMode else { return }
            self.appStore.send(.coordinatesResolved(coordinates))
            if let city = try? await self.locationManager.reverseGeocodedCity(for: coordinates) {
                self.appStore.send(.cityResolved(city))
            }
        }
    }

    private func searchCities(matching query: String) {
        state.citySearchQuery = query
        citySearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state.citySearchResults = []
            state.isSearchingCities = false
            return
        }
        state.isSearchingCities = true
        citySearchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled else { return }
            let results = (try? await self.locationManager.searchCities(matching: trimmed)) ?? []
            guard !Task.isCancelled else { return }
            self.send(.citySearchResultsLoaded(results))
        }
    }


    // MARK: - Notifications


    private func requestNotificationPermissionIfNeeded() {
        Task { [weak self] in
            guard let self else { return }
            do { _ = try await self.ensureNotificationAuthorization() }
            catch { self.state.notificationFeedback = String(localized: LocalizedKey.Settings.notificationFailed) }
        }
    }

    private func ensureNotificationAuthorization() async throws -> Bool {
        var status = await notificationManager.authorizationStatus()
        if status == .notDetermined {
            _ = try await notificationManager.requestAuthorization()
            status = await notificationManager.authorizationStatus()
        }
        appStore.send(.notificationAuthorizationStatusChanged(status))
        let allowed = [.authorized, .provisional, .ephemeral].contains(status)
        if !allowed { state.notificationFeedback = String(localized: LocalizedKey.Settings.notificationPermissionNeeded) }
        return allowed
    }

    private func sendTestNotification() {
        guard !state.isSendingTestNotification else { return }
        state.isSendingTestNotification = true
        state.notificationFeedback = nil
        Task { [weak self] in
            guard let self else { return }
            defer { self.state.isSendingTestNotification = false }
            do {
                guard try await self.ensureNotificationAuthorization() else { return }
                let sound = self.state.selectedNotificationSound.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
                let fireDate = Date().addingTimeInterval(5)
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
                components.timeZone = .current
                try await self.notificationManager.schedule(
                    identifier: "test.notification",
                    title: String(localized: LocalizedKey.Settings.testNotificationTitle),
                    body: String(localized: LocalizedKey.Settings.testNotificationBody),
                    sound: sound, dateComponents: components, repeats: false
                )
                self.state.notificationFeedback = String(localized: LocalizedKey.Settings.testNotificationScheduled)
            } catch {
                self.state.notificationFeedback = String(localized: LocalizedKey.Settings.notificationFailed)
            }
        }
    }
}
