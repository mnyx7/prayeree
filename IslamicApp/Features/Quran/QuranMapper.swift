//
//  QuranMapper.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum QuranMapper {
    static func map(chapter: QuranChapterDTO) -> Surah {
        Surah(
            id: chapter.id,
            arabicName: chapter.nameArabic,
            transliteratedName: chapter.nameSimple,
            englishTranslatedName: chapter.translatedName?.name ?? chapter.nameSimple,
            versesCount: chapter.versesCount,
            revelationPlace: RevelationPlace(rawValue: chapter.revelationPlace) ?? .makkah
        )
    }

    static func map(verse: QuranVerseDTO, translationId: Int?) -> Ayah {
        let surahNumber = verse.verseKey.split(separator: ":").first.flatMap { Int($0) } ?? 0
        let translationText = verse.translations?.first.map { stripHTMLTags($0.text) }
        return Ayah(
            surahNumber: surahNumber,
            ayahNumberInSurah: verse.verseNumber,
            arabicText: verse.textUthmani,
            translation: translationText,
            translationId: translationId
        )
    }

    static func map(translation: QuranTranslationResourceDTO) -> QuranTranslation {
        QuranTranslation(id: translation.id, languageCode: translation.languageName, name: translation.name)
    }

    // Quran.com translation text commonly embeds footnote markup (e.g. <sup
    // foot_note=...>1</sup>) — stripped here so the reader never shows raw HTML.
    static func stripHTMLTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
