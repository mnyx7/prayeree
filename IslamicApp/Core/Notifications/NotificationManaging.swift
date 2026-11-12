import UserNotifications

@MainActor
protocol NotificationManaging: AnyObject {
    func requestAuthorization() async throws -> Bool
    func authorizationStatus() async -> UNAuthorizationStatus
    func schedule(
        identifier: String,
        title: String,
        body: String,
        sound: UNNotificationSound?,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws
    func cancelNotifications(withIdentifiers identifiers: [String]) async
    func pendingNotificationIdentifiers() async -> [String]
}
