//
//  QuranView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QuranView: View {
    let store: QuranStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsSearch = false
    @State private var navigationPath: [ReaderDestination] = []

    private struct ReaderDestination: Hashable {
        let surah: Surah
        let ayahNumber: Int?
        var savesReadingProgress = true
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    if store.state.freshness.isCached {
                        QuranCachedDataBanner(lastUpdated: store.state.lastUpdated)
                    }

                    if let position = store.state.lastReadingPosition {
                        Button {
                            openReader(for: position.surah, at: position.ayahNumberInSurah)
                        } label: {
                            HStack(spacing: AppSpacing.medium) {
                                Image(systemName: "book.bookmark")
                                    .font(.title2).foregroundStyle(AppColor.accent)
                                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                                    Text(LocalizedKey.Quran.continueReading)
                                        .font(AppTypography.headline)
                                    Text(position.surah.transliteratedName)
                                        .foregroundStyle(AppColor.textPrimary)
                                    Text(LocalizedKey.Quran.ayahNumber(position.ayahNumberInSurah))
                                        .font(AppTypography.caption).foregroundStyle(AppColor.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(AppColor.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCardStyle()
                        }
                        .buttonStyle(.plain)
                    }

                    if let dailyAyah = store.state.dailyAyah {
                        DailyAyahCard(
                            ayah: dailyAyah,
                            onOpenReader: { openReader(forSurahNumber: dailyAyah.surahNumber, at: dailyAyah.ayahNumberInSurah) },
                            onShare: { store.send(.shareAyahTapped) },
                            isFavorite: store.favorites.isFavorite(dailyAyah),
                            canFavorite: store.state.surahs.contains { $0.id == dailyAyah.surahNumber },
                            onFavorite: { store.send(.ayahFavoriteToggled(dailyAyah)) }
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                QuranCreditsView(translation: store.state.selectedTranslation)
                    .padding(.horizontal)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColor.backgroundPrimary)
            }
            .background(AppColor.backgroundPrimary)
            .refreshable { store.send(.refreshRequested) }
            .navigationTitle(Text(LocalizedKey.Quran.tabTitle))
            .sheet(isPresented: $showsSearch) {
                QuranSearchView(store: store) { surah, ayah in
                    showsSearch = false
                    openReader(for: surah, at: ayah)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showsSearch = true } label: {
                        Label("Search Quran", systemImage: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { store.send(.favoritesTapped) } label: {
                        Label(String(localized: LocalizedKey.Common.favorites), systemImage: "star")
                    }
                }
            }
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
            .onChange(of: store.state.readerRequest, initial: true) { _, request in
                guard let request else { return }
                let savesProgress = store.state.readerRequestSavesProgress
                store.send(.readerRequestHandled)
                store.send(.readerOpened(request.surah))
                navigationPath = [ReaderDestination(surah: request.surah, ayahNumber: request.ayahNumberInSurah, savesReadingProgress: savesProgress)]
            }
            .navigationDestination(for: ReaderDestination.self) { destination in
                QuranReaderView(store: store.makeReaderStore(for: destination.surah, startingAyahNumber: destination.ayahNumber, savesReadingProgress: destination.savesReadingProgress))
                    .onDisappear { store.send(.readingProgressChanged) }
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
                        onShare: { store.send(.shareAyahTapped) },
                        isFavorite: store.favorites.isFavorite(ayah),
                        onFavorite: { store.send(.ayahFavoriteToggled(ayah)) }
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
        case .favorites:
            QuranFavoritesView(favorites: store.favorites, onOpen: { surah, ayah in
                store.send(.sheetDismissed)
                openReader(for: surah, at: ayah)
            }, onDismiss: { store.send(.sheetDismissed) })

        case .surahPicker:
            SurahPickerView(
                surahs: store.state.surahs,
                recentSurahs: store.state.recentSurahs,
                onSelect: { store.send(.surahSelected($0)) },
                onDismiss: { store.send(.sheetDismissed) },
                favorites: store.favorites
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

    private func openReader(for surah: Surah, at ayahNumber: Int? = nil, savesReadingProgress: Bool = true) {
        store.send(.readerOpened(surah))
        navigationPath.append(ReaderDestination(surah: surah, ayahNumber: ayahNumber, savesReadingProgress: savesReadingProgress))
    }

    private func openReader(forSurahNumber surahNumber: Int, at ayahNumber: Int) {
        guard let surah = store.state.surahs.first(where: { $0.id == surahNumber }) else { return }
        openReader(for: surah, at: ayahNumber, savesReadingProgress: false)
    }
}

private struct QuranFavoritesView: View {
    let favorites: QuranFavoritesStore
    let onOpen: (Surah, Int?) -> Void
    let onDismiss: () -> Void
    @State private var query = ""

    private func matches(_ surah: Surah) -> Bool {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return search.isEmpty || surah.transliteratedName.localizedCaseInsensitiveContains(search)
            || surah.englishTranslatedName.localizedCaseInsensitiveContains(search)
            || surah.arabicName.contains(search) || String(surah.id) == search
    }

    private var surahs: [Surah] { favorites.surahs.filter(matches) }
    private var ayahs: [QuranFavoriteAyah] {
        favorites.ayahs.filter { matches($0.surah) || $0.id.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                if favorites.surahs.isEmpty && favorites.ayahs.isEmpty {
                    Text(LocalizedKey.Quran.noFavorites).foregroundStyle(AppColor.textSecondary)
                } else {
                    Section {
                        ForEach(surahs) { surah in
                            Button { onOpen(surah, nil) } label: {
                                HStack {
                                    Text(surah.transliteratedName)
                                    Spacer()
                                    Text(surah.arabicName).foregroundStyle(AppColor.textSecondary)
                                    Image(systemName: "star.fill").foregroundStyle(AppColor.accent)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            let removed = offsets.map { surahs[$0] }
                            removed.forEach(favorites.removeSurah)
                        }
                    } header: { Text(LocalizedKey.Quran.favoriteSurahs) }
                    Section {
                        ForEach(ayahs) { ayah in
                            Button { onOpen(ayah.surah, ayah.ayahNumberInSurah) } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(ayah.surah.transliteratedName)
                                        Text(LocalizedKey.Quran.ayahNumber(ayah.ayahNumberInSurah))
                                            .font(.caption).foregroundStyle(AppColor.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "star.fill").foregroundStyle(AppColor.accent)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            let removed = offsets.map { ayahs[$0] }
                            removed.forEach(favorites.removeAyah)
                        }
                    } header: { Text(LocalizedKey.Quran.favoriteAyahs) }
                }
            }
            .navigationTitle(Text(LocalizedKey.Common.favorites))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedKey.Common.done), action: onDismiss)
                }
                ToolbarItem(placement: .primaryAction) { EditButton() }
            }
        }
        .searchable(text: $query, placement: .automatic, prompt: Text(LocalizedKey.Common.search))
    }
}

struct QuranCreditsView: View {
    let translation: QuranTranslation?

    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            Link("Quran data provided by Quran.Foundation.", destination: URL(string: "https://quran.foundation")!)
            Text("Translation: " + (translation?.name ?? "Saheeh International"))
        }
        .font(.caption2)
        .foregroundStyle(AppColor.textSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}


/// Search is scoped to a chapter for text, avoiding a bulk download of Quran content.
private struct QuranSearchView: View {
    let store: QuranStore
    let onOpen: (Surah, Int?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var chapter: Surah?
    @State private var ayahs: [Ayah] = []
    @State private var isLoading = false
    @State private var failed = false
    @State private var retry = 0

    private var search: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }
    private func matches(_ value: String) -> Bool {
        let needle = normalized(search)
        return !needle.isEmpty && normalized(value).contains(needle)
    }
    private var surahs: [Surah] {
        store.state.surahs.filter {
            search.isEmpty || matches($0.transliteratedName) || matches($0.englishTranslatedName)
                || matches($0.arabicName) || String($0.id) == search
        }
    }
    private var reference: (Surah, Int)? {
        let numericSearch = String(search.map { character in
            character.wholeNumberValue.flatMap { String($0).first } ?? character
        })
        let parts = numericSearch.replacingOccurrences(of: "：", with: ":").split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let number = Int(parts[0]), let ayah = Int(parts[1]),
              let surah = store.state.surahs.first(where: { $0.id == number }),
              (1...surah.versesCount).contains(ayah) else { return nil }
        return (surah, ayah)
    }
    private var results: [Ayah] {
        let source = chapter == nil ? store.state.availableAyahs : ayahs
        return source.filter {
            search.isEmpty || matches($0.arabicText) || matches($0.translation ?? "")
                || String($0.ayahNumberInSurah) == search || $0.id == search
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Search text in", selection: $chapter) {
                        Text("Current surah").tag(Optional<Surah>.none)
                        ForEach(store.state.surahs) { surah in
                            Text("\(surah.id). \(surah.transliteratedName)").tag(Optional(surah))
                        }
                    }
                    Text("Find a surah by name or number, jump to 2:255, or search Arabic and translation text in the selected surah.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let (surah, ayah) = reference {
                    Section("Go to ayah") {
                        Button { onOpen(surah, ayah) } label: {
                            Label("\(surah.transliteratedName) · \(surah.id):\(ayah)", systemImage: "arrow.up.forward.book")
                        }
                    }
                }
                if chapter == nil && !surahs.isEmpty {
                    Section(search.isEmpty ? "Browse surahs" : "Surahs") {
                        ForEach(surahs) { surah in
                            Button { onOpen(surah, nil) } label: {
                                HStack(spacing: 12) {
                                    Text("\(surah.id)").font(.caption.monospacedDigit())
                                        .foregroundStyle(AppColor.accent).frame(width: 32, height: 32)
                                        .background(AppColor.accent.opacity(0.1), in: Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(surah.transliteratedName).font(.headline)
                                        Text(surah.englishTranslatedName).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(surah.arabicName).font(.title3).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                }
                if isLoading {
                    ProgressView("Loading surah…").frame(maxWidth: .infinity)
                } else if failed {
                    Section {
                        Text("Couldn’t load this surah. Check your connection and try again.")
                        Button("Try again") { retry += 1 }
                    }
                } else if !results.isEmpty && (!search.isEmpty || chapter != nil) {
                    Section("Ayahs · \(chapter?.transliteratedName ?? store.state.selectedSurah?.transliteratedName ?? "Current surah")") {
                        ForEach(results) { ayah in
                            Button {
                                guard let surah = store.state.surahs.first(where: { $0.id == ayah.surahNumber }) else { return }
                                onOpen(surah, ayah.ayahNumberInSurah)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(ayah.id).font(.caption.weight(.semibold)).foregroundStyle(AppColor.accent)
                                    Text(ayah.arabicText).font(.title3).multilineTextAlignment(.trailing)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    if let translation = ayah.translation {
                                        Text(translation).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }.padding(.vertical, 8).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                } else if !search.isEmpty && reference == nil && (chapter != nil || surahs.isEmpty) {
                    ContentUnavailableView.search(text: search)
                }
            }
            .navigationTitle("Search Quran")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Surah, ayah, or words")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: "\(chapter?.id ?? 0)-\(store.state.selectedTranslation?.id ?? 0)-\(retry)") {
                ayahs = []
                failed = false
                isLoading = false
                guard let chapter else { return }
                isLoading = true
                for await result in store.searchAyahs(in: chapter) {
                    guard !Task.isCancelled else { return }
                    ayahs = result.value ?? []
                    failed = result.value == nil
                    isLoading = false
                }
            }
        }
    }
}
