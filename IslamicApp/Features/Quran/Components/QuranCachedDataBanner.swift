//
//  QuranCachedDataBanner.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QuranCachedDataBanner: View {
    let lastUpdated: Date?

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: "icloud.and.arrow.down")
                .foregroundStyle(AppColor.textPrimary)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(LocalizedKey.Common.showingCachedData)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                if let lastUpdated {
                    Text(LocalizedKey.Common.lastUpdated(DateFormatterFactory.shortTime().string(from: lastUpdated)))
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Spacer()
        }
        .padding(AppSpacing.small)
        .background(AppColor.cachedBanner, in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }
}
