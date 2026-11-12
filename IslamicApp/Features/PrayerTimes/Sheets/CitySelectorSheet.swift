import SwiftUI

struct CitySelectorSheet: View {
    let recentCities: [City]
    let favoriteCities: [City]
    var selectedCityID: String? = nil
    let selectedCountry: Country?
    let citySearchQuery: String
    let citySearchResults: [City]
    let isSearchingCities: Bool
    let onCurrentLocationTapped: () -> Void
    let onCountrySelected: (Country) -> Void
    let onCountryCleared: () -> Void
    let onQueryChanged: (String) -> Void
    let onCitySelected: (City) -> Void
    let onDismiss: () -> Void

    private let countries = Country.all

    var body: some View {
        NavigationStack {
            List {
                if citySearchQuery.isEmpty {
                    browseContent
                } else {
                    searchResultsContent
                }
            }
            .searchable(
                text: Binding(get: { citySearchQuery }, set: onQueryChanged),
                prompt: Text(LocalizedKey.PrayerTimes.searchForCity)
            )
            .navigationTitle(Text(LocalizedKey.Common.selectCity))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedKey.Common.cancel), action: onDismiss)
                }
            }
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        Section {
            Button(action: onCurrentLocationTapped) {
                Label(String(localized: LocalizedKey.Common.useCurrentLocation), systemImage: "location.fill")
            }
        }

        if let selectedCountry {
            Section {
                Button(action: onCountryCleared) {
                    Label(String(localized: LocalizedKey.PrayerTimes.searchingIn(selectedCountry.name)), systemImage: "xmark.circle.fill")
                }
            }
        }

        if !recentCities.isEmpty {
            Section {
                ForEach(recentCities) { city in
                    Button { onCitySelected(city) } label: { cityLabel(city) }
                }
            } header: {
                Text(LocalizedKey.Common.recent)
            }
        }

        if !favoriteCities.isEmpty {
            Section {
                ForEach(favoriteCities) { city in
                    Button { onCitySelected(city) } label: { cityLabel(city) }
                }
            } header: {
                Text(LocalizedKey.Common.favorites)
            }
        }

        Section {
            ForEach(countries) { country in
                Button(country.name) { onCountrySelected(country) }
            }
        } header: {
            Text(LocalizedKey.PrayerTimes.browseByCountry)
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        Section {
            if isSearchingCities {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if citySearchResults.isEmpty {
                Text(LocalizedKey.Common.noCitiesFound)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                ForEach(citySearchResults) { city in
                    Button {
                        onCitySelected(city)
                    } label: {
                        VStack(alignment: .leading) {
                            cityLabel(city)
                            Text(Locale.current.localizedString(forRegionCode: city.countryCode) ?? city.countryCode)
                                .font(.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
        }
    }
    private func cityLabel(_ city: City) -> some View {
        HStack {
            Text(city.name)
            Spacer()
            if city.id == selectedCityID {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.accent)
            }
        }
    }

}
