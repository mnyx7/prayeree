//
//  AppCard.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct AppCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .appCardStyle()
    }
}

extension View {
    /// Applies the card treatment to an existing view hierarchy directly —
    /// used by feature components (PrayerSummaryCard, AyahCardView, ...)
    /// instead of wrapping in `AppCard` when they already own their own layout.
    func appCardStyle() -> some View {
        self
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.backgroundElevated, in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
            .appShadow()
    }
}
