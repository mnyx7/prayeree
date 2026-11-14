//
//  AppColor.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

/// Semantic tokens, not raw hex — every value is a distinct light/dark pair
/// defined in Assets.xcassets (not a `.opacity()` inversion of a single
/// color), per the Phase 11 dark-mode requirement.
enum AppColor {
    static let backgroundPrimary = Color("AppBackgroundPrimary")
    static let backgroundElevated = Color("AppBackgroundElevated")
    static let textPrimary = Color("AppTextPrimary")
    static let textSecondary = Color("AppTextSecondary")
    static let accent = Color("AccentColor")
    static let divider = Color("AppDivider")
    static let cachedBanner = Color("AppCachedBanner")
    static let warning = Color("AppWarning")
    static let error = Color("AppError")
    static let quranReadingBackground = Color("AppQuranReadingBackground")

    /// Derived from `accent` rather than its own asset — "active prayer" is
    /// structurally a use of the one controlled accent color, not an
    /// independent hue (see Phase 11's "avoid too many accent colors" rule).
    static var activePrayerBackground: Color { accent.opacity(0.12) }
}
