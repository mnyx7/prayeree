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
}
