//
//  PrayerSummaryCard.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct PrayerSummaryCard: View {
    let cityName: String
    let selectedDate: Date
    let hijriDate: HijriDate?
    let nextPrayer: PrayerTime?
    let remainingCountdown: TimeInterval
    let onDateTapped: () -> Void
    let onLocationTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            PrayerDateLocationHeader(
                cityName: cityName,
                gregorianDate: selectedDate,
                hijriDate: hijriDate,
                onDateTapped: onDateTapped,
                onLocationTapped: onLocationTapped
            )
            PrayerCountdownView(nextPrayer: nextPrayer, remaining: remainingCountdown)
        }
        .appCardStyle()
    }
}
