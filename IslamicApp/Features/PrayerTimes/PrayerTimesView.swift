import SwiftUI

struct PrayerTimesView: View {
    let store: PrayerTimesStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    if store.state.freshness.isCached {
                        CachedDataBanner(lastUpdated: store.state.lastUpdated)
                    }

                    if case .calculated = store.state.freshness {
                        Label(String(localized: LocalizedKey.PrayerTimes.calculatedLocally), systemImage: "checkmark.shield")
                            .font(.caption).foregroundStyle(AppColor.textSecondary)
                    }

                    PrayerSummaryCard(
                        cityName: store.selectedCity?.name ?? String(localized: LocalizedKey.Common.useCurrentLocation),
                        selectedDate: store.state.selectedDate,
                        hijriDate: store.state.prayerTimes?.hijriDate,
                        nextPrayer: store.state.nextPrayer,
                        remainingCountdown: store.state.remainingCountdown,
                        onDateTapped: { store.send(.dateTapped) },
                        onLocationTapped: { store.send(.locationTapped) }
                    )

                    FavoriteCityChips(
                        cities: store.favoriteCities,
                        selectedCityID: store.activeCityID,
                        onSelect: { store.send(.recentCitySelected($0)) },
                        onManageTapped: { store.send(.favoriteCitiesTapped) }
                    )

                    prayerListContent
                }
                .padding()
            }
            .background(AppColor.backgroundPrimary)
            .refreshable {
                store.send(.refreshRequested)
            }
            .navigationTitle(Text(LocalizedKey.PrayerTimes.tabTitle))
            .task { store.send(.screenAppeared) }
            // Changing calculation method/madhab/adjustments/location from
            // Settings must refresh an already-loaded Prayer Times screen,
            // not just reschedule notifications (spec section B).
            .onChange(of: store.refreshTrigger) { _, _ in
                store.send(.configurationChanged)
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
    private var prayerListContent: some View {
        if let prayerTimes = store.state.prayerTimes {
            VStack(spacing: AppSpacing.xxSmall) {
                ForEach(prayerTimes.times) { time in
                    PrayerTimeRow(prayerTime: time, isNext: time.id == store.state.nextPrayer?.id, timeZone: prayerTimes.timeZone)
                }
            }
        } else if store.state.loadingState == .loading {
            ProgressView()
                .padding(.top, 40)
        } else if let errorMessage = store.state.errorMessage {
            AppErrorState(message: errorMessage) {
                store.send(.retryTapped)
            }
        } else {
            AppEmptyState(
                systemImage: "location.magnifyingglass",
                title: String(localized: LocalizedKey.PrayerTimes.selectLocationPrompt),
                actionTitle: String(localized: LocalizedKey.PrayerTimes.chooseCity)
            ) {
                store.send(.locationTapped)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: PrayerTimesStore.ActiveSheet) -> some View {
        switch sheet {
        case .datePicker:
            DatePickerSheet(
                initialDate: store.state.selectedDate,
                onDateSelected: { store.send(.dateSelected($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )

        case .citySelector:
            CitySelectorSheet(
                recentCities: store.recentCities,
                favoriteCities: store.favoriteCities,
                selectedCityID: store.activeCityID,
                selectedCountry: store.state.selectedCountryForCitySearch,
                citySearchQuery: store.state.citySearchQuery,
                citySearchResults: store.state.citySearchResults,
                isSearchingCities: store.state.isSearchingCities,
                onCurrentLocationTapped: { store.send(.currentLocationRequested) },
                onCountrySelected: { store.send(.countrySelectedForSearch($0)) },
                onCountryCleared: { store.send(.countrySelectedForSearch(nil)) },
                onQueryChanged: { store.send(.citySearchQueryChanged($0)) },
                onCitySelected: { store.send(.citySelected($0)) },
                onDismiss: { store.send(.sheetDismissed) }
            )

        case .favoriteCities:
            FavoriteCitiesSheet(
                favoriteCities: store.favoriteCities,
                selectedCityID: store.activeCityID,
                onSelect: { store.send(.citySelected($0)) },
                onRemove: { store.send(.favoriteToggled($0)) },
                onMove: { store.send(.favoriteCitiesReordered($0)) },
                onAdd: { store.send(.locationTapped) },
                onDismiss: { store.send(.sheetDismissed) }
            )
        }
    }
}
