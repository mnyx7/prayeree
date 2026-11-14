//
//  QuranStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
@testable import IslamicApp

@MainActor
final class QuranStoreTests: XCTestCase {
    private func makeStore(testEnv: TestEnvironment) -> QuranStore {
        let repository = QuranRepository(
            service: QuranService(apiClient: testEnv.apiClient),
            cacheStore: testEnv.cacheStore
        )
        return QuranStore(repository: repository, preferencesStore: testEnv.preferencesStore, locale: Locale(identifier: "en"))
    }

    private func installStandardHandler(on apiClient: MockAPIClient) {
        apiClient.handler = { endpoint in
            if endpoint is QuranChaptersEndpoint {
                return QuranChaptersResponseDTO(chapters: [
                    QuranChapterDTO(id: 1, revelationPlace: "makkah", versesCount: 7, nameSimple: "Al-Fatihah", nameArabic: "الفاتحة", translatedName: QuranTranslatedNameDTO(name: "The Opener"))
                ])
            }
            if endpoint is QuranTranslationsEndpoint {
                return QuranTranslationsResponseDTO(translations: [
                    QuranTranslationResourceDTO(id: 131, languageName: "english", name: "Saheeh International")
                ])
            }
            if endpoint is QuranVerseByKeyEndpoint {
                return QuranRandomVerseResponseDTO(
                    verse: QuranVerseDTO(verseNumber: 1, verseKey: "1:1", textUthmani: "بِسْمِ اللَّهِ", translations: [
                        QuranVerseTranslationDTO(resourceId: 131, text: "In the name of Allah")
                    ])
                )
            }
            if endpoint is QuranVersesByChapterEndpoint {
                return QuranVersesResponseDTO(verses: [
                    QuranVerseDTO(verseNumber: 1, verseKey: "1:1", textUthmani: "بِسْمِ اللَّهِ", translations: [
                        QuranVerseTranslationDTO(resourceId: 131, text: "In the name of Allah")
                    ]),
                    QuranVerseDTO(verseNumber: 2, verseKey: "1:2", textUthmani: "الْحَمْدُ لِلَّهِ", translations: [
                        QuranVerseTranslationDTO(resourceId: 131, text: "Praise be to Allah")
                    ])
                ])
            }
            throw NetworkError.invalidResponse
        }
    }

