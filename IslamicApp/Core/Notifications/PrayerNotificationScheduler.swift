import Foundation
import UserNotifications

@MainActor
final class PrayerNotificationScheduler: PrayerNotificationScheduling {
    private let notificationManager: any NotificationManaging
    private static let identifierPrefix = "prayer."

    init(notificationManager: any NotificationManaging) {
        self.notificationManager = notificationManager
    }

    func reschedule(
        for prayerTimesByDate: [PrayerTimes],
        preference: PrayerNotificationPreference,
        soundName: String?,
        content: @escaping @Sendable (PrayerName) -> (title: String, body: String)
    ) async {
        guard !Task.isCancelled else { return }
        await cancelAll()
        guard !Task.isCancelled else { return }

        let sound = soundName.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
        let now = Date()

        for dayTimes in prayerTimesByDate {
            for prayerTime in dayTimes.times {
                guard !Task.isCancelled else { return }
                guard preference.isEnabled(prayerTime.name) else { continue }
                guard prayerTime.date > now else { continue }

                let identifier = Self.identifier(for: prayerTime.name, date: dayTimes.date)
                var components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: prayerTime.date
                )
                components.timeZone = .current
                let text = content(prayerTime.name)
                try? await notificationManager.schedule(
                    identifier: identifier,
                    title: text.title,
                    body: text.body,
                    sound: sound,
                    dateComponents: components,
                    repeats: false
                )
            }
        }
    }

    func cancelAll() async {
        let identifiers = await notificationManager.pendingNotificationIdentifiers()
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        await notificationManager.cancelNotifications(withIdentifiers: identifiers)
    }

    static func identifier(for prayer: PrayerName, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = .current
        return "\(identifierPrefix)\(prayer.rawValue).\(formatter.string(from: date))"
    }
}
