import Foundation

struct PrayerTime: Identifiable, Codable, Equatable, Sendable {
    let name: PrayerName
    let date: Date

    var id: PrayerName { name }

    func remaining(from now: Date) -> TimeInterval {
        date.timeIntervalSince(now)
    }
}
