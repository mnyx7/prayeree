//
//  SettingsView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    let store: SettingsStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                LocationModePicker(
                    locationSourceMode: store.locationSourceMode,
                    selectedCity: store.selectedCity,
                    recentCities: store.recentCities,
                    favoriteCities: store.favoriteCities,
                    citySearchQuery: store.state.citySearchQuery,
                    citySearchResults: store.state.citySearchResults,
                    isSearchingCities: store.state.isSearchingCities,
                    onModeChanged: { store.send(.locationModeChanged($0)) },
                    onCitySelected: { store.send(.citySelected($0)) },
                    onFavoriteToggled: { store.send(.favoriteToggled($0)) },
                    onQueryChanged: { store.send(.citySearchQueryChanged($0)) }
                )

                SettingsSectionView(LocalizedKey.Settings.prayerSettingsSection) {
                    Button { store.send(.destinationTapped(.prayerCalculationSettings)) } label: {
                        SettingsNavigationRow(title: LocalizedKey.Settings.calculationMadhab, systemImage: "moon.stars", value: nil)
                    }
                    .buttonStyle(.plain)

                    Button { store.send(.destinationTapped(.prayerAdjustments)) } label: {
                        SettingsNavigationRow(title: LocalizedKey.Settings.manualAdjustments, systemImage: "slider.horizontal.3", value: nil)
                    }
                    .buttonStyle(.plain)
                }

                SettingsSectionView(LocalizedKey.Settings.prayerNotificationsSection) {
                    ForEach(PrayerName.allCases) { prayer in
                        PrayerNotificationRow(
                            prayer: prayer,
                            isEnabled: store.state.prayerNotificationPreference.isEnabled(prayer),
                            onToggle: { store.send(.prayerNotificationToggled(prayer)) }
                        )
                    }
                }

                SettingsSectionView(LocalizedKey.Settings.quranNotificationsSection) {
                    Toggle(
                        String(localized: LocalizedKey.Settings.dailyAyahReminder),
                        isOn: Binding(get: { store.state.dailyQuranNotificationEnabled }, set: { _ in store.send(.quranNotificationToggled) })
                    )
                }

                SettingsSectionView(LocalizedKey.Settings.soundSection) {
                    NotificationSoundPicker(
                        onPreviewTapped: { store.send(.soundPreviewRequested(store.state.selectedNotificationSound)) }
                    )
                    Button(String(localized: LocalizedKey.Settings.sendTestNotification)) {
                        store.send(.testNotificationRequested)
                    }
                    .disabled(store.state.isSendingTestNotification)
                    if let message = store.state.notificationFeedback {
                        Text(message).font(.footnote).foregroundStyle(AppColor.textSecondary)
                    }
                }

                SettingsSectionView(LocalizedKey.Settings.appearanceSection) {
                    AppearancePicker(selection: store.appearanceMode, onChange: { store.send(.appearanceModeChanged($0)) })
                }

                notificationPermissionSection

                SettingsSectionView(LocalizedKey.Settings.informationSection) {
                    Button { store.send(.aboutUsTapped) } label: {
                        SettingsNavigationRow(title: LocalizedKey.Settings.aboutUs, systemImage: "info.circle", value: nil)
                    }
                    .buttonStyle(.plain)

                    LabeledContent(String(localized: LocalizedKey.Settings.version), value: store.state.appVersion)
                }
            }
            .navigationTitle(Text(LocalizedKey.Settings.tabTitle))
            .task { store.send(.screenAppeared) }
            .navigationDestination(
                item: Binding(
                    get: { store.state.activeDestination },
                    set: { newValue in if newValue == nil { store.send(.destinationDismissed) } }
                )
            ) { destination in
                destinationView(for: destination)
            }
        }
    }

    @ViewBuilder
    private var notificationPermissionSection: some View {
        switch store.notificationAuthorizationStatus {
        case .denied:
            Section {
                Button(String(localized: LocalizedKey.Settings.enableNotificationsInSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        case .notDetermined:
            Section {
                Button(String(localized: LocalizedKey.Settings.allowNotifications)) { store.send(.notificationPermissionRequested) }
            }
        case .authorized, .provisional, .ephemeral:
            Section {
                Label(String(localized: LocalizedKey.Settings.notificationsScheduled(store.scheduledNotificationCount)), systemImage: "bell.badge")
                    .font(.footnote).foregroundStyle(AppColor.textSecondary)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsStore.Destination) -> some View {
        switch destination {
        case .prayerCalculationSettings:
            PrayerCalculationSettingsView(store: store)
        case .prayerAdjustments:
            PrayerAdjustmentsView(store: store)
        case .aboutUs:
            AboutUsView(appVersion: store.state.appVersion)
        }
    }
}
