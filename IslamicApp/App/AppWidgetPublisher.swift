//
//  AppWidgetPublisher.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import WidgetKit

@MainActor
final class AppWidgetPublisher {
    private let store: WidgetFileStore
    private let reload: (String) -> Void
    private var readingReloadTask: Task<Void, Never>?

    init(store: WidgetFileStore = WidgetFileStore(), reload: @escaping (String) -> Void = { WidgetCenter.shared.reloadTimelines(ofKind: $0) }) {
        self.store = store
        self.reload = reload
    }

    func seed(preferences: any PreferencesStore) {
        if let position = preferences.value(for: QuranReadingPosition.lastReadKey, as: QuranReadingPosition.self), position.isValid {
            publishReading(position)
        }
        let saved = preferences.value(for: "quran.readingPreferences", as: QuranReadingPreferences.self)
        let id = saved?.preferredTranslationId ?? QuranTranslation.defaultID
        let existing = store.read("quranPreferences", as: WidgetQuranPreferences.self)
        let name = existing.flatMap { $0.translationID == id ? $0.translationName : nil }
            ?? (id == 20 ? "Saheeh International" : "")
        publishQuranPreferences(translation: QuranTranslation(id: id, languageCode: "", name: name), languageCode: Locale.current.language.languageCode?.identifier ?? "en")
    }

    func publishPrayers(state: AppState, now: Date = Date()) {
        guard let coordinates = state.resolvedCoordinates else { return }
        let zone: String
        if case .manual(_, let city) = state.locationSourceMode { zone = city.timeZoneIdentifier }
        else { zone = TimeZone.current.identifier }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .current
        let days = (0..<7).compactMap { offset -> WidgetPrayerDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now),
                  let times = LocalPrayerTimesCalculator.calculate(dateComponents: calendar.dateComponents([.year, .month, .day], from: date), coordinates: coordinates, calculationMethod: state.calculationMethod, madhab: state.madhab, adjustment: state.prayerAdjustment, timeZoneIdentifier: zone) else { return nil }
            return WidgetPrayerDay(date: times.date, prayers: times.times.map { WidgetPrayer(name: $0.name.rawValue, date: $0.date) })
        }
        let snapshot = WidgetPrayerSnapshot(cityName: state.selectedCity?.name ?? String(localized: "widget.current_location", defaultValue: "Current location"), timeZoneIdentifier: zone, days: days)
        if store.write(snapshot, named: "prayers") { reload(CompanionWidgets.prayerKind) }
    }

    func publishPrayerTimes(_ times: PrayerTimes) {
        guard var snapshot = store.read("prayers", as: WidgetPrayerSnapshot.self), snapshot.timeZoneIdentifier == times.timeZoneIdentifier else { return }
        let key = CompanionWidgets.dayKey(times.date, timeZone: times.timeZone)
        guard let index = snapshot.days.firstIndex(where: { CompanionWidgets.dayKey($0.date, timeZone: times.timeZone) == key }) else { return }
        snapshot.days[index] = WidgetPrayerDay(date: times.date, prayers: times.times.map { WidgetPrayer(name: $0.name.rawValue, date: $0.date) })
        if store.write(snapshot, named: "prayers") { reload(CompanionWidgets.prayerKind) }
    }

    func publishQuranPreferences(translation: QuranTranslation?, languageCode: String) {
        let value = WidgetQuranPreferences(translationID: translation?.id ?? 20, translationName: translation?.name ?? "Saheeh International", languageCode: languageCode)
        if store.write(value, named: "quranPreferences") { reload(CompanionWidgets.ayahKind) }
    }

    func publishAyah(_ ayah: Ayah, date: Date, translation: QuranTranslation?, languageCode: String) {
        let prefs = WidgetQuranPreferences(translationID: translation?.id ?? 20, translationName: translation?.name ?? "Saheeh International", languageCode: languageCode)
        let value = WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(date), surahNumber: ayah.surahNumber, ayahNumber: ayah.ayahNumberInSurah, arabicText: "", translation: nil, preferences: prefs)
        if store.write(value, named: "dailyAyah") { reload(CompanionWidgets.ayahKind) }
    }

    func publishReading(_ position: QuranReadingPosition) {
        guard position.isValid else { return }
        let value = WidgetReadingSnapshot(surahNumber: position.surah.id, surahName: position.surah.transliteratedName, ayahNumber: position.ayahNumberInSurah, versesCount: position.surah.versesCount)
        guard store.write(value, named: "reading") else { return }
        readingReloadTask?.cancel()
        readingReloadTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            self?.reload(CompanionWidgets.readingKind)
        }
    }

    func flushReadingReload() {
        readingReloadTask?.cancel()
        reload(CompanionWidgets.readingKind)
    }
}
