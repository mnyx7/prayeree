//
//  PrayerNotificationPreference.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct PrayerNotificationPreference: Codable, Equatable, Sendable {
    var enabledByPrayer: [PrayerName: Bool]
    /// Opt-in: upgrading must not add alerts the user did not enable.
    var isSunriseEnabled = false

    static let allEnabled = PrayerNotificationPreference(
        enabledByPrayer: Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { ($0, true) })
    )

    func isEnabled(_ prayer: PrayerName) -> Bool {
        enabledByPrayer[prayer] ?? true
    }

    func toggling(_ prayer: PrayerName) -> PrayerNotificationPreference {
        var copy = self
        copy.enabledByPrayer[prayer] = !isEnabled(prayer)
        return copy
    }
}

extension PrayerNotificationPreference {
    private enum CodingKeys: String, CodingKey { case enabledByPrayer, isSunriseEnabled }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        enabledByPrayer = try values.decode([PrayerName: Bool].self, forKey: .enabledByPrayer)
        isSunriseEnabled = try values.decodeIfPresent(Bool.self, forKey: .isSunriseEnabled) ?? false
    }
}
