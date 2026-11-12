import XCTest
@testable import IslamicApp

final class PrayerCountdownTests: XCTestCase {
    func testRemainingIntervalIsPositiveBeforePrayer() {
        let now = Date(timeIntervalSince1970: 0)
        let prayer = PrayerTime(name: .maghrib, date: now.addingTimeInterval(84 * 60))
        XCTAssertEqual(prayer.remaining(from: now), 84 * 60, accuracy: 0.001)
    }

    func testRemainingIntervalIsNegativeAfterPrayer() {
        let now = Date(timeIntervalSince1970: 1000)
        let prayer = PrayerTime(name: .fajr, date: Date(timeIntervalSince1970: 500))
        XCTAssertLessThan(prayer.remaining(from: now), 0)
    }

    func testCountdownFormattingMatchesHoursAndMinutes() {
        // Matches the spec's canonical example: "Next prayer: Maghrib in 01:24"
        XCTAssertEqual(TimeFormatter.countdown(from: 84 * 60), "01:24")
        XCTAssertEqual(TimeFormatter.countdown(from: 59), "00:00")
        XCTAssertEqual(TimeFormatter.countdown(from: -30), "00:00")
    }

    func testNextPrayerReturnsFirstUpcomingTime() {
        let base = Date(timeIntervalSince1970: 0)
        let times = [
            PrayerTime(name: .fajr, date: base.addingTimeInterval(-3600)),
            PrayerTime(name: .dhuhr, date: base.addingTimeInterval(3600)),
            PrayerTime(name: .asr, date: base.addingTimeInterval(7200)),
            PrayerTime(name: .maghrib, date: base.addingTimeInterval(10800)),
            PrayerTime(name: .isha, date: base.addingTimeInterval(14400))
        ]
        let prayerTimes = PrayerTimes(
            date: base,
            hijriDate: HijriDate(day: 1, month: .muharram, year: 1447),
            times: times,
            coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
            calculationMethod: .ummAlQura,
            madhab: .shafiMalikiHanbali,
            timeZoneIdentifier: "Asia/Riyadh"
        )
        XCTAssertEqual(prayerTimes.nextPrayer(after: base)?.name, .dhuhr)
    }

    func testNextPrayerReturnsNilAfterIsha() {
        let base = Date(timeIntervalSince1970: 0)
        let times = [
            PrayerTime(name: .fajr, date: base.addingTimeInterval(-14400)),
            PrayerTime(name: .isha, date: base.addingTimeInterval(-3600))
        ]
        let prayerTimes = PrayerTimes(
            date: base,
            hijriDate: HijriDate(day: 1, month: .muharram, year: 1447),
            times: times,
            coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
            calculationMethod: .ummAlQura,
            madhab: .shafiMalikiHanbali,
            timeZoneIdentifier: "Asia/Riyadh"
        )
        XCTAssertNil(prayerTimes.nextPrayer(after: base))
    }
}
