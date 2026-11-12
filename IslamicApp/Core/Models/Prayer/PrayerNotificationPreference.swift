import Foundation

struct PrayerNotificationPreference: Codable, Equatable, Sendable {
    var enabledByPrayer: [PrayerName: Bool]

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
