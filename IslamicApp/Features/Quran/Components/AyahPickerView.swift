import SwiftUI

struct AyahPickerView: View {
    let ayahs: [Ayah]
    let onSelect: (Ayah) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List(ayahs) { ayah in
                Button {
                    onSelect(ayah)
                } label: {
                    HStack {
                        Text(LocalizedKey.Quran.ayahNumber(ayah.ayahNumberInSurah))
                        Spacer()
                        if let translation = ayah.translation {
                            Text(translation)
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(Text(LocalizedKey.Quran.selectAyah))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedKey.Common.cancel), action: onDismiss)
                }
            }
        }
    }
}
