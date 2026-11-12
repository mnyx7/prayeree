import Foundation
import CoreLocation
import UserNotifications

/// Builds an AppEnvironment safe for SwiftUI canvas previews: no network
/// calls, no real location/notification permission prompts.
///
/// These fakes are intentionally separate from Tests/TestSupport's mocks —
/// this file compiles into the app target (so Previews can see it), while
/// TestSupport compiles into the test target only. They also serve different
/// purposes: these just need to render harmlessly, while TestSupport's mocks
/// support configurable stubs and call-count assertions.
@MainActor
enum PreviewEnvironmentFactory {
    static func make() -> AppEnvironment {
        let notificationManager = PreviewNotificationManager()
        let previewDefaults = UserDefaults(suiteName: "com.islamicapp.preview") ?? .standard
        let previewCacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PreviewCache", isDirectory: true)

        return AppEnvironment(
            apiClient: PreviewAPIClient(),
            cacheStore: FileCacheStore(directory: previewCacheDirectory),
            preferencesStore: UserDefaultsPreferencesStore(defaults: previewDefaults),
            locationManager: PreviewLocationManager(),
            compassManager: PreviewCompassManager(),
            qiblaCalculator: QiblaCalculator(),
            notificationManager: notificationManager,
            prayerNotificationScheduler: PrayerNotificationScheduler(notificationManager: notificationManager),
            quranNotificationScheduler: QuranNotificationScheduler(notificationManager: notificationManager)
        )
    }
}

private struct PreviewAPIClient: APIClientProtocol {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, decodingTo type: Response.Type) async throws -> Response {
        throw NetworkError.invalidResponse
    }
}

@MainActor
private final class PreviewLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus { .authorizedWhenInUse }

    func requestWhenInUseAuthorization() async {}

    func requestCurrentLocation() async throws -> Coordinates {
        QiblaCalculator.kaaba
    }

    func reverseGeocodedCity(for coordinates: Coordinates) async throws -> City? {
        City(
            id: "SA-mecca",
            name: "Mecca",
            countryCode: "SA",
            coordinates: coordinates,
            timeZoneIdentifier: "Asia/Riyadh"
        )
    }

    func searchCities(matching query: String) async throws -> [City] {
        []
    }
}

@MainActor
private final class PreviewCompassManager: CompassManaging {
    func headingUpdates() -> AsyncStream<CompassHeading> {
        AsyncStream { continuation in
            continuation.yield(CompassHeading(magneticHeadingDegrees: 90, trueHeadingDegrees: 90, accuracyDegrees: 5))
            continuation.finish()
        }
    }

    func stopUpdatingHeading() {}
}

@MainActor
private final class PreviewNotificationManager: NotificationManaging {
    func requestAuthorization() async throws -> Bool { true }

    func authorizationStatus() async -> UNAuthorizationStatus { .authorized }

    func schedule(
        identifier: String,
        title: String,
        body: String,
        sound: UNNotificationSound?,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws {}

    func cancelNotifications(withIdentifiers identifiers: [String]) async {}

    func pendingNotificationIdentifiers() async -> [String] { [] }
}
