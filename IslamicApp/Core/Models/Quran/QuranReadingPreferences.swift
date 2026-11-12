struct QuranReadingPreferences: Codable, Equatable, Sendable {
    var readingMode: QuranReadingMode
    var fontScale: Double
    var preferredTranslationId: Int?

    static let fontScaleRange: ClosedRange<Double> = 0.8...2.0

    static let `default` = QuranReadingPreferences(
        readingMode: .arabicWithTranslation,
        fontScale: 1.0,
        preferredTranslationId: nil
    )

    func withFontScale(_ newValue: Double) -> QuranReadingPreferences {
        var copy = self
        copy.fontScale = min(max(newValue, Self.fontScaleRange.lowerBound), Self.fontScaleRange.upperBound)
        return copy
    }
}
