//
//  PrayerTimeRow.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct PrayerTimeRow: View {
    let prayerTime: PrayerTime
    let isNext: Bool
    let timeZone: TimeZone

    var body: some View {
        HStack {
            Text(LocalizedKey.PrayerName.displayName(for: prayerTime.name))
                .font(.body.weight(isNext ? .semibold : .regular))
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(DateFormatterFactory.shortTime(timeZone: timeZone).string(from: prayerTime.date))
                .font(.body.weight(isNext ? .semibold : .regular))
                .foregroundStyle(isNext ? AppColor.textPrimary : AppColor.textSecondary)
        }
        .appRowStyle()
        .background(
            isNext ? AppColor.activePrayerBackground : Color.clear,
            in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        )
    }
}

/// Sunrise is displayed alongside prayer times but never styled as the next prayer.
struct SunriseTimeRow: View {
    let date: Date
    let timeZone: TimeZone

    var body: some View {
        HStack {
            Text(LocalizedKey.PrayerTimes.sunrise)
                .font(.body)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(DateFormatterFactory.shortTime(timeZone: timeZone).string(from: date))
                .font(.body)
                .foregroundStyle(AppColor.textSecondary)
        }
        .appRowStyle()
        .accessibilityElement(children: .combine)
    }
}