    func testScreenAppearedLoadsSurahsTranslationsAndDailyAyah() async {
        let testEnv = TestEnvironmentFactory.make()
        installStandardHandler(on: testEnv.apiClient)
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.state.surahs.count, 1)
        XCTAssertEqual(store.state.availableTranslations.count, 1)
        XCTAssertNotNil(store.state.dailyAyah)
        XCTAssertEqual(store.state.selectedTranslation?.id, 131)
    }

    func testSurahSelectedLoadsAyahsAndUpdatesRecents() async {
        let testEnv = TestEnvironmentFactory.make()
        installStandardHandler(on: testEnv.apiClient)
        let store = makeStore(testEnv: testEnv)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)

        store.send(.surahSelected(surah))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.state.availableAyahs.count, 2)
        XCTAssertEqual(store.state.selectedAyah?.ayahNumberInSurah, 1)
        XCTAssertEqual(store.state.recentSurahs.first, surah)
    }

    func testTranslationSelectedPersistsPreference() async {
        let testEnv = TestEnvironmentFactory.make()
        installStandardHandler(on: testEnv.apiClient)
        let store = makeStore(testEnv: testEnv)
        let translation = QuranTranslation(id: 20, languageCode: "french", name: "French Translation")

        store.send(.translationSelected(translation))
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.state.selectedTranslation, translation)
        XCTAssertEqual(
            testEnv.preferencesStore.value(for: "quran.readingPreferences", as: QuranReadingPreferences.self)?.preferredTranslationId,
            20
        )
    }

    func testMakeReaderStoreUsesRequestedSurah() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let surah = Surah(id: 2, arabicName: "البقرة", transliteratedName: "Al-Baqarah", englishTranslatedName: "The Cow", versesCount: 286, revelationPlace: .madinah)

        let readerStore = store.makeReaderStore(for: surah)

        XCTAssertEqual(readerStore.state.surah, surah)
    }

    func testContinueReadingAvailableAfterRelaunchWithoutLoadingSurahs() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        let surah = Surah(id: 2, arabicName: "البقرة", transliteratedName: "Al-Baqarah", englishTranslatedName: "The Cow", versesCount: 286, revelationPlace: .madinah)
        home.makeReaderStore(for: surah).send(.readingPositionChanged(120))
        home.send(.readingProgressChanged)
        XCTAssertEqual(home.state.lastReadingPosition?.ayahNumberInSurah, 120)

        let relaunchedHome = makeStore(testEnv: env)
        XCTAssertTrue(relaunchedHome.state.surahs.isEmpty)
        XCTAssertEqual(relaunchedHome.state.lastReadingPosition?.surah, surah)
        XCTAssertEqual(relaunchedHome.makeReaderStore(for: surah).initialAyahNumber, 120)
        XCTAssertTrue(env.apiClient.requestedEndpoints.isEmpty)
    }

    func testInvalidSavedReadingPositionDoesNotShowContinueReading() {
        let env = TestEnvironmentFactory.make()
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        env.preferencesStore.setValue(QuranReadingPosition(surah: surah, ayahNumberInSurah: 999), for: QuranReadingPosition.lastReadKey)
        XCTAssertNil(makeStore(testEnv: env).state.lastReadingPosition)
    }

    func testChoosingAnAyahOnTheQuranPageAlsoSavesProgress() {
        let env = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: env)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        store.send(.surahSelected(surah))
        store.send(.ayahSelected(Ayah(surahNumber: 1, ayahNumberInSurah: 4, arabicText: "", translation: nil, translationId: nil)))
        XCTAssertEqual(makeStore(testEnv: env).state.lastReadingPosition?.ayahNumberInSurah, 4)
        XCTAssertEqual(store.makeReaderStore(for: surah).initialAyahNumber, 4)
    }

    func testFavoriteSurahsPersistAndCanBeRemoved() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        home.favorites.toggleSurah(surah)
        let reopened = makeStore(testEnv: env)
        XCTAssertEqual(reopened.favorites.surahs, [surah])
        reopened.favorites.toggleSurah(surah)
        XCTAssertTrue(makeStore(testEnv: env).favorites.surahs.isEmpty)
    }

    func testReaderSharesFavoritesWithHomeAndAyahsOpenAtTheirSavedReference() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        let reader = home.makeReaderStore(for: surah)
        let ayah = Ayah(surahNumber: 1, ayahNumberInSurah: 4, arabicText: "", translation: nil, translationId: 20)
        reader.send(.surahFavoriteToggled)
        reader.send(.bookmarkTapped(ayah))
        XCTAssertTrue(home.favorites.isFavorite(surah))
        XCTAssertTrue(home.favorites.isFavorite(ayah))
        let reopened = makeStore(testEnv: env)
        let saved = reopened.favorites.ayahs.first!
        XCTAssertEqual(saved.ayahNumberInSurah, 4)
        XCTAssertEqual(reopened.makeReaderStore(for: saved.surah, startingAyahNumber: saved.ayahNumberInSurah).initialAyahNumber, 4)
        home.favorites.removeAyah(saved)
        XCTAssertFalse(reader.favorites.isFavorite(ayah))
        XCTAssertTrue(home.favorites.isFavorite(surah))
    }

    func testAyahFavoriteIsIndependentOfTranslationAndReadingProgress() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        let reader = home.makeReaderStore(for: surah)
        reader.send(.readingPositionChanged(5))
        reader.send(.bookmarkTapped(Ayah(surahNumber: 1, ayahNumberInSurah: 2, arabicText: "", translation: nil, translationId: 20)))
        let translated = Ayah(surahNumber: 1, ayahNumberInSurah: 2, arabicText: "", translation: nil, translationId: 85)
        XCTAssertTrue(home.favorites.isFavorite(translated))
        reader.send(.bookmarkTapped(translated))
        XCTAssertTrue(home.favorites.ayahs.isEmpty)
        XCTAssertEqual(home.makeReaderStore(for: surah).initialAyahNumber, 5)
    }

    func testFavoriteValidationRejectsInvalidOrMismatchedAyahs() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
        let reader = home.makeReaderStore(for: surah)
        reader.send(.bookmarkTapped(Ayah(surahNumber: 1, ayahNumberInSurah: 8, arabicText: "", translation: nil, translationId: nil)))
        reader.send(.bookmarkTapped(Ayah(surahNumber: 2, ayahNumberInSurah: 1, arabicText: "", translation: nil, translationId: nil)))
        XCTAssertTrue(home.favorites.ayahs.isEmpty)
    }

    func testFavoritesMenuOpensWithoutNetworkData() {
        let env = TestEnvironmentFactory.make()
        let home = makeStore(testEnv: env)
        home.send(.favoritesTapped)
        XCTAssertEqual(home.state.activeSheet, .favorites)
        XCTAssertTrue(env.apiClient.requestedEndpoints.isEmpty)
    }

    func testAyahWidgetDeepLinkWaitsForSurahMetadataThenTargetsExactAyah() async {
        let env = TestEnvironmentFactory.make()
        installStandardHandler(on: env.apiClient)
        let store = makeStore(testEnv: env)
        store.send(.widgetAyahRequested(1, 4))
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(store.state.readerRequest?.surah.id, 1)
        XCTAssertEqual(store.state.readerRequest?.ayahNumberInSurah, 4)
        XCTAssertFalse(store.state.readerRequestSavesProgress)
        store.send(.readerRequestHandled)
        XCTAssertNil(store.state.readerRequest)
    }

    func testContinueReadingWidgetWithoutProgressDoesNotFetchOrInventPosition() {
        let env = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: env)
        store.send(.widgetContinueReadingRequested)
        XCTAssertNil(store.state.readerRequest)
        XCTAssertTrue(store.state.readerRequestSavesProgress)
        XCTAssertTrue(env.apiClient.requestedEndpoints.isEmpty)
    }
}
