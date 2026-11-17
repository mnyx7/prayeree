//
//  PrayerTimesMapper.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum PrayerTimesMapper {
    /// All output Date values are resolved using the response's own
    /// `meta.timezone` — never the device's calendar — so a request made
    /// from a different timezone than the target city can't shift the day.
    static func map(
        response: AlAdhanTimingsResponseDTO,
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption
    ) throws -> PrayerTimes {
        let data = response.data

        guard let timeZone = TimeZone(identifier: data.meta.timezone) else {
            throw NetworkError.decodingFailed("Unrecognized timezone identifier: \(data.meta.timezone)")
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let dayStart = calendar.date(from: dateComponents) else {
            throw NetworkError.decodingFailed("Invalid date components")
        }
        let normalizedDayComponents = calendar.dateComponents([.year, .month, .day], from: dayStart)

        func makeDate(from timingString: String) throws -> Date {
            // AlAdhan sometimes suffixes timing strings with a zone hint, e.g. "05:14 (+03)".
            let cleaned = timingString.split(separator: " ").first.map(String.init) ?? timingString
            let parts = cleaned.split(separator: ":")
            guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
                throw NetworkError.decodingFailed("Unrecognized timing format: \(timingString)")
            }
            var components = normalizedDayComponents
            components.hour = hour
            components.minute = minute
            components.second = 0
            guard let date = calendar.date(from: components) else {
                throw NetworkError.decodingFailed("Could not construct date from timing: \(timingString)")
            }
            return date
        }

        let orderedEntries: [(PrayerName, String)] = [
            (.fajr, data.timings.fajr),
            (.dhuhr, data.timings.dhuhr),
            (.asr, data.timings.asr),
            (.maghrib, data.timings.maghrib),
            (.isha, data.timings.isha)
        ]
        let times = try orderedEntries.map { name, raw in
            PrayerTime(name: name, date: try makeDate(from: raw))
        }

        guard let hijriMonth = HijriMonth(rawValue: data.date.hijri.month.number) else {
            throw NetworkError.decodingFailed("Unrecognized Hijri month number: \(data.date.hijri.month.number)")
        }
        guard let hijriDay = Int(data.date.hijri.day), let hijriYear = Int(data.date.hijri.year) else {
            throw NetworkError.decodingFailed("Unrecognized Hijri date components")
        }

        let sunrise = data.timings.sunrise.flatMap { raw -> Date? in
            let cleaned = raw.split(separator: " ").first.map(String.init) ?? raw
            let parts = cleaned.split(separator: ":")
            guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
                  (0...23).contains(hour), (0...59).contains(minute) else { return nil }
            return try? makeDate(from: raw)
        }

        return PrayerTimes(
            date: dayStart,
            hijriDate: HijriDate(day: hijriDay, month: hijriMonth, year: hijriYear),
            times: times,
            coordinates: coordinates,
            calculationMethod: calculationMethod,
            madhab: madhab,
            timeZoneIdentifier: data.meta.timezone,
            sunrise: sunrise
        )
    }
}
