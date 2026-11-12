import Foundation
import Adhan

struct PrayerTimesService: PrayerTimesServiceProtocol {
    let apiClient: any APIClientProtocol

    func fetchPrayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment
    ) async throws -> PrayerTimes {
        let endpoint = PrayerTimesEndpoint(
            dateComponents: dateComponents,
            coordinates: coordinates,
            calculationMethod: calculationMethod,
            madhab: madhab,
            adjustment: adjustment
        )
        let response = try await apiClient.send(endpoint, decodingTo: AlAdhanTimingsResponseDTO.self)
        return try PrayerTimesMapper.map(
            response: response,
            dateComponents: dateComponents,
            coordinates: coordinates,
            calculationMethod: calculationMethod,
            madhab: madhab
        )
    }
}

/// Independent of the network; keeps prayer times usable during provider outages.
/// The caller supplies the location's timezone instead of guessing from longitude.
enum LocalPrayerTimesCalculator {
    static func calculate(
        dateComponents: DateComponents, coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod, madhab: MadhabOption,
        adjustment: PrayerAdjustment, timeZoneIdentifier: String
    ) -> PrayerTimes? {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return nil }
        let method: Adhan.CalculationMethod
        switch calculationMethod {
        case .karachi: method = .karachi
        case .northAmerica: method = .northAmerica
        case .muslimWorldLeague: method = .muslimWorldLeague
        case .ummAlQura: method = .ummAlQura
        case .egyptianGeneralAuthority: method = .egyptian
        case .tehran: method = .tehran
        case .dubai: method = .dubai
        case .kuwait: method = .kuwait
        case .qatar: method = .qatar
        case .singapore: method = .singapore
        case .turkey: method = .turkey
        case .moonsightingCommittee: method = .moonsightingCommittee
        }
        var parameters = method.params
        parameters.madhab = madhab == .hanafi ? .hanafi : .shafi
        parameters.adjustments = Adhan.PrayerAdjustments(
            fajr: adjustment.minutes(for: .fajr), dhuhr: adjustment.minutes(for: .dhuhr),
            asr: adjustment.minutes(for: .asr), maghrib: adjustment.minutes(for: .maghrib),
            isha: adjustment.minutes(for: .isha)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let day = calendar.date(from: dateComponents) else { return nil }
        // Umm al-Qura uses a two-hour Isha interval during Ramadan.
        var hijriCalendar = Calendar.islamicUmmAlQura
        hijriCalendar.timeZone = timeZone
        if calculationMethod == .ummAlQura, day.hijriDate(using: hijriCalendar).month == .ramadan {
            parameters.ishaInterval = 120
        }
        guard let calculated = Adhan.PrayerTimes(
            coordinates: Adhan.Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude),
            date: dateComponents, calculationParameters: parameters
        ) else { return nil }
        return PrayerTimes(
            date: day, hijriDate: day.hijriDate(using: hijriCalendar),
            times: [PrayerTime(name: .fajr, date: calculated.fajr),
                    PrayerTime(name: .dhuhr, date: calculated.dhuhr),
                    PrayerTime(name: .asr, date: calculated.asr),
                    PrayerTime(name: .maghrib, date: calculated.maghrib),
                    PrayerTime(name: .isha, date: calculated.isha)],
            coordinates: coordinates, calculationMethod: calculationMethod, madhab: madhab,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}
