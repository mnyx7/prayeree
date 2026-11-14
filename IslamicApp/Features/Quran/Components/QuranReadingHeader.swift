//
//  QuranReadingHeader.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QuranReadingHeader: View {
    let selectedSurah: Surah?
    let selectedTranslation: QuranTranslation?
    let onSurahTapped: () -> Void
    let onTranslationTapped: () -> Void
    let onReadingSettingsTapped: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSurahTapped) {
                HStack {
                    Text(selectedSurah?.transliteratedName ?? String(localized: LocalizedKey.Quran.selectSurah))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
            }
            .buttonStyle(.bordered)

            HStack {
                Button(action: onTranslationTapped) {
                    Label(selectedTranslation?.name ?? String(localized: LocalizedKey.Quran.translation), systemImage: "text.book.closed")
                        .lineLimit(1)
                }
                Spacer()
                Button(action: onReadingSettingsTapped) {
                    Image(systemName: "textformat.size")
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
