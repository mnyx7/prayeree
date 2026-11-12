import Foundation

protocol QuranServiceProtocol: Sendable {
    func fetchSurahs(languageCode: String) async throws -> [Surah]
    func fetchAyahs(surahNumber: Int, translationId: Int, languageCode: String) async throws -> [Ayah]
    func fetchDailyAyah(date: Date, translationId: Int, languageCode: String) async throws -> Ayah
    func fetchTranslations() async throws -> [QuranTranslation]
}
