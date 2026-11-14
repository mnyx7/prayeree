//
//  QuranReadingPreferencesTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

final class QuranReadingPreferencesTests: XCTestCase {
    func testDefaultPreferences() {
        let preferences = QuranReadingPreferences.default
        XCTAssertEqual(preferences.readingMode, .arabicWithTranslation)
        XCTAssertEqual(preferences.fontScale, 1.0, accuracy: 0.001)
        XCTAssertNil(preferences.preferredTranslationId)
    }

    func testFontScaleClampsBelowMinimum() {
        let preferences = QuranReadingPreferences.default.withFontScale(0.1)
        XCTAssertEqual(preferences.fontScale, QuranReadingPreferences.fontScaleRange.lowerBound, accuracy: 0.001)
    }

    func testFontScaleClampsAboveMaximum() {
        let preferences = QuranReadingPreferences.default.withFontScale(5.0)
        XCTAssertEqual(preferences.fontScale, QuranReadingPreferences.fontScaleRange.upperBound, accuracy: 0.001)
    }

    func testFontScaleWithinRangeIsUnchanged() {
        let preferences = QuranReadingPreferences.default.withFontScale(1.5)
        XCTAssertEqual(preferences.fontScale, 1.5, accuracy: 0.001)
    }

    func testCodableRoundTrip() throws {
        let original = QuranReadingPreferences(readingMode: .arabicOnly, fontScale: 1.2, preferredTranslationId: 131)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(QuranReadingPreferences.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
