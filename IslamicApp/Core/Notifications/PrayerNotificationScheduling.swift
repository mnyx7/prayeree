//
//  PrayerNotificationScheduling.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

/// Takes an already-computed rolling window of PrayerTimes rather than
/// fetching it — Core/Notifications must not depend on Features/PrayerTimes,
/// so the caller (a future app-level coordinator) supplies the data.
///
/// `content` is injected rather than hardcoded so this file never embeds
/// user-facing text; Phase 12 wires it to LocalizationManager.
@MainActor
protocol PrayerNotificationScheduling: AnyObject {
    func reschedule(
        for prayerTimesByDate: [PrayerTimes],
        preference: PrayerNotificationPreference,
        soundName: String?,
        content: @escaping @Sendable (PrayerName) -> (title: String, body: String)
    ) async
    func rescheduleSunrise(
        for prayerTimesByDate: [PrayerTimes],
        isEnabled: Bool,
        soundName: String?,
        content: @escaping @Sendable () -> (title: String, body: String)
    ) async
    func cancelAll() async
}
