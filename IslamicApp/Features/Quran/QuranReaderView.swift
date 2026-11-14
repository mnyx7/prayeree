//
//  QuranReaderView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QuranReaderView: View {
    @State private var store: QuranReaderStore

    init(store: QuranReaderStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        Group {
            switch content {
            case .loaded:
                QuranReadingContent(store: store)
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                AppErrorState(message: message) { store.send(.retryTapped) }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // A dedicated, slightly-warmer background than the rest of the app —
        // the reading area is meant to feel like its own spacious, focused
        // space, not just another list screen (Phase 11 requirement).
        .background(AppColor.quranReadingBackground)
        .navigationTitle(store.state.surah.transliteratedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { store.send(.surahFavoriteToggled) } label: {
                    Image(systemName: store.favorites.isFavorite(store.state.surah) ? "star.fill" : "star")
                }
                .accessibilityLabel(Text(store.favorites.isFavorite(store.state.surah) ? LocalizedKey.Quran.removeFavorite : LocalizedKey.Quran.addFavorite))
                .foregroundStyle(AppColor.accent)
                Button {
                    let nextMode: QuranReadingMode = store.state.readingMode == .arabicOnly ? .arabicWithTranslation : .arabicOnly
                    store.send(.readingModeChanged(nextMode))
                } label: {
                    Image(systemName: store.state.readingMode == .arabicOnly ? "text.book.closed" : "text.book.closed.fill")
                }
                .foregroundStyle(AppColor.accent)
            }
        }
        .task { store.send(.screenAppeared) }
    }

    private enum ContentKind {
        case loaded, loading, error(String)
    }

    private var content: ContentKind {
        if !store.state.ayahs.isEmpty { return .loaded }
        if let errorMessage = store.state.errorMessage { return .error(errorMessage) }
        return .loading
    }
}

/// Created only after the ayahs load, so loading placeholders cannot reset
/// the saved scroll target. Lazy layout reports the visible ayah, not preloaded cards.
private struct QuranReadingContent: View {
    let store: QuranReaderStore
    @State private var visibleAyahNumber: Int?

    init(store: QuranReaderStore) {
        self.store = store
        let target = store.state.ayahs.first { $0.ayahNumberInSurah == store.initialAyahNumber }
            ?? store.state.ayahs.first
        _visibleAyahNumber = State(initialValue: target?.ayahNumberInSurah)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                ForEach(store.state.ayahs) { ayah in
                    AyahCardView(
                        ayah: ayah,
                        readingMode: store.state.readingMode,
                        fontScale: store.state.fontScale,
                        onCopy: { store.send(.copyTapped(ayah)) },
                        onShare: { store.send(.shareTapped(ayah)) },
                        isFavorite: store.favorites.isFavorite(ayah),
                        onFavorite: { store.send(.bookmarkTapped(ayah)) }
                    )
                    .id(ayah.ayahNumberInSurah)
                }
            }
            .scrollTargetLayout()
            .padding()
        }
        .scrollPosition(id: $visibleAyahNumber, anchor: .top)
        .onChange(of: visibleAyahNumber, initial: true) { _, number in
            guard let number else { return }
            store.send(.readingPositionChanged(number))
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                if store.savesReadingProgress {
                    Label(String(localized: LocalizedKey.Quran.progressSaved), systemImage: "checkmark.circle")
                } else {
                    Text("Your reading place is preserved")
                    Button("Continue reading from here") { store.send(.startReadingHere) }
                        .buttonStyle(.bordered)
                }
                QuranCreditsView(translation: store.state.selectedTranslation)
            }
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
                .background(AppColor.quranReadingBackground)
        }
    }
}
