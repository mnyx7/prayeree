import Foundation

@MainActor
protocol QuranNotificationScheduling: AnyObject {
    func scheduleDailyReminder(at time: DateComponents, title: String, body: String, soundName: String?) async
    func cancelDailyReminder() async
}
