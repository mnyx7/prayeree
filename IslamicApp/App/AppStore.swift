//
//  AppStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import Observation
import UserNotifications

/// Owns AppState and is the only thing that mutates it. Feature Stores never
/// write AppState directly or call each other — they call `send` here, which
/// keeps cross-feature coordination (e.g. "location changed") in one place
/// instead of scattered Store-to-Store calls. That includes notification
/// rescheduling (Phase 10): AppStore is the single place that reacts to
/// location/calculation-method/madhab/adjustment changes AND to Settings'
/// notification-preference changes (via `.notificationPreferencesChanged`)
/// by recomputing the rolling prayer-notification window.
@Observable
@MainActor
final class AppStore {
    private(set) var state: AppState
    private(set) var favoriteCities: [City]
    private(set) var recentCities: [City]
    private(set) var scheduledNotificationCount = 0
    private let environment: AppEnvironment
    private let prayerTimesRepository: any PrayerTimesRepositoryProtocol
    private static let storageKey = "app.state.v1"
    private static let rollingWindowDays = 7
    private static let dailyAyahReminderTime = DateComponents(hour: 8, minute: 0)

    private var rescheduleTask: Task<Void, Never>?

    enum Action: Sendable {
        case favoriteCityToggled(City)
        case favoriteCitiesReordered([City])
        case appLaunched
        case locationSourceModeChanged(LocationSourceMode)
        case coordinatesResolved(Coordinates)
        case cityResolved(City)
        case appearanceModeChanged(AppAppearanceMode)
        case calculationMethodChanged(PrayerCalculationMethod)
        case madhabChanged(MadhabOption)
        case prayerAdjustmentChanged(PrayerAdjustment)
        case notificationAuthorizationStatusChanged(UNAuthorizationStatus)
        /// Dispatched by SettingsStore after it persists a prayer-toggle,
        /// sound, or daily-Quran-reminder change — triggers a reschedule
        /// without AppState needing to store those Settings-local values.
        case notificationPreferencesChanged
    }

    init(environment: AppEnvironment) {
        self.environment = environment
        self.prayerTimesRepository = PrayerTimesRepository(
            service: PrayerTimesService(apiClient: environment.apiClient),
            cacheStore: environment.cacheStore
        )
        self.favoriteCities = environment.preferencesStore.value(for: "prayerTimes.favoriteCities", as: [City].self) ?? []
        self.recentCities = environment.preferencesStore.value(for: "prayerTimes.recentCities", as: [City].self) ?? []
        self.state = environment.preferencesStore.value(for: Self.storageKey, as: AppState.self) ?? .initial
        if environment.preferencesStore.value(for: "cities.sharedFavorites.v1", as: Bool.self) != true {
            if case .manual(_, let city) = state.locationSourceMode,
               !favoriteCities.contains(where: { $0.id == city.id }) {
                favoriteCities.append(city)
                persistCities()
            }
            environment.preferencesStore.setValue(true, for: "cities.sharedFavorites.v1")
        }
    }

