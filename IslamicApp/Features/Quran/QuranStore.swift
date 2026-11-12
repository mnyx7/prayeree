import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class QuranStore {
    struct State: Equatable, Sendable {
        var surahs: [Surah]
        var selectedSurah: Surah?
        var selectedAyah: Ayah?
        var availableAyahs: [Ayah]
        var dailyAyah: Ayah?
        var selectedTranslation: QuranTranslation?
        var availableTranslations: [QuranTranslation]
        var readingPreferences: QuranReadingPreferences
        var loadingState: LoadingState
        var freshness: DataFreshness
        var lastUpdated: Date?
        var activeSheet: ActiveSheet?
        var errorMessage: String?
        var recentSurahs: [Surah]
    }

    enum ActiveSheet: Identifiable, Equatable, Sendable {
        case surahPicker
        case ayahPicker
        case translationSelector
        case readingSettings

        var id: Self { self }
    }

    enum Action: Sendable {
        case dailyAyahRefreshRequested
        case screenAppeared
        case surahPickerTapped
        case surahSelected(Surah)
        case ayahPickerTapped
        case ayahSelected(Ayah)
        case translationSelectorTapped
        case translationSelected(QuranTranslation)
        case readerOpened(Surah)
        case surahsLoaded(QuranRepositoryResult<[Surah]>)
        case ayahsLoaded(QuranRepositoryResult<[Ayah]>)
        case translationsLoaded(QuranRepositoryResult<[QuranTranslation]>)
        case dailyAyahLoaded(QuranRepositoryResult<Ayah>)
        case readingSettingsTapped
        case readingModeChanged(QuranReadingMode)
        case fontScaleChanged(Double)
        case copyAyahTapped
        case shareAyahTapped
        case retryTapped
        case refreshRequested
        case sheetDismissed
    }

    private(set) var state: State
    private let repository: any QuranRepositoryProtocol
    private let preferencesStore: any PreferencesStore
    let languageCode: String

    private var surahsTask: Task<Void, Never>?
    private var ayahsTask: Task<Void, Never>?
    private var translationsTask: Task<Void, Never>?
    private var dailyAyahTask: Task<Void, Never>?

    private static let readingPreferencesKey = "quran.readingPreferences"
    private static let recentSurahsKey = "quran.recentSurahs"
    private static let maxRecents = 5

    init(repository: any QuranRepositoryProtocol, preferencesStore: any PreferencesStore, locale: Locale = .current) {
        self.repository = repository
        self.preferencesStore = preferencesStore
        self.languageCode = locale.language.languageCode?.identifier ?? "en"
        let savedPreferences = preferencesStore.value(for: Self.readingPreferencesKey, as: QuranReadingPreferences.self) ?? .default
        self.state = State(
            surahs: [],
            selectedSurah: nil,
            selectedAyah: nil,
            availableAyahs: [],
            dailyAyah: nil,
            selectedTranslation: nil,
            availableTranslations: [],
            readingPreferences: savedPreferences,
            loadingState: .idle,
            freshness: .none,
            lastUpdated: nil,
            activeSheet: nil,
            errorMessage: nil,
            recentSurahs: preferencesStore.value(for: Self.recentSurahsKey, as: [Surah].self) ?? []
        )
    }

    func send(_ action: Action) {
        switch action {
        case .dailyAyahRefreshRequested:
            loadDailyAyah()

        case .screenAppeared:
            if state.surahs.isEmpty { state.loadingState = .loading }
            loadSurahsIfNeeded()
            loadTranslationsIfNeeded()
            loadDailyAyah()

        case .surahPickerTapped:
            state.activeSheet = .surahPicker

        case .surahSelected(let surah):
            state.activeSheet = nil
            state.selectedSurah = surah
            state.selectedAyah = nil
            state.availableAyahs = []
            addToRecents(surah)
            loadAyahs()

        case .ayahPickerTapped:
            state.activeSheet = .ayahPicker

        case .ayahSelected(let ayah):
            state.activeSheet = nil
            state.selectedAyah = ayah

        case .translationSelectorTapped:
            state.activeSheet = .translationSelector

        case .translationSelected(let translation):
            state.activeSheet = nil
            state.selectedTranslation = translation
            state.readingPreferences.preferredTranslationId = translation.id
            persistReadingPreferences()
            if state.selectedSurah != nil { loadAyahs() }
            loadDailyAyah()

        case .readerOpened(let surah):
            addToRecents(surah)

        case .surahsLoaded(let result):
            if let surahs = result.value {
                state.surahs = surahs
                state.freshness = result.freshness
                state.lastUpdated = result.freshness.lastUpdated
                state.loadingState = .loaded
                state.errorMessage = nil
            } else {
                state.loadingState = .failed
                state.errorMessage = message(for: result.error)
            }

        case .ayahsLoaded(let result):
            if let ayahs = result.value {
                state.availableAyahs = ayahs
                state.selectedAyah = state.selectedAyah ?? ayahs.first
                state.freshness = result.freshness
                state.lastUpdated = result.freshness.lastUpdated
                state.loadingState = .loaded
                state.errorMessage = nil
            } else {
                state.loadingState = .failed
                state.errorMessage = message(for: result.error)
            }

        case .translationsLoaded(let result):
            guard let translations = result.value, !translations.isEmpty else { return }
            state.availableTranslations = translations
            if state.selectedTranslation == nil {
                let translationId = state.readingPreferences.preferredTranslationId ?? QuranTranslation.defaultID
                let translation = translations.first { $0.id == translationId }
                    ?? translations.first { $0.id == QuranTranslation.defaultID } ?? translations.first
                state.selectedTranslation = translation
                state.readingPreferences.preferredTranslationId = translation?.id
                persistReadingPreferences()
                if state.selectedSurah != nil { loadAyahs() }
                loadDailyAyah()
            }

        case .dailyAyahLoaded(let result):
            state.dailyAyah = result.value

        case .readingSettingsTapped:
            state.activeSheet = .readingSettings

        case .readingModeChanged(let mode):
            state.readingPreferences.readingMode = mode
            persistReadingPreferences()

        case .fontScaleChanged(let scale):
            state.readingPreferences = state.readingPreferences.withFontScale(scale)
            persistReadingPreferences()

        case .copyAyahTapped:
            if let ayah = state.selectedAyah {
                UIPasteboard.general.string = displayText(for: ayah)
            }

        case .shareAyahTapped:
            break // Sharing itself is presented natively via ShareLink in the View; reserved for future analytics.

        case .retryTapped, .refreshRequested:
            state.errorMessage = nil
            loadTranslationsIfNeeded()
            loadSurahsIfNeeded(force: true)
            if state.selectedSurah != nil { loadAyahs() }
            loadDailyAyah()

        case .sheetDismissed:
            state.activeSheet = nil
        }
    }

    // MARK: - Loading

    private func loadSurahsIfNeeded(force: Bool = false) {
        guard force || state.surahs.isEmpty else { return }
        surahsTask?.cancel()
        let stream = repository.surahs(languageCode: languageCode)
        surahsTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.surahsLoaded(result))
            }
        }
    }

    private func loadTranslationsIfNeeded() {
        guard state.availableTranslations.isEmpty else { return }
        translationsTask?.cancel()
        let stream = repository.translations()
        translationsTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.translationsLoaded(result))
            }
        }
    }

    private func loadDailyAyah() {
        dailyAyahTask?.cancel()
        let translationId = state.selectedTranslation?.id ?? QuranTranslation.defaultID
        let stream = repository.dailyAyah(date: Date(), translationId: translationId, languageCode: languageCode)
        dailyAyahTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.dailyAyahLoaded(result))
            }
        }
    }

    private func loadAyahs() {
        guard let surah = state.selectedSurah else { return }
        ayahsTask?.cancel()
        state.loadingState = .loading
        let translationId = state.selectedTranslation?.id ?? QuranTranslation.defaultID
        let stream = repository.ayahs(surahNumber: surah.id, translationId: translationId, languageCode: languageCode)
        ayahsTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.ayahsLoaded(result))
            }
        }
    }

    // MARK: - Reader factory

    /// QuranReaderStore is scoped to the reader's navigation lifetime (built
    /// fresh per surah), unlike the four tab-level Stores which live for the
    /// app's lifetime — composed here from already-injected dependencies,
    /// never raw concrete types.
    func makeReaderStore(for surah: Surah) -> QuranReaderStore {
        QuranReaderStore(
            surah: surah,
            repository: repository,
            preferencesStore: preferencesStore,
            initialTranslation: state.selectedTranslation,
            languageCode: languageCode
        )
    }

    // MARK: - Helpers

    private func addToRecents(_ surah: Surah) {
        var recents = state.recentSurahs.filter { $0.id != surah.id }
        recents.insert(surah, at: 0)
        if recents.count > Self.maxRecents {
            recents = Array(recents.prefix(Self.maxRecents))
        }
        state.recentSurahs = recents
        preferencesStore.setValue(recents, for: Self.recentSurahsKey)
    }

    private func persistReadingPreferences() {
        preferencesStore.setValue(state.readingPreferences, for: Self.readingPreferencesKey)
    }

    private func displayText(for ayah: Ayah) -> String {
        if let translation = ayah.translation, state.readingPreferences.readingMode == .arabicWithTranslation {
            return "\(ayah.arabicText)\n\n\(translation)\n\n— Quran \(ayah.surahNumber):\(ayah.ayahNumberInSurah)"
        }
        return "\(ayah.arabicText)\n\n— Quran \(ayah.surahNumber):\(ayah.ayahNumberInSurah)"
    }

    private func message(for error: NetworkError?) -> String {
        switch error {
        case .none:
            return String(localized: LocalizedKey.Common.genericLoadError())
        case .invalidURL, .invalidResponse, .decodingFailed:
            return String(localized: LocalizedKey.Quran.errorLoadFailed)
        case .httpStatus:
            return String(localized: LocalizedKey.Common.serviceUnavailableError())
        case .transportError, .cancelled:
            return String(localized: LocalizedKey.Common.networkLoadError())
        }
    }
}
