import Foundation

struct PrayerTimesEndpoint: Endpoint {
    let baseURL = URL(string: "https://api.aladhan.com")!
    let dateComponents: DateComponents
    let coordinates: Coordinates
    let calculationMethod: PrayerCalculationMethod
    let madhab: MadhabOption
    let adjustment: PrayerAdjustment

    var path: String {
        guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else {
            return "/v1/timings"
        }
        return String(format: "/v1/timings/%02d-%02d-%04d", day, month, year)
    }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "latitude", value: String(coordinates.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinates.longitude)),
            URLQueryItem(name: "method", value: String(calculationMethod.rawValue)),
            URLQueryItem(name: "school", value: String(madhab.rawValue)),
            URLQueryItem(name: "tune", value: Self.tuneString(for: adjustment))
        ]
    }

    // AlAdhan's `tune` parameter is 9 comma-separated minute offsets in the
    // documented order: Imsak,Fajr,Sunrise,Dhuhr,Asr,Maghrib,Sunset,Isha,Midnight.
    // Only the 5 prayers our domain model tracks are user-adjustable; the rest stay 0.
    private static func tuneString(for adjustment: PrayerAdjustment) -> String {
        let values = [
            0, // Imsak
            adjustment.minutes(for: .fajr),
            0, // Sunrise
            adjustment.minutes(for: .dhuhr),
            adjustment.minutes(for: .asr),
            adjustment.minutes(for: .maghrib),
            0, // Sunset
            adjustment.minutes(for: .isha),
            0  // Midnight
        ]
        return values.map(String.init).joined(separator: ",")
    }
}
