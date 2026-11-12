import Foundation
@testable import IslamicApp
import Foundation

/// Bundles a real AppEnvironment (so Stores under test see the exact same
/// composition-root shape production code does) with direct references to
/// each mock, so tests can configure/inspect them without downcasting.
/// Shared across Store test files to avoid repeating this 9-parameter
/// construction in every one.
struct TestEnvironment {
    let environment: AppEnvironment
    let apiClient: MockAPIClient
    let cacheStore: InMemoryCacheStore
    let preferencesStore: InMemoryPreferencesStore
    let locationManager: MockLocationManager
    let compassManager: MockCompassManager
    let notificationManager: MockNotificationManager
}

@MainActor
enum TestEnvironmentFactory {
    static func make() -> TestEnvironment {
        let apiClient = MockAPIClient()
        let cacheStore = InMemoryCacheStore()
        let preferencesStore = InMemoryPreferencesStore()
        let locationManager = MockLocationManager()
        let compassManager = MockCompassManager()
        let notificationManager = MockNotificationManager()
        let environment = AppEnvironment(
            apiClient: apiClient,
            cacheStore: cacheStore,
            preferencesStore: preferencesStore,
            locationManager: locationManager,
            compassManager: compassManager,
            qiblaCalculator: QiblaCalculator(),
            notificationManager: notificationManager,
            prayerNotificationScheduler: PrayerNotificationScheduler(notificationManager: notificationManager),
            quranNotificationScheduler: QuranNotificationScheduler(notificationManager: notificationManager)
        )
        return TestEnvironment(
            environment: environment,
            apiClient: apiClient,
            cacheStore: cacheStore,
            preferencesStore: preferencesStore,
            locationManager: locationManager,
            compassManager: compassManager,
            notificationManager: notificationManager
        )
    }
}
