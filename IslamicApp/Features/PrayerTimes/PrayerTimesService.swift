//
//  PrayerTimesService.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import Adhan

struct PrayerTimesService: PrayerTimesServiceProtocol {
    let apiClient: any APIClientProtocol
    let minberTimetables = MinberTimetableCache()

    func fetchPrayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment,
        city: City? = nil
    ) async throws -> PrayerTimes {
        if calculationMethod == .qmiMinber {
            return try await MinberPrayerTimetable.fetch(apiClient: apiClient, cache: minberTimetables,
                dateComponents: dateComponents, coordinates: coordinates,
                city: city, madhab: madhab, adjustment: adjustment)
        }
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
        case .qmiMinber: return nil // Never approximate a published timetable with another method.
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
            timeZoneIdentifier: timeZoneIdentifier,
            sunrise: calculated.sunrise
        )
    }
}

// MARK: - QMİ published timetable, distributed by Minber.az

struct MinberDirectoryEndpoint: Endpoint {
    let baseURL = URL(string: "https://namaz.minber.az")!
    let path = "/api"
    let queryItems: [URLQueryItem] = []
}
struct MinberMonthEndpoint: Endpoint {
    let baseURL = URL(string: "https://namaz.minber.az")!
    let city: String
    let year: Int
    let month: Int
    var path: String { "/json/\(city)/\(year)/\(month)" }
    let queryItems: [URLQueryItem] = []
}
struct MinberDirectoryDTO: Decodable, Sendable {
    struct Entry: Decodable, Sendable { let city: String; let name: String }
    let Cities: [Entry]
}
struct MinberMonthDTO: Decodable, Sendable {
    struct InfoDTO: Decodable, Sendable { let Status: String }
    struct CityDTO: Decodable, Sendable { let name: String }
    struct Day: Decodable, Sendable {
        let tarix: String
        let hicri: String
        let subh: String
        let gunorta: String
        let ikindi: String
        let axsam: String
        let yatsi: String
        var gunes: String? = nil
    }
    let Info: InfoDTO
    let CityInfo: CityDTO
    let PrayerTimes: [Day]
}

/// Reuse a fetched month for the notification window without persisting another content format.
actor MinberTimetableCache {
    private var directory: MinberDirectoryDTO?
    private var months: [String: (Date, MinberMonthDTO)] = [:]
    func directory(using client: any APIClientProtocol) async throws -> MinberDirectoryDTO {
        if let directory { return directory }
        let fetched = try await client.send(MinberDirectoryEndpoint(), decodingTo: MinberDirectoryDTO.self)
        directory = fetched
        return fetched
    }
    func month(_ endpoint: MinberMonthEndpoint, using client: any APIClientProtocol) async throws -> MinberMonthDTO {
        if let (date, response) = months[endpoint.path], Date().timeIntervalSince(date) < 900 { return response }
        let response = try await client.send(endpoint, decodingTo: MinberMonthDTO.self)
        guard response.Info.Status.lowercased() == "success", !response.PrayerTimes.isEmpty else { throw NetworkError.invalidResponse }
        months[endpoint.path] = (Date(), response)
        if months.count > 12 { months = [endpoint.path: (Date(), response)] }
        return response
    }
}

