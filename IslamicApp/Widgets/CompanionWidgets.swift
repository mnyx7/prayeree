//
//  CompanionWidgets.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI
import WidgetKit

@main
struct CompanionWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        DailyAyahWidget()
        ContinueReadingWidget()
    }
}

private let widgetAccent = Color(red: 0.06, green: 0.48, blue: 0.42)

struct CompanionEntry: TimelineEntry {
    let date: Date
    var prayers: WidgetPrayerSnapshot? = nil
    var ayah: WidgetAyahSnapshot? = nil
    var reading: WidgetReadingSnapshot? = nil
}

private enum WidgetPreview {
    static var prayer: WidgetPrayerSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.startOfDay(for: Date())
        let names = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
        let hours = [5, 12, 15, 18, 20]
        let prayers = zip(names, hours).map { WidgetPrayer(name: $0.0, date: Date().addingTimeInterval(Double($0.1) * 600)) }
        return WidgetPrayerSnapshot(cityName: "Baku", timeZoneIdentifier: TimeZone.current.identifier, days: [WidgetPrayerDay(date: date, prayers: prayers)])
    }
    static let reading = WidgetReadingSnapshot(surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 25, versesCount: 286)
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry { CompanionEntry(date: Date(), prayers: WidgetPreview.prayer) }
    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : CompanionEntry(date: Date(), prayers: WidgetFileStore().read("prayers", as: WidgetPrayerSnapshot.self)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetFileStore().read("prayers", as: WidgetPrayerSnapshot.self)
        let dates = snapshot?.timelineDates(from: now) ?? [now]
        let entries = dates.map { CompanionEntry(date: $0, prayers: snapshot) }
        completion(Timeline(entries: entries, policy: .after((dates.last ?? now).addingTimeInterval(15 * 60))))
    }
}

struct DailyAyahProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry {
        CompanionEntry(date: Date(), ayah: WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(Date()), surahNumber: 1, ayahNumber: 1, arabicText: "", translation: nil, preferences: WidgetQuranPreferences()))
    }
    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        let now = Date()
        let store = WidgetFileStore()
        let prefs = store.read("quranPreferences", as: WidgetQuranPreferences.self) ?? WidgetQuranPreferences()
        let cached = store.read("dailyAyah", as: WidgetAyahSnapshot.self)
        completion(CompanionEntry(date: now, ayah: cached?.isCurrent(at: now, preferences: prefs) == true ? cached : nil))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        Task {
            let now = Date()
            let store = WidgetFileStore()
            let prefs = store.read("quranPreferences", as: WidgetQuranPreferences.self) ?? WidgetQuranPreferences()
            var value = store.read("dailyAyah", as: WidgetAyahSnapshot.self)
            if value?.isCurrent(at: now, preferences: prefs) != true { value = nil }
            if value == nil {
                let service = QuranService(apiClient: APIClient())
                if let reference = try? await service.dailyAyahReference(date: now, languageCode: prefs.languageCode) {
                    let fresh = WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(now), surahNumber: reference.surah, ayahNumber: reference.ayah, arabicText: "", translation: nil, preferences: prefs)
                    store.write(fresh, named: "dailyAyah")
                    value = fresh
                }
            }
            let calendar = Calendar(identifier: .gregorian)
            let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86400)
            // Expire yesterday's verse even if WidgetKit delays the next network refresh.
            let entries = [CompanionEntry(date: now, ayah: value), CompanionEntry(date: midnight)]
            completion(Timeline(entries: entries, policy: .after(value == nil ? min(midnight, now.addingTimeInterval(15 * 60)) : midnight)))
        }
    }
}

struct ReadingProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry { CompanionEntry(date: Date(), reading: WidgetPreview.reading) }
    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(Date().addingTimeInterval(3600))))
    }
    private func entry() -> CompanionEntry {
        let value = WidgetFileStore().read("reading", as: WidgetReadingSnapshot.self)
        return CompanionEntry(date: Date(), reading: value?.isValid == true ? value : nil)
    }
}

