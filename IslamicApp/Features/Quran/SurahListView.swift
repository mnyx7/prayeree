import SwiftUI

// Reused by Components/SurahPickerView.swift (which wraps this in the sheet
// chrome: NavigationStack, search field, cancel button) — the row/search
// logic lives here once rather than being duplicated between the two files.
struct SurahListView: View {
    let surahs: [Surah]
    let recentSurahs: [Surah]
    let searchQuery: String
    let onSelect: (Surah) -> Void

    var body: some View {
        List {
            if searchQuery.isEmpty, !recentSurahs.isEmpty {
                Section {
                    ForEach(recentSurahs) { surah in
                        row(for: surah)
                    }
                } header: {
                    Text(LocalizedKey.Common.recent)
                }
            }
            Section {
                ForEach(filteredSurahs) { surah in
                    row(for: surah)
                }
            } header: {
                Text(searchQuery.isEmpty ? LocalizedKey.Quran.allSurahs : LocalizedKey.Quran.results)
            }
        }
    }

    private var filteredSurahs: [Surah] {
        guard !searchQuery.isEmpty else { return surahs }
        return surahs.filter {
            $0.transliteratedName.localizedCaseInsensitiveContains(searchQuery) ||
            $0.englishTranslatedName.localizedCaseInsensitiveContains(searchQuery) ||
            String($0.id) == searchQuery
        }
    }

    private func row(for surah: Surah) -> some View {
        Button {
            onSelect(surah)
        } label: {
            HStack {
                Text("\(surah.id).")
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 28, alignment: .trailing)
                VStack(alignment: .leading) {
                    Text(surah.transliteratedName)
                    Text(surah.englishTranslatedName)
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text(surah.arabicName)
                    .font(.body)
            }
        }
        .buttonStyle(.plain)
    }
}
