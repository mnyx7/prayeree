//
//  SurahPickerView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct SurahPickerView: View {
    let surahs: [Surah]
    let recentSurahs: [Surah]
    let onSelect: (Surah) -> Void
    let onDismiss: () -> Void
    let favorites: QuranFavoritesStore

    @State private var query = ""

    var body: some View {
        NavigationStack {
            SurahListView(surahs: surahs, recentSurahs: recentSurahs, searchQuery: query, onSelect: onSelect, favoriteSurahs: favorites.surahs, onFavoriteToggled: favorites.toggleSurah)
                .navigationTitle(Text(LocalizedKey.Quran.selectSurah))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: LocalizedKey.Common.cancel), action: onDismiss)
                    }
                }
        }
        .searchable(text: $query, placement: .automatic, prompt: Text(LocalizedKey.Quran.searchSurah))
    }
}
