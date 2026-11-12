import Foundation

enum LocalizationManager {
    /// Whether the current app language reads right-to-left — drives layout
    /// mirroring decisions beyond SwiftUI's automatic ones (e.g. deciding
    /// whether to force RTL on Arabic Quran text regardless of app language).
    static var isRightToLeft: Bool {
        Locale.current.language.characterDirection == .rightToLeft
    }

    /// Builds a natural-language, VoiceOver-friendly countdown label with
    /// correct singular/plural minute handling. The on-screen "01:24" digit
    /// display isn't screen-reader-friendly ("zero one colon two four"), so
    /// this powers `.accessibilityLabel` instead of the visible Text.
    ///
    /// `String(localized:defaultValue:)` resolves the interpolated `minutes`
    /// argument against the String Catalog's plural variation for this key
    /// using the current locale's ICU plural rules — this is what makes
    /// Arabic's richer plural categories (zero/one/two/few/many/other) work
    /// correctly rather than a hand-rolled singular/plural-only check, which
    /// would produce wrong grammar for Arabic's 2/3–10/11+ forms.
    static func countdownAccessibilityLabel(prayerName: String, remainingSeconds: TimeInterval) -> String {
        let minutes = max(0, Int(remainingSeconds) / 60)
        return String(
            localized: "prayer_times.countdown_accessibility_format",
            defaultValue: "Next prayer: \(prayerName) in \(minutes) minutes",
            table: "Localizable"
        )
    }
}
