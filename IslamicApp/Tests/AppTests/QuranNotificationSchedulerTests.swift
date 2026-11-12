import XCTest
@testable import IslamicApp

final class QuranNotificationSchedulerTests: XCTestCase {
    @MainActor
    func testDailyReminderUsesStableIdentifier() async {
        let mock = MockNotificationManager()
        let scheduler = QuranNotificationScheduler(notificationManager: mock)

        await scheduler.scheduleDailyReminder(
            at: DateComponents(hour: 8, minute: 0),
            title: "Daily Ayah",
            body: "Read today's ayah",
            soundName: nil
        )

        XCTAssertTrue(mock.scheduledIdentifiers.contains("quran.dailyAyah"))
    }

    @MainActor
    func testReschedulingDoesNotDuplicateTheIdentifier() async {
        let mock = MockNotificationManager()
        let scheduler = QuranNotificationScheduler(notificationManager: mock)

        await scheduler.scheduleDailyReminder(at: DateComponents(hour: 8, minute: 0), title: "Daily Ayah", body: "A", soundName: nil)
        await scheduler.scheduleDailyReminder(at: DateComponents(hour: 9, minute: 0), title: "Daily Ayah", body: "B", soundName: nil)

        XCTAssertEqual(mock.scheduledIdentifiers.filter { $0 == "quran.dailyAyah" }.count, 1)
    }

    @MainActor
    func testCancelDailyReminderRemovesTheIdentifier() async {
        let mock = MockNotificationManager()
        let scheduler = QuranNotificationScheduler(notificationManager: mock)
        await scheduler.scheduleDailyReminder(at: DateComponents(hour: 8, minute: 0), title: "Daily Ayah", body: "A", soundName: nil)

        await scheduler.cancelDailyReminder()

        XCTAssertFalse(mock.scheduledIdentifiers.contains("quran.dailyAyah"))
    }
}
