//
//  PrayerTimes.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct PrayerTimes: Codable, Equatable, Sendable {
    let date: Date
    let hijriDate: HijriDate
    let times: [PrayerTime]
    let coordinates: Coordinates
    let calculationMethod: PrayerCalculationMethod
    let madhab: MadhabOption
    /// The prayer location's own IANA timezone (e.g. "America/New_York") —
    /// prayer times must always display in this timezone, never the device's
    /// current one. `DateFormatter` defaults to `TimeZone.current` when not
    /// told otherwise, which silently shows the wrong clock time whenever the
    /// device's system timezone differs from the prayed-for location's.
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    func time(for prayer: PrayerName) -> PrayerTime? {
        times.first { $0.name == prayer }
    }

    /// Returns the next upcoming prayer strictly after `referenceDate`.
    /// Returns `nil` once all five prayers for this date have passed — callers
    /// are expected to fall back to the following day's Fajr in that case.
    func nextPrayer(after referenceDate: Date) -> PrayerTime? {
        times
            .sorted { $0.date < $1.date }
            .first { $0.date > referenceDate }
    }
}
