//
//  PrayerTime.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct PrayerTime: Identifiable, Codable, Equatable, Sendable {
    let name: PrayerName
    let date: Date

    var id: PrayerName { name }

    func remaining(from now: Date) -> TimeInterval {
        date.timeIntervalSince(now)
    }
}
