//
//  PrayerNotificationScheduler.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import UserNotifications

@MainActor
final class PrayerNotificationScheduler: PrayerNotificationScheduling {
    private let notificationManager: any NotificationManaging
    private static let identifierPrefix = "prayer."
    private static let sunrisePrefix = "sunrise."

    init(notificationManager: any NotificationManaging) {
        self.notificationManager = notificationManager
    }

    func reschedule(
        for prayerTimesByDate: [PrayerTimes],
        preference: PrayerNotificationPreference,
        soundName: String?,
        content: @escaping @Sendable (PrayerName) -> (title: String, body: String)
    ) async {
        guard !Task.isCancelled else { return }
        await cancelAll()
        guard !Task.isCancelled else { return }

        let sound = soundName.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
        let now = Date()

        for dayTimes in prayerTimesByDate {
            for prayerTime in dayTimes.times {
                guard !Task.isCancelled else { return }
                guard preference.isEnabled(prayerTime.name) else { continue }
                guard prayerTime.date > now else { continue }

                let identifier = Self.identifier(for: prayerTime.name, date: dayTimes.date)
                var components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: prayerTime.date
                )
                components.timeZone = .current
                let text = content(prayerTime.name)
                try? await notificationManager.schedule(
                    identifier: identifier,
                    title: text.title,
                    body: text.body,
                    sound: sound,
                    dateComponents: components,
                    repeats: false
                )
            }
        }
    }

    func rescheduleSunrise(
        for prayerTimesByDate: [PrayerTimes],
        isEnabled: Bool,
        soundName: String?,
        content: @escaping @Sendable () -> (title: String, body: String)
    ) async {
        guard !Task.isCancelled else { return }
        let identifiers = await notificationManager.pendingNotificationIdentifiers()
            .filter { $0.hasPrefix(Self.sunrisePrefix) }
        await notificationManager.cancelNotifications(withIdentifiers: identifiers)
        guard isEnabled, !Task.isCancelled else { return }

        let now = Date()
        let sound = soundName.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
        let text = content()
        for day in prayerTimesByDate {
            guard !Task.isCancelled else { return }
            guard let sunrise = day.sunrise, sunrise > now else { continue }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = day.timeZone
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: sunrise)
            components.timeZone = day.timeZone
            try? await notificationManager.schedule(
                identifier: Self.sunriseIdentifier(for: day.date, timeZone: day.timeZone),
                title: text.title, body: text.body, sound: sound,
                dateComponents: components, repeats: false
            )
        }
    }

    static func sunriseIdentifier(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = timeZone
        return "\(sunrisePrefix)\(formatter.string(from: date))"
    }

    func cancelAll() async {
        guard !Task.isCancelled else { return }
        let identifiers = await notificationManager.pendingNotificationIdentifiers()
            .filter { $0.hasPrefix(Self.identifierPrefix) || $0.hasPrefix(Self.sunrisePrefix) }
        guard !Task.isCancelled else { return }
        await notificationManager.cancelNotifications(withIdentifiers: identifiers)
    }

    static func identifier(for prayer: PrayerName, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = .current
        return "\(identifierPrefix)\(prayer.rawValue).\(formatter.string(from: date))"
    }
}
