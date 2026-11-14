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