enum MinberPrayerTimetable {
    static func normalized(_ name: String) -> String {
        let latin = name.applyingTransform(.toLatin, reverse: false) ?? name
        return latin.lowercased().folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "ə", with: "e").replacingOccurrences(of: "ı", with: "i")
            .components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
    static func citySlug(for city: City, coordinates: Coordinates, directory: MinberDirectoryDTO) -> String? {
        guard city.countryCode.uppercased() == "AZ" else { return nil }
        // Reject stale location metadata after moving to a different location.
        let latitude = (coordinates.latitude - city.coordinates.latitude) * .pi / 180
        let longitude = (coordinates.longitude - city.coordinates.longitude) * .pi / 180
        let a = pow(sin(latitude / 2), 2) + cos(coordinates.latitude * .pi / 180)
            * cos(city.coordinates.latitude * .pi / 180) * pow(sin(longitude / 2), 2)
        guard a.isFinite, a >= 0, a <= 1, 6_371 * 2 * atan2(sqrt(a), sqrt(1 - a)) <= 25 else { return nil }
        let aliases = ["baku": "baki", "ganja": "gence", "gandzha": "gence", "nakhchivan": "naxcivan",
                       "lankaran": "lenkeran", "shaki": "seki", "sheki": "seki", "shamakhi": "samaxi",
                       "khachmaz": "xacmaz", "khankendi": "xankendi", "sumgait": "sumqayit", "shusha": "susa"]
        let name = normalized(city.name)
        let target = aliases[name] ?? name
        return directory.Cities.first { normalized($0.name) == target || normalized($0.city) == target }?.city
    }
    static func fetch(apiClient: any APIClientProtocol, cache: MinberTimetableCache,
                      dateComponents: DateComponents, coordinates: Coordinates, city: City?,
                      madhab: MadhabOption, adjustment: PrayerAdjustment) async throws -> PrayerTimes {
        guard let city, city.countryCode.uppercased() == "AZ",
              let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day,
              (1...12).contains(month), (1...31).contains(day) else { throw NetworkError.invalidResponse }
        let directory = try await cache.directory(using: apiClient)
        guard let slug = citySlug(for: city, coordinates: coordinates, directory: directory) else { throw NetworkError.invalidResponse }
        let response = try await cache.month(MinberMonthEndpoint(city: slug, year: year, month: month), using: apiClient)
        let expectedCity = directory.Cities.first { $0.city == slug }?.name
        guard expectedCity.map({ normalized($0) == normalized(response.CityInfo.name) }) == true else { throw NetworkError.invalidResponse }
        return try map(response, dateComponents: dateComponents, coordinates: coordinates, madhab: madhab, adjustment: adjustment)
    }
    static func map(_ response: MinberMonthDTO, dateComponents: DateComponents, coordinates: Coordinates,
                    madhab: MadhabOption, adjustment: PrayerAdjustment) throws -> PrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Baku")!
        guard response.Info.Status.lowercased() == "success",
              let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day,
              (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              calendar.component(.day, from: date) == day, calendar.component(.month, from: date) == month else { throw NetworkError.invalidResponse }
        let monthNames = ["yanvar", "fevral", "mart", "aprel", "may", "iyun", "iyul", "avqust", "sentyabr", "oktyabr", "noyabr", "dekabr"]
        let matches = response.PrayerTimes.filter { row in
            let parts = row.tarix.split(separator: " ")
            return parts.count == 3 && Int(parts[0]) == day && Int(parts[2]) == year && normalized(String(parts[1])) == monthNames[month - 1]
        }
        guard matches.count == 1, let row = matches.first else { throw NetworkError.invalidResponse }
        let values: [(PrayerName, String)] = [(.fajr, row.subh), (.dhuhr, row.gunorta), (.asr, row.ikindi), (.maghrib, row.axsam), (.isha, row.yatsi)]
        func makeDate(_ raw: String) throws -> Date {
            let parts = raw.split(separator: ":")
            guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]), (0...23).contains(hour), (0...59).contains(minute),
                  let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else { throw NetworkError.invalidResponse }
            return time
        }
        let times = try values.map { name, raw -> PrayerTime in
            PrayerTime(name: name, date: try makeDate(raw).addingTimeInterval(Double(adjustment.minutes(for: name)) * 60))
        }
        guard zip(times, times.dropFirst()).allSatisfy({ $0.date < $1.date }) else { throw NetworkError.invalidResponse }
        let hijriParts = row.hicri.split(separator: " ")
        let hijriMonths = ["meherrem", "sefer", "rebiulevvel", "rebiulaxir", "cemadiyelevvel", "cemadiyelaxir", "receb", "saban", "ramazan", "sevval", "zulqede", "zulhicce"]
        guard hijriParts.count == 3, let hijriDay = Int(hijriParts[0]), (1...30).contains(hijriDay),
              let hijriYear = Int(hijriParts[2]), let monthIndex = hijriMonths.firstIndex(of: normalized(String(hijriParts[1])).replacingOccurrences(of: "zil", with: "zul")),
              let hijriMonth = HijriMonth(rawValue: monthIndex + 1) else { throw NetworkError.invalidResponse }
        return PrayerTimes(date: date, hijriDate: HijriDate(day: hijriDay, month: hijriMonth, year: hijriYear),
                           times: times, coordinates: coordinates, calculationMethod: .qmiMinber,
                           madhab: madhab, timeZoneIdentifier: "Asia/Baku",
                           sunrise: row.gunes.flatMap { try? makeDate($0) })
    }
}
