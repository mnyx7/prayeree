import SwiftUI

struct TranslationSelectorView: View {
    let translations: [QuranTranslation]
    let selectedTranslation: QuranTranslation?
    let onSelect: (QuranTranslation) -> Void
    let onDismiss: () -> Void

    @State private var searchQuery = ""

    private var filteredTranslations: [QuranTranslation] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return translations }
        return translations.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.languageCode.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filteredTranslations) { translation in
                Button {
                    onSelect(translation)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(translation.name)
                            Text(translation.languageCode.uppercased())
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        Spacer()
                        if translation.id == selectedTranslation?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColor.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(Text(LocalizedKey.Quran.translation))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedKey.Common.done), action: onDismiss)
                }
            }
        }
        .searchable(text: $searchQuery, placement: .automatic, prompt: Text(LocalizedKey.Common.search))
    }
}
