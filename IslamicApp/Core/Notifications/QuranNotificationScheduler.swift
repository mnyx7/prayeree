import Foundation
import UserNotifications

@MainActor
final class QuranNotificationScheduler: QuranNotificationScheduling {
    private let notificationManager: any NotificationManaging
    private static let identifier = "quran.dailyAyah"

    init(notificationManager: any NotificationManaging) {
        self.notificationManager = notificationManager
    }

    func scheduleDailyReminder(at time: DateComponents, title: String, body: String, soundName: String?) async {
        let sound = soundName.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
        try? await notificationManager.schedule(
            identifier: Self.identifier,
            title: title,
            body: body,
            sound: sound,
            dateComponents: time,
            repeats: true
        )
    }

    func cancelDailyReminder() async {
        await notificationManager.cancelNotifications(withIdentifiers: [Self.identifier])
    }
}
