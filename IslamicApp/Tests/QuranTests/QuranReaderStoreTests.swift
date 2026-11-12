import XCTest
@testable import IslamicApp

@MainActor
final class QuranReaderStoreTests: XCTestCase {
    private let surah = Surah(id: 1, arabicName: "الفاتحة", transliteratedName: "Al-Fatihah", englishTranslatedName: "The Opener", versesCount: 7, revelationPlace: .makkah)
    private let translation = QuranTranslation(id: 131, languageCode: "english", name: "Saheeh International")

    private func makeStore(testEnv: TestEnvironment) -> QuranReaderStore {
        let repository = QuranRepository(
            service: QuranService(apiClient: testEnv.apiClient),
            cacheStore: testEnv.cacheStore
        )
        return QuranReaderStore(
            surah: surah,
            repository: repository,
            preferencesStore: testEnv.preferencesStore,
            initialTranslation: translation,
            languageCode: "en"
        )
    }

    private func installAyahsHandler(on apiClient: MockAPIClient, shouldFail: Bool = false) {
        apiClient.handler = { _ in
            if shouldFail { throw NetworkError.httpStatus(500) }
            return QuranVersesResponseDTO(verses: [
                QuranVerseDTO(verseNumber: 1, verseKey: "1:1", textUthmani: "بِسْمِ اللَّهِ", translations: [
                    QuranVerseTranslationDTO(resourceId: 131, text: "In the name of Allah")
                ])
            ])
        }
    }

    func testScreenAppearedLoadsAyahs() async {
        let testEnv = TestEnvironmentFactory.make()
        installAyahsHandler(on: testEnv.apiClient)
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.state.ayahs.count, 1)
        XCTAssertEqual(store.state.loadingState, .loaded)
    }

    func testRetryAfterFailureRecovers() async {
        let testEnv = TestEnvironmentFactory.make()
        installAyahsHandler(on: testEnv.apiClient, shouldFail: true)
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertNotNil(store.state.errorMessage)
        XCTAssertTrue(store.state.ayahs.isEmpty)

        installAyahsHandler(on: testEnv.apiClient, shouldFail: false)
        store.send(.retryTapped)
        try? await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(store.state.ayahs.count, 1)
        XCTAssertNil(store.state.errorMessage)
    }

    func testFontScaleChangedClampsToValidRange() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)

        store.send(.fontScaleChanged(10.0))
        XCTAssertEqual(store.state.fontScale, QuranReadingPreferences.fontScaleRange.upperBound)

        store.send(.fontScaleChanged(0.1))
        XCTAssertEqual(store.state.fontScale, QuranReadingPreferences.fontScaleRange.lowerBound)
    }

    func testReadingModeChangedPersistsPreference() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)

        store.send(.readingModeChanged(.arabicOnly))

        XCTAssertEqual(store.state.readingMode, .arabicOnly)
        XCTAssertEqual(
            testEnv.preferencesStore.value(for: "quran.readingPreferences", as: QuranReadingPreferences.self)?.readingMode,
            .arabicOnly
        )
    }

    func testAyahAppearedUpdatesReadingPosition() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let ayah = Ayah(surahNumber: 1, ayahNumberInSurah: 3, arabicText: "text", translation: nil, translationId: nil)

        store.send(.ayahAppeared(ayah))

        XCTAssertEqual(store.state.currentReadingPosition, 3)
    }
}
