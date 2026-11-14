//
//  FavoriteCityChips.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

// Reused for both favorites and recents (PrayerTimesView passes whichever
// list is relevant) rather than shipping two near-identical components.
struct FavoriteCityChips: View {
    let cities: [City]
    var selectedCityID: String? = nil
    let onSelect: (City) -> Void
    let onManageTapped: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cities) { city in
                    let isSelected = city.id == selectedCityID
                    Button { onSelect(city) } label: {
                        HStack(spacing: 6) {
                            if isSelected { Image(systemName: "checkmark") }
                            Text(city.name)
                        }
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .foregroundStyle(isSelected ? Color.white : AppColor.accent)
                        .background(isSelected ? AppColor.accent : AppColor.accent.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                Button {
                    onManageTapped()
                } label: {
                    Label(String(localized: LocalizedKey.PrayerTimes.favoriteCitiesTitle), systemImage: "star")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
        .scrollClipDisabled()
    }
}
