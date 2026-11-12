import SwiftUI

struct FavoriteCitiesSheet: View {
    let favoriteCities: [City]
    var selectedCityID: String? = nil
    let onSelect: (City) -> Void
    let onRemove: (City) -> Void
    let onMove: ([City]) -> Void
    let onAdd: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if favoriteCities.isEmpty {
                    Text(LocalizedKey.PrayerTimes.noFavoriteCities)
                        .foregroundStyle(AppColor.textSecondary)
                } else {
                    ForEach(favoriteCities) { city in
                        Button {
                            onSelect(city)
                        } label: {
                            HStack {
                                Text(city.name)
                                Spacer()
                                if city.id == selectedCityID { Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColor.accent) }
                            }
                        }
                    }
                    .onMove { source, destination in
                        var cities = favoriteCities
                        cities.move(fromOffsets: source, toOffset: destination)
                        onMove(cities)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            onRemove(favoriteCities[index])
                        }
                    }
                }
            }
            .navigationTitle(Text(LocalizedKey.PrayerTimes.favoriteCitiesTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    EditButton()
                    Button(action: onAdd) {
                        Label(String(localized: LocalizedKey.Common.addCity), systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedKey.Common.done), action: onDismiss)
                }
            }
        }
    }
}
