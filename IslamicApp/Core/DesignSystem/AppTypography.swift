import SwiftUI

enum AppTypography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline)
    static let body = Font.system(.body)
    static let subheadline = Font.system(.subheadline)
    static let caption = Font.system(.caption)
    static let caption2 = Font.system(.caption2)

    /// Uthmani Arabic text at a caller-supplied scale (font-size preference,
    /// 0.8–2.0 per QuranReadingPreferences) — the system font already ships
    /// a well-designed Arabic companion face, so no custom typeface is needed.
    static func arabicBody(scale: Double = 1.0) -> Font {
        .system(size: 26 * scale, weight: .regular)
    }
}
