//
//  PrayerName.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

enum PrayerName: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    /// Ordering matches the chronological sequence of the five daily prayers.
    static func < (lhs: PrayerName, rhs: PrayerName) -> Bool {
        (allCases.firstIndex(of: lhs) ?? 0) < (allCases.firstIndex(of: rhs) ?? 0)
    }
}
