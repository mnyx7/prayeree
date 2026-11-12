import SwiftUI

struct DailyAyahCard: View {
    let ayah: Ayah
    let onOpenReader: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(LocalizedKey.Quran.ayahOfTheDay)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)

            Text(ayah.arabicText)
                .font(AppTypography.arabicBody(scale: 0.85))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineSpacing(8)

            if let translation = ayah.translation {
                Text(translation)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack {
                Text(LocalizedKey.Quran.quranReference(surah: ayah.surahNumber, ayah: ayah.ayahNumberInSurah))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button(String(localized: LocalizedKey.Quran.openInReader), action: onOpenReader)
                    .font(AppTypography.caption.weight(.semibold))
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))
            }
            .foregroundStyle(AppColor.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [AppColor.accent.opacity(0.15), AppColor.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .appShadow()
    }

    private var shareText: String {
        let reference = String(localized: LocalizedKey.Quran.quranReference(surah: ayah.surahNumber, ayah: ayah.ayahNumberInSurah))
        if let translation = ayah.translation {
            return "\(ayah.arabicText)\n\n\(translation)\n\n— \(reference)"
        }
        return "\(ayah.arabicText)\n\n— \(reference)"
    }
}
