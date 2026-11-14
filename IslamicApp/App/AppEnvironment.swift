//
//  AppEnvironment.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

/// The single place production dependencies are constructed. Stores and
/// repositories receive everything through this container's protocol-typed
/// properties — never by instantiating a concrete service themselves.
@MainActor
final class AppEnvironment {
    let apiClient: any APIClientProtocol
    let cacheStore: any CacheStore
    let preferencesStore: any PreferencesStore
    let locationManager: any LocationManaging
    let compassManager: any CompassManaging
    let qiblaCalculator: any QiblaCalculating
    let notificationManager: any NotificationManaging
    let prayerNotificationScheduler: any PrayerNotificationScheduling
    let quranNotificationScheduler: any QuranNotificationScheduling

    init(
        apiClient: any APIClientProtocol,
        cacheStore: any CacheStore,
        preferencesStore: any PreferencesStore,
        locationManager: any LocationManaging,
        compassManager: any CompassManaging,
        qiblaCalculator: any QiblaCalculating,
        notificationManager: any NotificationManaging,
        prayerNotificationScheduler: any PrayerNotificationScheduling,
        quranNotificationScheduler: any QuranNotificationScheduling
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.preferencesStore = preferencesStore
        self.locationManager = locationManager
        self.compassManager = compassManager
        self.qiblaCalculator = qiblaCalculator
        self.notificationManager = notificationManager
        self.prayerNotificationScheduler = prayerNotificationScheduler
        self.quranNotificationScheduler = quranNotificationScheduler
    }

    static func live() -> AppEnvironment {
        let notificationManager = NotificationManager()
        return AppEnvironment(
            apiClient: APIClient(),
            cacheStore: FileCacheStore(),
            preferencesStore: UserDefaultsPreferencesStore(),
            locationManager: LocationManager(),
            compassManager: CompassManager(),
            qiblaCalculator: QiblaCalculator(),
            notificationManager: notificationManager,
            prayerNotificationScheduler: PrayerNotificationScheduler(notificationManager: notificationManager),
            quranNotificationScheduler: QuranNotificationScheduler(notificationManager: notificationManager)
        )
    }
}
