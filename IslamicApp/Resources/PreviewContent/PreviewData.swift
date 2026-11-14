//
//  PreviewData.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// Representative sample data for SwiftUI canvas previews across all four
/// features — kept separate from PreviewEnvironment.swift (which builds the
/// fake AppEnvironment) since this file has no dependency on Core/App types
/// beyond the domain models themselves.
enum PreviewData {
    static let coordinates = QiblaCalculator.kaaba

    static let country = Country(code: "SA")

    static let city = City(
        id: "SA-mecca",
        name: "Mecca",
        countryCode: "SA",
        coordinates: coordinates,
        timeZoneIdentifier: "Asia/Riyadh"
    )

    static let hijriDate = HijriDate(day: 12, month: .ramadan, year: 1447)

    static let prayerTimes: PrayerTimes = {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        func time(_ hour: Int, _ minute: Int, _ name: PrayerName) -> PrayerTime {
            var components = calendar.dateComponents([.year, .month, .day], from: today)
            components.hour = hour
            components.minute = minute
            return PrayerTime(name: name, date: calendar.date(from: components) ?? today)
        }
        return PrayerTimes(
            date: today,
            hijriDate: hijriDate,
            times: [
                time(5, 12, .fajr),
                time(12, 15, .dhuhr),
                time(15, 30, .asr),
                time(18, 42, .maghrib),
                time(20, 5, .isha)
            ],
            coordinates: coordinates,
            calculationMethod: .ummAlQura,
            madhab: .shafiMalikiHanbali,
            timeZoneIdentifier: "Asia/Riyadh"
        )
    }()

    static let surah = Surah(
        id: 1,
        arabicName: "الفاتحة",
        transliteratedName: "Al-Fatihah",
        englishTranslatedName: "The Opener",
        versesCount: 7,
        revelationPlace: .makkah
    )

    static let translation = QuranTranslation(id: 131, languageCode: "english", name: "Saheeh International")

    static let ayah = Ayah(
        surahNumber: 1,
        ayahNumberInSurah: 1,
        arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        translation: "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
        translationId: 131
    )

    static let dailyAyah = DailyAyah(date: Date(), ayah: ayah)
}
