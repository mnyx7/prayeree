import Foundation
@testable import IslamicApp
import UserNotifications

@MainActor
final class MockNotificationManager: NotificationManaging {
    private(set) var authorizationRequestCount = 0
    var schedulingError: Error?
    var authorizationGranted = true
    var stubbedAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    private(set) var scheduledIdentifiers: [String] = []
    private(set) var cancelledIdentifiers: [String] = []

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        stubbedAuthorizationStatus = authorizationGranted ? .authorized : .denied
        return authorizationGranted
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func schedule(
        identifier: String,
        title: String,
        body: String,
        sound: UNNotificationSound?,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws {
        if let schedulingError { throw schedulingError }
        // Mirrors UNUserNotificationCenter.add(_:): scheduling with an
        // identifier that's already pending replaces it rather than duplicating.
        scheduledIdentifiers.removeAll { $0 == identifier }
        scheduledIdentifiers.append(identifier)
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) async {
        cancelledIdentifiers.append(contentsOf: identifiers)
        scheduledIdentifiers.removeAll { identifiers.contains($0) }
    }

    func pendingNotificationIdentifiers() async -> [String] {
        scheduledIdentifiers
    }
}
