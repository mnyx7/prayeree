import SwiftUI

struct QuranReaderView: View {
    @State private var store: QuranReaderStore

    init(store: QuranReaderStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                switch content {
                case .loaded:
                    ForEach(store.state.ayahs) { ayah in
                        AyahCardView(
                            ayah: ayah,
                            readingMode: store.state.readingMode,
                            fontScale: store.state.fontScale,
                            onCopy: { store.send(.copyTapped(ayah)) },
                            onShare: { store.send(.shareTapped(ayah)) }
                        )
                        .onAppear { store.send(.ayahAppeared(ayah)) }
                    }
                case .loading:
                    ProgressView()
                        .padding(.top, 60)
                case .error(let message):
                    AppErrorState(message: message) {
                        store.send(.retryTapped)
                    }
                }
            }
            .padding()
        }
        // A dedicated, slightly-warmer background than the rest of the app —
        // the reading area is meant to feel like its own spacious, focused
        // space, not just another list screen (Phase 11 requirement).
        .background(AppColor.quranReadingBackground)
        .navigationTitle(store.state.surah.transliteratedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
