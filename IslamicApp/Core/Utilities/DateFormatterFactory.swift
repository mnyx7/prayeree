import Foundation

enum DateFormatterFactory {
    /// `timeZone` defaults to nil (DateFormatter's own `TimeZone.current`
    /// fallback) for callers displaying device-local events (e.g. "last
    /// updated at..."). Callers displaying a specific location's time (e.g.
    /// prayer times) must pass that location's own timezone explicitly —
    /// see PrayerTimes.timeZone.
    static func gregorianMediumDate(locale: Locale = .current, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if let timeZone { formatter.timeZone = timeZone }
        return formatter
    }

    static func shortTime(locale: Locale = .current, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        if let timeZone { formatter.timeZone = timeZone }
        return formatter
    }
}
