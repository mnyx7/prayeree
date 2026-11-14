//
//  QuranReaderStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class QuranReaderStore {
    struct State: Equatable, Sendable {
        var surah: Surah
        var ayahs: [Ayah]
        var selectedTranslation: QuranTranslation?
        var readingMode: QuranReadingMode
        var fontScale: Double
        var currentReadingPosition: Int?
        var loadingState: LoadingState
        var freshness: DataFreshness
        var errorMessage: String?
    }

    enum Action: Sendable {
        case screenAppeared
        case ayahsLoaded(QuranRepositoryResult<[Ayah]>)
        case fontScaleChanged(Double)
        case readingModeChanged(QuranReadingMode)
        case translationChanged(QuranTranslation)
        case ayahAppeared(Ayah)
        case readingPositionChanged(Int)
        case copyTapped(Ayah)
        case shareTapped(Ayah)
        case surahFavoriteToggled
        case bookmarkTapped(Ayah)
        case retryTapped
    }

    private(set) var state: State
    private let repository: any QuranRepositoryProtocol
    private let preferencesStore: any PreferencesStore
    private let languageCode: String
    private var loadTask: Task<Void, Never>?
    let initialAyahNumber: Int
    let favorites: QuranFavoritesStore

    private static let readingPreferencesKey = "quran.readingPreferences"

    init(
        surah: Surah,
        repository: any QuranRepositoryProtocol,
        preferencesStore: any PreferencesStore,
        initialTranslation: QuranTranslation?,
        languageCode: String,
        startingAyahNumber: Int? = nil,
        favorites: QuranFavoritesStore? = nil
    ) {
        self.repository = repository
        self.preferencesStore = preferencesStore
        self.favorites = favorites ?? QuranFavoritesStore(preferencesStore: preferencesStore)
        self.languageCode = languageCode
        let savedPreferences = preferencesStore.value(for: Self.readingPreferencesKey, as: QuranReadingPreferences.self) ?? .default
        let savedPosition = preferencesStore.value(
            for: QuranReadingPosition.storageKey(for: surah.id), as: QuranReadingPosition.self
        )
        let savedAyah = savedPosition.flatMap { $0.isValid && $0.surah.id == surah.id ? $0.ayahNumberInSurah : nil }
        let requestedAyah = startingAyahNumber.flatMap { $0 > 0 && $0 <= surah.versesCount ? $0 : nil }
        self.initialAyahNumber = requestedAyah ?? savedAyah ?? 1
        self.state = State(
            surah: surah,
            ayahs: [],
            selectedTranslation: initialTranslation,
            readingMode: savedPreferences.readingMode,
            fontScale: savedPreferences.fontScale,
            currentReadingPosition: requestedAyah ?? savedAyah,
            loadingState: .idle,
            freshness: .none,
            errorMessage: nil
        )
    }

    func send(_ action: Action) {
        switch action {
        case .screenAppeared:
            loadAyahs()

        case .ayahsLoaded(let result):
            if let ayahs = result.value {
                state.ayahs = ayahs
                state.freshness = result.freshness
                state.loadingState = .loaded
                state.errorMessage = nil
            } else {
                state.loadingState = .failed
                state.errorMessage = message(for: result.error)
            }

        case .fontScaleChanged(let scale):
            let range = QuranReadingPreferences.fontScaleRange
            state.fontScale = min(max(scale, range.lowerBound), range.upperBound)
            persistPreferences()

        case .readingModeChanged(let mode):
            state.readingMode = mode
            persistPreferences()

        case .translationChanged(let translation):
            state.selectedTranslation = translation
            loadAyahs()

        case .ayahAppeared(let ayah):
            guard ayah.surahNumber == state.surah.id else { return }
            saveReadingPosition(ayah.ayahNumberInSurah)

        case .readingPositionChanged(let number):
            saveReadingPosition(number)

        case .copyTapped(let ayah):
            UIPasteboard.general.string = displayText(for: ayah)

        case .shareTapped:
            break // Sharing itself is presented natively via ShareLink in the View; reserved for future analytics.

        case .surahFavoriteToggled:
            favorites.toggleSurah(state.surah)

        case .bookmarkTapped(let ayah):
            guard ayah.surahNumber == state.surah.id else { return }
            favorites.toggleAyah(QuranFavoriteAyah(surah: state.surah, ayahNumberInSurah: ayah.ayahNumberInSurah))

        case .retryTapped:
            loadAyahs()
        }
    }

    private func loadAyahs() {
        loadTask?.cancel()
        state.loadingState = .loading
        state.errorMessage = nil
        let translationId = state.selectedTranslation?.id ?? QuranTranslation.defaultID
        let stream = repository.ayahs(surahNumber: state.surah.id, translationId: translationId, languageCode: languageCode)
        loadTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.ayahsLoaded(result))
            }
        }
    }

    private func persistPreferences() {
        let preferences = QuranReadingPreferences(
            readingMode: state.readingMode,
            fontScale: state.fontScale,
            preferredTranslationId: state.selectedTranslation?.id
        )
        preferencesStore.setValue(preferences, for: Self.readingPreferencesKey)
    }

    private func saveReadingPosition(_ number: Int) {
        let position = QuranReadingPosition(surah: state.surah, ayahNumberInSurah: number)
        guard position.isValid else { return }
        state.currentReadingPosition = number
        // Write as the reader scrolls, so force-closing the app does not lose progress.
        preferencesStore.setValue(position, for: QuranReadingPosition.storageKey(for: state.surah.id))
        preferencesStore.setValue(position, for: QuranReadingPosition.lastReadKey)
    }

    private func displayText(for ayah: Ayah) -> String {
        if let translation = ayah.translation, state.readingMode == .arabicWithTranslation {
            return "\(ayah.arabicText)\n\n\(translation)\n\n— \(state.surah.transliteratedName) \(ayah.surahNumber):\(ayah.ayahNumberInSurah)"
        }
        return "\(ayah.arabicText)\n\n— \(state.surah.transliteratedName) \(ayah.surahNumber):\(ayah.ayahNumberInSurah)"
    }

    private func message(for error: NetworkError?) -> String {
        switch error {
        case .none:
            return String(localized: LocalizedKey.Common.genericLoadError())
        case .invalidURL, .invalidResponse, .decodingFailed:
            return String(localized: LocalizedKey.Quran.errorSurahLoadFailed)
        case .httpStatus:
            return String(localized: LocalizedKey.Common.serviceUnavailableError())
        case .transportError, .cancelled:
            return String(localized: LocalizedKey.Common.networkLoadError())
        }
    }
}
