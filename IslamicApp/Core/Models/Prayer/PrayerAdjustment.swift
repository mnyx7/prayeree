//
//  PrayerAdjustment.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct PrayerAdjustment: Codable, Equatable, Sendable {
    var minutesByPrayer: [PrayerName: Int]

    static let zero = PrayerAdjustment(
        minutesByPrayer: Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, 0) })
    )

    func minutes(for prayer: PrayerName) -> Int {
        minutesByPrayer[prayer] ?? 0
    }

    func adjusting(_ prayer: PrayerName, byMinutes minutes: Int) -> PrayerAdjustment {
        var copy = self
        copy.minutesByPrayer[prayer] = minutes
        return copy
    }
}
