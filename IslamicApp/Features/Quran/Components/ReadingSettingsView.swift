import SwiftUI

struct ReadingSettingsView: View {
    let readingMode: QuranReadingMode
    let fontScale: Double
    let onReadingModeChanged: (QuranReadingMode) -> Void
    let onFontScaleChanged: (Double) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(String(localized: LocalizedKey.Quran.readingModeSection), selection: Binding(get: { readingMode }, set: onReadingModeChanged)) {
                        Text(LocalizedKey.Quran.arabicOnly).tag(QuranReadingMode.arabicOnly)
                        Text(LocalizedKey.Quran.arabicWithTranslation).tag(QuranReadingMode.arabicWithTranslation)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(LocalizedKey.Quran.readingModeSection)
                }

                Section {
                    Slider(
                        value: Binding(get: { fontScale }, set: onFontScaleChanged),
                        in: QuranReadingPreferences.fontScaleRange
                    )
                    // Fixed sample text demonstrating the chosen font size —
                    // always Arabic regardless of app language, not a UI label.
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: 22 * fontScale))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                } header: {
                    Text(LocalizedKey.Quran.fontSize)
                }
            }
            .navigationTitle(Text(LocalizedKey.Quran.readingSettings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: LocalizedKey.Common.done), action: onDismiss)
                }
            }
        }
    }
}
