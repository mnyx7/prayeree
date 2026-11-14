//
//  LocationModePicker.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct LocationModePicker: View {
    let locationSourceMode: LocationSourceMode
    let selectedCity: City?
    let recentCities: [City]
    let favoriteCities: [City]
    let citySearchQuery: String
    let citySearchResults: [City]
    let isSearchingCities: Bool
    let onModeChanged: (LocationSourceMode) -> Void
    let onCitySelected: (City) -> Void
    let onFavoriteToggled: (City) -> Void
    let onQueryChanged: (String) -> Void

    @State private var isChoosingManual = false

    private var isAutomatic: Bool {
        if case .automatic = locationSourceMode { return true }
        return false
    }

    var body: some View {
        Section {
            Picker(
                String(localized: LocalizedKey.Settings.locationModeLabel),
                selection: Binding(
                    get: { isAutomatic && !isChoosingManual },
                    set: { useAutomatic in
                        isChoosingManual = !useAutomatic
                        if useAutomatic {
                            onModeChanged(.automatic)
                        } else if let selectedCity {
                            onModeChanged(.manual(country: Country(code: selectedCity.countryCode), city: selectedCity))
                        }
                    }
                )
            ) {
                Text(LocalizedKey.Settings.locationModeAutomatic).tag(true)
                Text(LocalizedKey.Settings.locationModeManual).tag(false)
            }
            .pickerStyle(.segmented)

            if isAutomatic && !isChoosingManual {
                LabeledContent(String(localized: LocalizedKey.Settings.currentCity), value: selectedCity?.name ?? String(localized: LocalizedKey.Settings.detecting))
            } else {
                LabeledContent(String(localized: LocalizedKey.Settings.selectedCity), value: selectedCity?.name ?? String(localized: LocalizedKey.Settings.none))

                TextField(String(localized: LocalizedKey.PrayerTimes.searchForCity), text: Binding(get: { citySearchQuery }, set: onQueryChanged))

                if isSearchingCities {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if !citySearchQuery.isEmpty {
                    if citySearchResults.isEmpty {
                        Text(LocalizedKey.Common.noCitiesFound)
                            .foregroundStyle(AppColor.textSecondary)
                    } else {
                        ForEach(citySearchResults) { city in
                            cityRow(city)
                        }
                    }
                } else {
                    ForEach(favoriteCities) { city in
                        cityRow(city)
                    }
                    ForEach(recentCities.filter { city in !favoriteCities.contains(where: { $0.id == city.id }) }) { city in
                        cityRow(city)
                    }
                }
            }
        } header: {
            Text(LocalizedKey.Settings.locationSection)
        }
    }

    private func cityRow(_ city: City) -> some View {
        HStack {
            Button { onCitySelected(city) } label: {
                HStack {
                    Text(city.name)
                    Spacer()
                    if city.id == selectedCity?.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.accent)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { onFavoriteToggled(city) } label: {
                Image(systemName: favoriteCities.contains(where: { $0.id == city.id }) ? "star.fill" : "star")
                    .foregroundStyle(AppColor.accent)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(LocalizedKey.Common.favorites))
        }
    }
}
