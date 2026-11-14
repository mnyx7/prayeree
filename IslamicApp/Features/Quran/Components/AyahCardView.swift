//
//  AyahCardView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI
import UIKit

struct AyahCardView: View {
    let ayah: Ayah
    let readingMode: QuranReadingMode
    let fontScale: Double
    let onCopy: () -> Void
    let onShare: () -> Void
    let isFavorite: Bool
    let onFavorite: () -> Void

    @State private var copyCount = 0
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.small) {
            Text(ayah.arabicText)
                .font(AppTypography.arabicBody(scale: fontScale))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .lineSpacing(10)

            if readingMode == .arabicWithTranslation, let translation = ayah.translation {
                Text(translation)
                    .font(.system(size: 16 * fontScale))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack {
                Text(LocalizedKey.Quran.ayahNumber(ayah.ayahNumberInSurah))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(Text(isFavorite ? LocalizedKey.Quran.removeFavorite : LocalizedKey.Quran.addFavorite))
                .sensoryFeedback(.selection, trigger: isFavorite)
                Button {
                    onCopy()
                    isCopied = true
                    copyCount += 1
                    UIAccessibility.post(notification: .announcement, argument: String(localized: LocalizedKey.Common.copied))
                } label: {
                    Label(String(localized: isCopied ? LocalizedKey.Common.copied : LocalizedKey.Common.copy),
                          systemImage: isCopied ? "checkmark" : "doc.on.doc")
                }
                .sensoryFeedback(.success, trigger: copyCount)
                .task(id: copyCount) {
                    guard isCopied else { return }
                    do { try await Task.sleep(for: .seconds(2)) } catch { return }
                    isCopied = false
                }
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))
            }
            .foregroundStyle(AppColor.accent)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle()
    }

    private var shareText: String {
        let reference = String(localized: LocalizedKey.Quran.quranReference(surah: ayah.surahNumber, ayah: ayah.ayahNumberInSurah))
        if readingMode == .arabicWithTranslation, let translation = ayah.translation {
            return "\(ayah.arabicText)\n\n\(translation)\n\n— \(reference)"
        }
        return "\(ayah.arabicText)\n\n— \(reference)"
    }
}
