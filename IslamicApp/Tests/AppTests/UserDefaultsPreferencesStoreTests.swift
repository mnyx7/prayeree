//
//  UserDefaultsPreferencesStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

final class UserDefaultsPreferencesStoreTests: XCTestCase {
    private let suiteName = "com.islamicapp.tests.preferences"
    private var defaults: UserDefaults!
    private var sut: UserDefaultsPreferencesStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        sut = UserDefaultsPreferencesStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        sut = nil
        defaults = nil
        super.tearDown()
    }

    func testMissingValueReturnsNil() {
        XCTAssertNil(sut.value(for: "appearanceMode", as: AppAppearanceMode.self))
    }

    func testSetThenGetRoundTrips() {
        sut.setValue(AppAppearanceMode.dark, for: "appearanceMode")

        XCTAssertEqual(sut.value(for: "appearanceMode", as: AppAppearanceMode.self), .dark)
    }

    func testSettingNilRemovesStoredValue() {
        sut.setValue(AppAppearanceMode.light, for: "appearanceMode")
        XCTAssertNotNil(sut.value(for: "appearanceMode", as: AppAppearanceMode.self))

        sut.setValue(AppAppearanceMode?.none, for: "appearanceMode")

        XCTAssertNil(sut.value(for: "appearanceMode", as: AppAppearanceMode.self))
    }

    func testPersistsComplexCodableValue() {
        let preference = PrayerNotificationPreference.allEnabled.toggling(.fajr)
        sut.setValue(preference, for: "prayerNotifications")

        let restored = sut.value(for: "prayerNotifications", as: PrayerNotificationPreference.self)

        XCTAssertEqual(restored, preference)
        XCTAssertEqual(restored?.isEnabled(.fajr), false)
    }

    func testValuePersistsAcrossStoreInstances() {
        sut.setValue(PrayerCalculationMethod.ummAlQura, for: "calculationMethod")

        let anotherStore = UserDefaultsPreferencesStore(defaults: defaults)

        XCTAssertEqual(anotherStore.value(for: "calculationMethod", as: PrayerCalculationMethod.self), .ummAlQura)
    }
}