    func send(_ action: Action) {
        switch action {
        case .favoriteCityToggled(let city):
            if favoriteCities.contains(where: { $0.id == city.id }) {
                favoriteCities.removeAll { $0.id == city.id }
            } else {
                favoriteCities.append(city)
            }
            persistCities()

        case .favoriteCitiesReordered(let cities):
            guard Set(cities.map(\.id)) == Set(favoriteCities.map(\.id)), cities.count == favoriteCities.count else { return }
            favoriteCities = cities
            persistCities()

        case .appLaunched:
            environment.widgetPublisher?.publishPrayers(state: state)
            Task { await refreshNotificationAuthorizationStatus() }

        case .locationSourceModeChanged(let mode):
            guard state.locationSourceMode != mode else {
                if case .manual(_, let city) = mode,
                   !favoriteCities.contains(where: { $0.id == city.id }) {
                    favoriteCities.append(city)
                    persistCities()
                }
                return
            }
            state.locationSourceMode = mode
            switch mode {
            case .automatic:
                break // resolvedCoordinates is updated separately once GPS resolves
            case .manual(let country, let city):
                state.selectedCountry = country
                state.selectedCity = city
                state.resolvedCoordinates = city.coordinates
                if !favoriteCities.contains(where: { $0.id == city.id }) { favoriteCities.append(city) }
                recentCities.removeAll { $0.id == city.id }
                recentCities.insert(city, at: 0)
                recentCities = Array(recentCities.prefix(5))
                persistCities()
            }
            persist()
            rescheduleNotificationsIfNeeded()

        case .cityResolved(let city):
            guard case .automatic = state.locationSourceMode else { return }
            state.selectedCity = city
            state.selectedCountry = Country(code: city.countryCode)
            recentCities.removeAll { $0.id == city.id }
            recentCities.insert(city, at: 0)
            recentCities = Array(recentCities.prefix(5))
            persistCities()
            persist()
            environment.widgetPublisher?.publishPrayers(state: state)
            if state.calculationMethod == .qmiMinber { rescheduleNotificationsIfNeeded() }

        case .coordinatesResolved(let coordinates):
            state.resolvedCoordinates = coordinates
            persist()
            rescheduleNotificationsIfNeeded()

        case .appearanceModeChanged(let mode):
            state.appearanceMode = mode
            persist()

        case .calculationMethodChanged(let method):
            state.calculationMethod = method
            persist()
            rescheduleNotificationsIfNeeded()

        case .madhabChanged(let madhab):
            state.madhab = madhab
            persist()
            rescheduleNotificationsIfNeeded()

        case .prayerAdjustmentChanged(let adjustment):
            state.prayerAdjustment = adjustment
            persist()
            rescheduleNotificationsIfNeeded()

        case .notificationAuthorizationStatusChanged(let status):
            state.notificationAuthorizationStatus = status
            if status == .authorized || status == .provisional || status == .ephemeral {
                rescheduleNotificationsIfNeeded()
            }

        case .notificationPreferencesChanged:
            rescheduleNotificationsIfNeeded()
        }
    }

    private func refreshNotificationAuthorizationStatus() async {
        let status = await environment.notificationManager.authorizationStatus()
        send(.notificationAuthorizationStatusChanged(status))
    }

    private func persistCities() {
        environment.preferencesStore.setValue(favoriteCities, for: "prayerTimes.favoriteCities")
        environment.preferencesStore.setValue(recentCities, for: "prayerTimes.recentCities")
    }

    private func persist() {
        environment.preferencesStore.setValue(state, for: Self.storageKey)
    }

    // MARK: - Notification scheduling