private struct WidgetEmptyView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundStyle(widgetAccent)
            Text(title).font(.headline)
            Text(message).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct PrayerWidgetView: View {
    let entry: CompanionEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if let snapshot = entry.prayers, let next = snapshot.nextPrayer(after: entry.date) {
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Next prayer", systemImage: "sun.horizon").font(.caption).foregroundStyle(widgetAccent)
                        Text(LocalizedStringKey("prayer." + next.name)).font(.title2.weight(.semibold))
                        Text(next.date, style: .time).font(.title.weight(.bold)).monospacedDigit()
                        Text(timerInterval: entry.date...next.date, countsDown: true)
                            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Text(snapshot.cityName).font(.caption).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if family == .systemMedium {
                        VStack(spacing: 5) {
                            ForEach(snapshot.prayers(on: entry.date), id: \.name) { prayer in
                                HStack {
                                    Text(LocalizedStringKey("prayer." + prayer.name))
                                    Spacer()
                                    Text(prayer.date, style: .time).monospacedDigit()
                                }
                                .font(.caption)
                                .fontWeight(prayer.date == next.date ? .bold : .regular)
                                .foregroundStyle(prayer.date == next.date ? widgetAccent : .primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .environment(\.timeZone, snapshot.timeZone)
            } else {
                WidgetEmptyView(title: "Prayer times", message: "Open the app to set or refresh your location.", icon: "sun.horizon")
            }
        }
        .widgetURL(WidgetRoute.prayerTimes.url)
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

struct AyahWidgetView: View {
    let entry: CompanionEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if let ayah = entry.ayah {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Ayah of the Day", systemImage: "book.closed").font(.caption.weight(.semibold)).foregroundStyle(widgetAccent)
                    Text("Open today's ayah")
                        .font(.headline)
                    Text("Tap to read Quran online.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    HStack {
                        Text("\(ayah.surahNumber):\(ayah.ayahNumber)").font(.caption2).monospacedDigit()
                        Spacer()
                        Text("Quran.Foundation").font(.system(size: 9)).foregroundStyle(.secondary)
                    }

                }
                .widgetURL(WidgetRoute.dailyAyah(surah: ayah.surahNumber, ayah: ayah.ayahNumber).url)
            } else {
                WidgetEmptyView(title: "Ayah of the Day", message: "Open Quran or connect to the internet to load today's ayah.", icon: "book.closed")
                    .widgetURL(WidgetRoute.quran.url)
            }
        }
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

struct ReadingWidgetView: View {
    let entry: CompanionEntry
    var body: some View {
        Group {
            if let position = entry.reading {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Continue reading", systemImage: "book.bookmark").font(.caption.weight(.semibold)).foregroundStyle(widgetAccent)
                    Spacer(minLength: 0)
                    Text(position.surahName).font(.title2.weight(.semibold)).lineLimit(2)
                    Text("Ayah \(position.ayahNumber)").font(.subheadline).foregroundStyle(.secondary)
                    ProgressView(value: position.progress).tint(widgetAccent)
                    Text("Tap to resume").font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                WidgetEmptyView(title: "Continue reading", message: "Read a surah in the app to save your place.", icon: "book.bookmark")
            }
        }
        .privacySensitive()
        .widgetURL(WidgetRoute.continueReading.url)
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

struct PrayerTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CompanionWidgets.prayerKind, provider: PrayerProvider()) { PrayerWidgetView(entry: $0) }
            .configurationDisplayName("Prayer times")
            .description("See the next namaz and your daily prayer schedule.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyAyahWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CompanionWidgets.ayahKind, provider: DailyAyahProvider()) { AyahWidgetView(entry: $0) }
            .configurationDisplayName("Ayah of the Day")
            .description("Open today's ayah from its daily reference.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ContinueReadingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CompanionWidgets.readingKind, provider: ReadingProvider()) { ReadingWidgetView(entry: $0) }
            .configurationDisplayName("Continue reading")
            .description("Return to the surah and ayah where you stopped.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    PrayerTimesWidget()
} timeline: {
    CompanionEntry(date: Date(), prayers: WidgetPreview.prayer)
}

#Preview(as: .systemLarge) {
    DailyAyahWidget()
} timeline: {
    CompanionEntry(date: Date(), ayah: WidgetAyahSnapshot(dayKey: CompanionWidgets.dayKey(Date()), surahNumber: 1, ayahNumber: 1, arabicText: "", translation: nil, preferences: WidgetQuranPreferences()))
}

#Preview(as: .systemSmall) {
    ContinueReadingWidget()
} timeline: {
    CompanionEntry(date: Date(), reading: WidgetPreview.reading)
}
