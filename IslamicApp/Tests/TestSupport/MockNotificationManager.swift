//
//  MockNotificationManager.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
@testable import IslamicApp
import UserNotifications

@MainActor
final class MockNotificationManager: NotificationManaging {
    private(set) var authorizationRequestCount = 0
    var schedulingError: Error?
    var authorizationGranted = true
    var stubbedAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    struct ScheduledRequest {
        let title: String
        let body: String
        let sound: UNNotificationSound?
        let dateComponents: DateComponents
    }
    private(set) var scheduledRequests: [String: ScheduledRequest] = [:]
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
        scheduledRequests[identifier] = ScheduledRequest(title: title, body: body, sound: sound, dateComponents: dateComponents)
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) async {
        cancelledIdentifiers.append(contentsOf: identifiers)
        scheduledIdentifiers.removeAll { identifiers.contains($0) }
        for identifier in identifiers { scheduledRequests.removeValue(forKey: identifier) }
    }

    func pendingNotificationIdentifiers() async -> [String] {
        scheduledIdentifiers
    }
}
