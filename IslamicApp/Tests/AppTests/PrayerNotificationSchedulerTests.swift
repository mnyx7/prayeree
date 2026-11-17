//
//  PrayerNotificationSchedulerTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

final class PrayerNotificationSchedulerTests: XCTestCase {
    @MainActor
    func testIdentifierFormatIsStableAndPrefixed() {
        let date = Date(timeIntervalSince1970: 0)

        let identifier = PrayerNotificationScheduler.identifier(for: .fajr, date: date)

        XCTAssertTrue(identifier.hasPrefix("prayer.fajr."))
        XCTAssertTrue(identifier.hasSuffix(dateKey(for: date)))
    }

    @MainActor
    func testIdentifierIsDeterministicForSameInputs() {
        let date = Date()

        let first = PrayerNotificationScheduler.identifier(for: .isha, date: date)
        let second = PrayerNotificationScheduler.identifier(for: .isha, date: date)

        XCTAssertEqual(first, second)
    }

    @MainActor
    func testIdentifierDiffersByPrayerAndByDate() {
        let date = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date)!

        XCTAssertNotEqual(
            PrayerNotificationScheduler.identifier(for: .fajr, date: date),
            PrayerNotificationScheduler.identifier(for: .dhuhr, date: date)
        )
        XCTAssertNotEqual(
            PrayerNotificationScheduler.identifier(for: .fajr, date: date),
            PrayerNotificationScheduler.identifier(for: .fajr, date: tomorrow)
        )
    }

    @MainActor
    func testDisabledPrayersAreNotScheduled() async {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        let today = Date()
        let times = makePrayerTimes(
            date: today,
            times: PrayerName.allCases.map { PrayerTime(name: $0, date: today.addingTimeInterval(3600)) }
        )
        let preference = PrayerNotificationPreference.allEnabled.toggling(.fajr)

        await scheduler.reschedule(
            for: [times],
            preference: preference,
            soundName: nil,
            content: { prayer in (title: prayer.rawValue, body: "") }
        )

        XCTAssertFalse(mock.scheduledIdentifiers.contains(PrayerNotificationScheduler.identifier(for: .fajr, date: today)))
        XCTAssertTrue(mock.scheduledIdentifiers.contains(PrayerNotificationScheduler.identifier(for: .dhuhr, date: today)))
    }

    @MainActor
    func testPastPrayerTimesAreNotScheduled() async {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        let today = Date()
        let times = makePrayerTimes(
            date: today,
            times: [
                PrayerTime(name: .fajr, date: today.addingTimeInterval(-3600)),
                PrayerTime(name: .isha, date: today.addingTimeInterval(3600))
            ]
        )

        await scheduler.reschedule(
            for: [times],
            preference: .allEnabled,
            soundName: nil,
            content: { prayer in (title: prayer.rawValue, body: "") }
        )

        XCTAssertFalse(mock.scheduledIdentifiers.contains(PrayerNotificationScheduler.identifier(for: .fajr, date: today)))
        XCTAssertTrue(mock.scheduledIdentifiers.contains(PrayerNotificationScheduler.identifier(for: .isha, date: today)))
    }

    @MainActor
    func testCancelAllOnlyRemovesPrayerPrefixedIdentifiers() async throws {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        try await mock.schedule(identifier: "quran.dailyAyah", title: "x", body: "x", sound: nil, dateComponents: DateComponents(), repeats: true)
        try await mock.schedule(identifier: "prayer.fajr.20260101", title: "x", body: "x", sound: nil, dateComponents: DateComponents(), repeats: false)

        await scheduler.cancelAll()

        XCTAssertTrue(mock.scheduledIdentifiers.contains("quran.dailyAyah"))
        XCTAssertFalse(mock.scheduledIdentifiers.contains("prayer.fajr.20260101"))
    }

    @MainActor
    func testReschedulingReplacesPreviousRequestsRatherThanDuplicating() async {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        let today = Date()
        let times = makePrayerTimes(date: today, times: [PrayerTime(name: .dhuhr, date: today.addingTimeInterval(3600))])

        await scheduler.reschedule(for: [times], preference: .allEnabled, soundName: nil, content: { ($0.rawValue, "") })
        await scheduler.reschedule(for: [times], preference: .allEnabled, soundName: nil, content: { ($0.rawValue, "") })

        let dhuhrIdentifier = PrayerNotificationScheduler.identifier(for: .dhuhr, date: today)
        XCTAssertEqual(mock.scheduledIdentifiers.filter { $0 == dhuhrIdentifier }.count, 1)
    }

    func testLegacyNotificationPreferencesKeepSunriseOff() throws {
        let preference = PrayerNotificationPreference.allEnabled.toggling(.isha)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(preference)) as? [String: Any])
        object.removeValue(forKey: "isSunriseEnabled")
        let restored = try JSONDecoder().decode(PrayerNotificationPreference.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertFalse(restored.isSunriseEnabled)
        XCTAssertTrue(restored.isEnabled(.fajr))
        XCTAssertFalse(restored.isEnabled(.isha))
        var enabled = restored
        enabled.isSunriseEnabled = true
        XCTAssertEqual(try JSONDecoder().decode(PrayerNotificationPreference.self, from: JSONEncoder().encode(enabled)), enabled)
    }

    @MainActor func testSunriseUsesSourceTimeZoneContentAndSound() async throws {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        var schedule = makePrayerTimes(date: Date().addingTimeInterval(86400), times: [])
        schedule.sunrise = Date().addingTimeInterval(90000)
        await scheduler.rescheduleSunrise(for: [schedule], isEnabled: true, soundName: "test.caf", content: { ("Sunrise", "The sun is rising.") })
        let id = PrayerNotificationScheduler.sunriseIdentifier(for: schedule.date, timeZone: schedule.timeZone)
        let request = try XCTUnwrap(mock.scheduledRequests[id])
        XCTAssertEqual(request.title, "Sunrise")
        XCTAssertEqual(request.body, "The sun is rising.")
        XCTAssertNotNil(request.sound)
        XCTAssertEqual(request.dateComponents.timeZone?.identifier, schedule.timeZoneIdentifier)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = schedule.timeZone
        XCTAssertEqual(request.dateComponents.hour, calendar.component(.hour, from: schedule.sunrise!))
        XCTAssertEqual(request.dateComponents.minute, calendar.component(.minute, from: schedule.sunrise!))
        XCTAssertTrue(id.hasPrefix("sunrise."))
        XCTAssertEqual(mock.scheduledIdentifiers.count, 1)
    }

    @MainActor func testSunriseDisabledMissingAndPastProduceNoAlerts() async {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        var schedule = makePrayerTimes(date: Date(), times: [])
        schedule.sunrise = Date().addingTimeInterval(3600)
        await scheduler.rescheduleSunrise(for: [schedule], isEnabled: false, soundName: nil, content: { ("Sunrise", "") })
        XCTAssertTrue(mock.scheduledIdentifiers.isEmpty)
        schedule.sunrise = nil
        await scheduler.rescheduleSunrise(for: [schedule], isEnabled: true, soundName: nil, content: { ("Sunrise", "") })
        schedule.sunrise = Date().addingTimeInterval(-3600)
        await scheduler.rescheduleSunrise(for: [schedule], isEnabled: true, soundName: nil, content: { ("Sunrise", "") })
        XCTAssertTrue(mock.scheduledIdentifiers.isEmpty)
    }

    @MainActor func testSunriseToggleOffCancelsOnlySunriseAndRescheduleDoesNotDuplicate() async throws {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        try await mock.schedule(identifier: "prayer.fajr.existing", title: "", body: "", sound: nil, dateComponents: DateComponents(), repeats: false)
        try await mock.schedule(identifier: "quran.dailyAyah", title: "", body: "", sound: nil, dateComponents: DateComponents(), repeats: true)
        var schedule = makePrayerTimes(date: Date(), times: [])
        schedule.sunrise = Date().addingTimeInterval(3600)
        for _ in 0..<2 {
            await scheduler.rescheduleSunrise(for: [schedule], isEnabled: true, soundName: nil, content: { ("Sunrise", "") })
        }
        XCTAssertEqual(mock.scheduledIdentifiers.filter { $0.hasPrefix("sunrise.") }.count, 1)
        await scheduler.rescheduleSunrise(for: [schedule], isEnabled: false, soundName: nil, content: { ("Sunrise", "") })
        XCTAssertFalse(mock.scheduledIdentifiers.contains { $0.hasPrefix("sunrise.") })
        XCTAssertTrue(mock.scheduledIdentifiers.contains("prayer.fajr.existing"))
        XCTAssertTrue(mock.scheduledIdentifiers.contains("quran.dailyAyah"))
    }

    @MainActor func testSevenDaysWithSunriseKeepFivePrayersPerDayAndCancelTogether() async {
        let mock = MockNotificationManager()
        let scheduler = PrayerNotificationScheduler(notificationManager: mock)
        let days = (1...7).map { offset -> PrayerTimes in
            let date = Date().addingTimeInterval(Double(offset) * 86400)
            var schedule = makePrayerTimes(date: date, times: PrayerName.allCases.map { PrayerTime(name: $0, date: date.addingTimeInterval(3600)) })
            schedule.sunrise = date.addingTimeInterval(7200)
            return schedule
        }
        await scheduler.reschedule(for: days, preference: .allEnabled, soundName: nil, content: { ($0.rawValue, "") })
        await scheduler.rescheduleSunrise(for: days, isEnabled: true, soundName: nil, content: { ("Sunrise", "") })
        XCTAssertEqual(mock.scheduledIdentifiers.filter { $0.hasPrefix("prayer.") }.count, 35)
        XCTAssertEqual(mock.scheduledIdentifiers.filter { $0.hasPrefix("sunrise.") }.count, 7)
        await scheduler.cancelAll()
        XCTAssertTrue(mock.scheduledIdentifiers.isEmpty)
    }

    private func makePrayerTimes(date: Date, times: [PrayerTime]) -> PrayerTimes {
        PrayerTimes(
            date: date,
            hijriDate: HijriDate(day: 1, month: .muharram, year: 1447),
            times: times,
            coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
            calculationMethod: .ummAlQura,
            madhab: .shafiMalikiHanbali,
            timeZoneIdentifier: "Asia/Riyadh"
        )
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
