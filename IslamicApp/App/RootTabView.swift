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
    @State private var selectedTab = 0
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
                preferencesStore: environment.preferencesStore,
                widgetPublisher: environment.widgetPublisher
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
                preferencesStore: environment.preferencesStore,
                widgetPublisher: environment.widgetPublisher
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
        TabView(selection: $selectedTab) {
            PrayerTimesView(store: prayerTimesStore)
                .tag(0)
                .tabItem { Label(LocalizedKey.PrayerTimes.tabTitle, systemImage: "sun.horizon") }

            QiblaView(store: qiblaStore)
                .tag(1)
                .tabItem { Label(LocalizedKey.Qibla.tabTitle, systemImage: "location.north.circle") }

            QuranView(store: quranStore)
                .tag(2)
                .tabItem { Label(LocalizedKey.Quran.tabTitle, systemImage: "book.closed") }

            SettingsView(store: settingsStore)
                .tag(3)
                .tabItem { Label(LocalizedKey.Settings.tabTitle, systemImage: "gearshape") }
        }
        .onOpenURL { url in
            guard let route = WidgetRoute(url: url) else { return }
            switch route {
            case .prayerTimes: selectedTab = 0
            case .quran: selectedTab = 2
            case .continueReading:
                selectedTab = 2
                quranStore.send(.widgetContinueReadingRequested)
            case .dailyAyah(let surah, let ayah):
                selectedTab = 2
                quranStore.send(.widgetAyahRequested(surah, ayah))
            }
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
