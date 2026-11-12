import SwiftUI

struct QuranView: View {
    let store: QuranStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var navigationPath: [Surah] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    if store.state.freshness.isCached {
                        QuranCachedDataBanner(lastUpdated: store.state.lastUpdated)
                    }

                    if let dailyAyah = store.state.dailyAyah {
                        DailyAyahCard(
                            ayah: dailyAyah,
                            onOpenReader: { openReader(forSurahNumber: dailyAyah.surahNumber) },
                            onShare: { store.send(.shareAyahTapped) }
                        )
                    }

                    QuranReadingHeader(
                        selectedSurah: store.state.selectedSurah,
                        selectedTranslation: store.state.selectedTranslation,
                        onSurahTapped: { store.send(.surahPickerTapped) },
                        onTranslationTapped: { store.send(.translationSelectorTapped) },
                        onReadingSettingsTapped: { store.send(.readingSettingsTapped) }
                    )

                    selectionContent
                }
                .padding()
            }
            .background(AppColor.backgroundPrimary)
            .refreshable { store.send(.refreshRequested) }
            .navigationTitle(Text(LocalizedKey.Quran.tabTitle))
            .task {
                store.send(.screenAppeared)
                while !Task.isCancelled {
                    let calendar = Calendar(identifier: .gregorian)
                    let now = Date()
                    guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else { return }
                    do { try await Task.sleep(for: .seconds(max(1, midnight.timeIntervalSince(now)))) }
                    catch { return }
                    store.send(.dailyAyahRefreshRequested)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { store.send(.dailyAyahRefreshRequested) }
            }
            .navigationDestination(for: Surah.self) { surah in
                QuranReaderView(store: store.makeReaderStore(for: surah))
            }
            .sheet(
                item: Binding(
                    get: { store.state.activeSheet },
                    set: { newValue in if newValue == nil { store.send(.sheetDismissed) } }
                )
            ) { sheet in
                sheetContent(for: sheet)
            }
        }
    }

    @ViewBuilder
    private var selectionContent: some View {
        if let selectedSurah = store.state.selectedSurah {
            VStack(alignment: .leading, spacing: 12) {
                if store.state.loadingState == .loading && store.state.availableAyahs.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                }
                if let message = store.state.errorMessage {
                    AppErrorState(message: message) { store.send(.retryTapped) }
                }
                Button {
                    store.send(.ayahPickerTapped)
                } label: {
                    HStack {
                        Text(store.state.selectedAyah.map { String(localized: LocalizedKey.Quran.ayahNumber($0.ayahNumberInSurah)) } ?? String(localized: LocalizedKey.Quran.selectAyah))
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(store.state.availableAyahs.isEmpty)

                if let ayah = store.state.selectedAyah {
                    AyahCardView(
                        ayah: ayah,
                        readingMode: store.state.readingPreferences.readingMode,
                        fontScale: store.state.readingPreferences.fontScale,
                        onCopy: { store.send(.copyAyahTapped) },
                        onShare: { store.send(.shareAyahTapped) }
                    )
                }

                Button {
                    openReader(for: selectedSurah)
                } label: {
                    Label(String(localized: LocalizedKey.Quran.openFullReader), systemImage: "book")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        } else if store.state.loadingState == .loading {
            ProgressView()
                .padding(.top, 20)
        } else if let errorMessage = store.state.errorMessage {
            AppErrorState(message: errorMessage) {
                store.send(.retryTapped)
            }
        } else {
            AppEmptyState(
                systemImage: "book.closed",
                title: String(localized: LocalizedKey.Quran.selectSurahToStartReading),
                actionTitle: String(localized: LocalizedKey.Quran.chooseSurah)
            ) {
                store.send(.surahPickerTapped)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: QuranStore.ActiveSheet) -> some View {
        switch sheet {
        case .surahPicker:
            SurahPickerView(
                surahs: store.state.surahs,
                recentSurahs: store.state.recentSurahs,
                onSelect: { store.send(.surahSelected($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )

        case .ayahPicker:
            AyahPickerView(
                ayahs: store.state.availableAyahs,
                onSelect: { store.send(.ayahSelected($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )

        case .translationSelector:
            TranslationSelectorView(
                translations: store.state.availableTranslations,
                selectedTranslation: store.state.selectedTranslation,
                onSelect: { store.send(.translationSelected($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )

        case .readingSettings:
            ReadingSettingsView(
                readingMode: store.state.readingPreferences.readingMode,
                fontScale: store.state.readingPreferences.fontScale,
                onReadingModeChanged: { store.send(.readingModeChanged($0)) },
                onFontScaleChanged: { store.send(.fontScaleChanged($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )
        }
    }

    private func openReader(for surah: Surah) {
        store.send(.readerOpened(surah))
        navigationPath.append(surah)
    }

    private func openReader(forSurahNumber surahNumber: Int) {
        guard let surah = store.state.surahs.first(where: { $0.id == surahNumber }) else { return }
        openReader(for: surah)
    }
}
