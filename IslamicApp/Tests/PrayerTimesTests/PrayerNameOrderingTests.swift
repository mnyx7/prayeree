import XCTest
@testable import IslamicApp

final class PrayerNameOrderingTests: XCTestCase {
    func testAllCasesAreInChronologicalOrder() {
        XCTAssertEqual(PrayerName.allCases, [.fajr, .dhuhr, .asr, .maghrib, .isha])
    }

    func testComparableOrdering() {
        XCTAssertLessThan(PrayerName.fajr, PrayerName.dhuhr)
        XCTAssertLessThan(PrayerName.asr, PrayerName.maghrib)
        XCTAssertLessThan(PrayerName.maghrib, PrayerName.isha)
        XCTAssertFalse(PrayerName.isha < PrayerName.fajr)
    }

    func testSortedMatchesDeclarationOrder() {
        let shuffled: [PrayerName] = [.isha, .fajr, .maghrib, .dhuhr, .asr]
        XCTAssertEqual(shuffled.sorted(), PrayerName.allCases)
    }
}
