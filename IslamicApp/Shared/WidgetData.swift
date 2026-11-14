//
//  WidgetData.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// Display snapshots shared only between this app and its widget extension.
enum CompanionWidgets {
    static let appGroup = "group.com.minayayagubova.islamiccompanion"
    static let prayerKind = "CompanionPrayerTimes"
    static let ayahKind = "CompanionDailyAyah"
    static let readingKind = "CompanionContinueReading"

    static func dayKey(_ date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}

struct WidgetPrayer: Codable, Equatable, Sendable {
    let name: String
    let date: Date
}

struct WidgetPrayerDay: Codable, Equatable, Sendable {
    let date: Date
    let prayers: [WidgetPrayer]
}

struct WidgetPrayerSnapshot: Codable, Equatable, Sendable {
    let cityName: String
    let timeZoneIdentifier: String
    var days: [WidgetPrayerDay]

    var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .current }
    func nextPrayer(after date: Date) -> WidgetPrayer? {
        days.flatMap(\.prayers).filter { $0.date > date }.min { $0.date < $1.date }
    }
    func prayers(on date: Date) -> [WidgetPrayer] {
        days.first { CompanionWidgets.dayKey($0.date, timeZone: timeZone) == CompanionWidgets.dayKey(date, timeZone: timeZone) }?.prayers ?? []
    }
    func timelineDates(from date: Date) -> [Date] {
        let boundaries = days.flatMap(\.prayers).map(\.date).filter { $0 > date }
        let midnights = days.map(\.date).filter { $0 > date }
        let expiry = boundaries.max().map { $0.addingTimeInterval(1) }
        return Array(Set([date] + boundaries + midnights + (expiry.map { [$0] } ?? []))).sorted()
    }
}

struct WidgetQuranPreferences: Codable, Equatable, Sendable {
    var translationID: Int = 20
    var translationName: String = "Saheeh International"
    var languageCode: String = "en"
}

struct WidgetAyahSnapshot: Codable, Equatable, Sendable {
    let dayKey: String
    let surahNumber: Int
    let ayahNumber: Int
    let arabicText: String
    let translation: String?
    let preferences: WidgetQuranPreferences

    func isCurrent(at date: Date, preferences: WidgetQuranPreferences) -> Bool {
        dayKey == CompanionWidgets.dayKey(date)
            && self.preferences.translationID == preferences.translationID
            && self.preferences.languageCode == preferences.languageCode
    }
}

struct WidgetReadingSnapshot: Codable, Equatable, Sendable {
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let versesCount: Int

    var isValid: Bool { (1...114).contains(surahNumber) && ayahNumber > 0 && ayahNumber <= versesCount }
    var progress: Double { isValid ? Double(ayahNumber) / Double(versesCount) : 0 }
}

/// One atomic file per feature avoids lost updates when app and extension write concurrently.
struct WidgetFileStore: Sendable {
    let directory: URL?

    init(directory: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CompanionWidgets.appGroup)?.appendingPathComponent("WidgetSnapshots", isDirectory: true)) {
        self.directory = directory
    }

    func read<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let directory, let data = try? Data(contentsOf: directory.appendingPathComponent(name + ".json")) else { return nil }
        let decoded = try? JSONDecoder().decode(type, from: data)
        if name == "dailyAyah", let ayah = decoded as? WidgetAyahSnapshot,
           !ayah.arabicText.isEmpty || ayah.translation != nil {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name + ".json"))
            return nil
        }
        return decoded
    }

    @discardableResult
    func write<T: Encodable & Equatable>(_ value: T, named name: String) -> Bool {
        if name == "dailyAyah", let ayah = value as? WidgetAyahSnapshot,
           !ayah.arabicText.isEmpty || ayah.translation != nil { return false }
        guard var directory else { return false }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(value) else { return false }
        let url = directory.appendingPathComponent(name + ".json")
        guard (try? Data(contentsOf: url)) != data else { return false }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var flags = URLResourceValues()
            flags.isExcludedFromBackup = true
            try directory.setResourceValues(flags)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch { return false }
    }
}

enum WidgetRoute: Equatable {
    case prayerTimes
    case quran
    case dailyAyah(surah: Int, ayah: Int)
    case continueReading

    init?(url: URL) {
        guard url.scheme?.lowercased() == "prayeree" else { return nil }
        switch url.host {
        case "quran": self = .quran
        case "prayer-times": self = .prayerTimes
        case "continue-reading": self = .continueReading
        case "daily-ayah":
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard let s = query.first(where: { $0.name == "surah" })?.value.flatMap(Int.init),
                  let a = query.first(where: { $0.name == "ayah" })?.value.flatMap(Int.init),
                  (1...114).contains(s), (1...286).contains(a) else { return nil }
            self = .dailyAyah(surah: s, ayah: a)
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case .quran: return URL(string: "prayeree://quran")!
        case .prayerTimes: return URL(string: "prayeree://prayer-times")!
        case .continueReading: return URL(string: "prayeree://continue-reading")!
        case .dailyAyah(let surah, let ayah): return URL(string: "prayeree://daily-ayah?surah=\(surah)&ayah=\(ayah)")!
        }
    }
}