    /// Recomputes the rolling prayer-notification window and the daily Quran
    /// reminder from current AppState + Settings' persisted preferences.
    /// Safe to call repeatedly — cancels any in-flight reschedule first, and
    /// PrayerNotificationScheduler.reschedule itself cancels-and-replaces
    /// existing requests, so this never produces duplicates.
    private func rescheduleNotificationsIfNeeded() {
        environment.widgetPublisher?.publishPrayers(state: state)
        rescheduleTask?.cancel()
        guard [.authorized, .provisional, .ephemeral].contains(state.notificationAuthorizationStatus) else {
            // Remove queued location reminders even if iOS permission was revoked.
            rescheduleTask = Task { [weak self] in
                guard let self, !Task.isCancelled else { return }
                await self.environment.prayerNotificationScheduler.cancelAll()
                guard !Task.isCancelled else { return }
                self.scheduledNotificationCount = await self.environment.notificationManager.pendingNotificationIdentifiers().count
            }
            return
        }
        let coordinates = state.resolvedCoordinates

        let timeZoneIdentifier: String
        if case .manual(_, let city) = state.locationSourceMode {
            timeZoneIdentifier = city.timeZoneIdentifier
        } else {
            timeZoneIdentifier = TimeZone.current.identifier
        }
        let calculationMethod = state.calculationMethod
        let timetableCity = state.selectedCity
        let madhab = state.madhab
        let adjustment = state.prayerAdjustment
        let prayerPreference = environment.preferencesStore.value(
            for: SettingsStore.prayerNotificationKey,
            as: PrayerNotificationPreference.self
        ) ?? .allEnabled
        let soundName = environment.preferencesStore.value(for: SettingsStore.notificationSoundKey, as: String.self)
        let isQuranReminderEnabled = environment.preferencesStore.value(
            for: SettingsStore.quranNotificationKey,
            as: Bool.self
        ) ?? false

        rescheduleTask = Task { [weak self] in
            guard let self else { return }
            if let coordinates {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
                var prayerTimesByDate: [PrayerTimes] = []
                for dayOffset in 0..<Self.rollingWindowDays {
                    guard !Task.isCancelled else { return }
                    guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    if let prayerTimes = await self.latestPrayerTimes(
                        dateComponents: components,
                        coordinates: coordinates,
                        calculationMethod: calculationMethod,
                        madhab: madhab,
                        adjustment: adjustment,
                        timeZoneIdentifier: timeZoneIdentifier,
                        city: timetableCity
                    ) {
                        prayerTimesByDate.append(prayerTimes)
                        if calculationMethod == .qmiMinber { self.environment.widgetPublisher?.publishPrayerTimes(prayerTimes) }
                    }
                }
                guard !Task.isCancelled else { return }
    
                await self.environment.prayerNotificationScheduler.reschedule(
                    for: prayerTimesByDate,
                    preference: prayerPreference,
                    soundName: soundName,
                    content: { prayerName in
                        let displayName = String(localized: LocalizedKey.PrayerName.displayName(for: prayerName))
                        return (
                            title: String(localized: LocalizedKey.PrayerTimes.notificationTitle(prayer: displayName)),
                            body: String(localized: LocalizedKey.PrayerTimes.notificationBody(prayer: displayName))
                        )
                    }
                )
                await self.environment.prayerNotificationScheduler.rescheduleSunrise(
                    for: prayerTimesByDate,
                    isEnabled: prayerPreference.isSunriseEnabled,
                    soundName: soundName,
                    content: {
                        (title: String(localized: LocalizedKey.PrayerTimes.sunrise),
                         body: String(localized: LocalizedKey.PrayerTimes.sunriseNotificationBody))
                    }
                )
            } else {
                await self.environment.prayerNotificationScheduler.cancelAll()
            }
            guard !Task.isCancelled else { return }

            if isQuranReminderEnabled {
                await self.environment.quranNotificationScheduler.scheduleDailyReminder(
                    at: Self.dailyAyahReminderTime,
                    title: String(localized: LocalizedKey.Quran.ayahOfTheDay),
                    body: String(localized: LocalizedKey.Quran.dailyNotificationBody),
                    soundName: soundName
                )
            } else {
                await self.environment.quranNotificationScheduler.cancelDailyReminder()
            }
            self.scheduledNotificationCount = await self.environment.notificationManager.pendingNotificationIdentifiers().count
        }
    }

    /// Drains the repository's cache-then-network stream and keeps the last
    /// successful value — the fresh one if the network succeeded, otherwise
    /// the cached fallback. Returns nil only if neither was ever available.
    private func latestPrayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment,
        timeZoneIdentifier: String,
        city: City?
    ) async -> PrayerTimes? {
        if let local = LocalPrayerTimesCalculator.calculate(dateComponents: dateComponents,
            coordinates: coordinates, calculationMethod: calculationMethod, madhab: madhab,
            adjustment: adjustment, timeZoneIdentifier: timeZoneIdentifier) {
            return local
        }
        var best: PrayerTimes?
        let stream = prayerTimesRepository.prayerTimes(
            dateComponents: dateComponents,
            coordinates: coordinates,
            calculationMethod: calculationMethod,
            madhab: madhab,
            adjustment: adjustment,
            city: city,
            timeZoneIdentifier: timeZoneIdentifier
        )
        for await result in stream {
            if let value = result.prayerTimes {
                best = value
            }
        }
        return best
    }
}
