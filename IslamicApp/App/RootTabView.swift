//
//  RootTabView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct RootTabView: View {
    let appStore: AppStore
    let environment: AppEnvironment
    @State private var prayerTimesStore: PrayerTimesStore
    @State private var qiblaStore: QiblaStore
    @State private var quranStore: QuranStore
    @State private var settingsStore: SettingsStore

    init(appStore: AppStore, environment: AppEnvironment) {
        self.appStore = appStore
        self.environment = environment
        _prayerTimesStore = State(
            initialValue: PrayerTimesStore(
                appStore: appStore,
                repository: PrayerTimesRepository(
                    service: PrayerTimesService(apiClient: environment.apiClient),
                    cacheStore: environment.cacheStore
                ),
                locationManager: environment.locationManager,
                preferencesStore: environment.preferencesStore
            )
        )
        _qiblaStore = State(
            initialValue: QiblaStore(
                locationManager: environment.locationManager,
                compassManager: environment.compassManager,
                qiblaCalculator: environment.qiblaCalculator
            )
        )
        _quranStore = State(
            initialValue: QuranStore(
                repository: QuranRepository(
                    service: QuranService(apiClient: environment.apiClient),
                    cacheStore: environment.cacheStore
                ),
                preferencesStore: environment.preferencesStore
            )
        )
        _settingsStore = State(
            initialValue: SettingsStore(
                appStore: appStore,
                preferencesStore: environment.preferencesStore,
                notificationManager: environment.notificationManager,
                locationManager: environment.locationManager
            )
        )
    }

    var body: some View {
        TabView {
            PrayerTimesView(store: prayerTimesStore)
                .tabItem { Label(LocalizedKey.PrayerTimes.tabTitle, systemImage: "sun.horizon") }

            QiblaView(store: qiblaStore)
                .tabItem { Label(LocalizedKey.Qibla.tabTitle, systemImage: "location.north.circle") }

            QuranView(store: quranStore)
                .tabItem { Label(LocalizedKey.Quran.tabTitle, systemImage: "book.closed") }

            SettingsView(store: settingsStore)
                .tabItem { Label(LocalizedKey.Settings.tabTitle, systemImage: "gearshape") }
        }
        .tint(AppColor.accent)
        .preferredColorScheme(appStore.state.appearanceMode.colorScheme)
    }
}

// SwiftUI-facing mapping kept here (not in Core/Models) since AppAppearanceMode
// itself must stay UIKit/SwiftUI-framework-free.
extension AppAppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
