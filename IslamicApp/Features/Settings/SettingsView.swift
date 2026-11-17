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
    @AppStorage(LocalizationManager.languagePreferenceKey) private var appLanguage = ""
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

                SettingsSectionView(LocalizedKey.Settings.prayerNotificationsSection, footer: LocalizedKey.Settings.sunriseReminderInfo) {
                    ForEach(PrayerName.allCases) { prayer in
                        PrayerNotificationRow(
                            prayer: prayer,
                            isEnabled: store.state.prayerNotificationPreference.isEnabled(prayer),
                            onToggle: { store.send(.prayerNotificationToggled(prayer)) }
                        )
                        if prayer == .fajr {
                            Toggle(String(localized: LocalizedKey.PrayerTimes.sunrise), isOn: Binding(
                                get: { store.state.prayerNotificationPreference.isSunriseEnabled },
                                set: { _ in store.send(.sunriseNotificationToggled) }
                            ))
                        }
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

                SettingsSectionView(LocalizedKey.Settings.language) {
                    Picker(selection: $appLanguage) {
                        Text(LocalizedKey.Settings.languageSystem).tag("")
                        Text(verbatim: "English").tag("en")
                        Text(verbatim: "العربية").tag("ar")
                        Text(verbatim: "Русский").tag("ru")
                        Text(verbatim: "Azərbaycan dili").tag("az")
                    } label: {
                        Text(LocalizedKey.Settings.language)
                    }
                }

                notificationPermissionSection

                SettingsSectionView(LocalizedKey.Settings.informationSection) {
                    Button { store.send(.aboutUsTapped) } label: {
                        SettingsNavigationRow(title: LocalizedKey.Settings.aboutUs, systemImage: "info.circle", value: nil)
                    }
                    .buttonStyle(.plain)

                    Link(destination: URL(string: "https://github.com/mnyx7/prayeree/blob/main/PRIVACY_POLICY.md")!) {
                        Label("Privacy Policy Website", systemImage: "safari")
                    }
                    Link(destination: URL(string: "https://github.com/mnyx7/prayeree/blob/main/CONTACT.md")!) {
                        Label("Support Website", systemImage: "safari")
                    }
                    Link(destination: URL(string: "mailto:minaya.yagubova@icloud.com")!) {
                        Label("Email Support", systemImage: "envelope")
                    }
                    NavigationLink {
                        AppInformationDocument(title: "Privacy Policy", content: appPrivacyPolicy)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    NavigationLink {
                        AppInformationDocument(title: "Support", content: appSupportInformation)
                    } label: {
                        Label("Support", systemImage: "questionmark.circle")
                    }

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

private struct AppInformationDocument: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            Text(.init(content))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let appPrivacyPolicy = "# Islamic Companion — Privacy Policy\n\n**Last updated:** 17 November 2026\n\n**Developer:** Minaya ([mnyx7](https://github.com/mnyx7))\n\n## 1. Scope\n\nThis document explains the current data flows in Islamic Companion (`prayeree`), an iOS application providing prayer times, Qibla direction, and Quran reading. It distinguishes information kept on your device from information sent to external providers to deliver requested features.\n\nThe current app has no developer-operated account, login, advertising, analytics, payment, or cloud-sync service. The app does not intentionally transmit reading progress or favorite verse references to the developer. External services still receive the information necessary to answer API requests, including ordinary connection information.\n\n## 2. Information and purposes\n\n| Information | Purpose | Where it is processed/stored |\n| --- | --- | --- |\n| Current coordinates, if you allow location access | Automatic prayer location and Qibla bearing | Coordinates are used on-device, may be stored as the last resolved location, are sent to AlAdhan when that source is used for prayer/sunrise requests, and can be sent to Apple for reverse geocoding |\n| Manually selected cities, favorites, and recent cities | Prayer location and quick switching | Stored on-device; AlAdhan receives selected coordinates for its prayer/sunrise requests. With QMİ/Minber selected, Minber receives a timetable city slug, year, and month instead |\n| City search text | Find a city or country/city combination | Sent to Apple's geocoding service; query/results can remain temporarily in app memory |\n| Compass heading and accuracy | Show the direction toward the Kaaba | Used on-device; no app code sends heading data to the developer or content providers |\n| Surah/ayah references, translation choice, and language | Retrieve Quran content | Sent in requests to Quran.com / Quran Foundation; the provider also receives ordinary request/connection information such as IP address |\n| Reading position and Quran favorite references | Continue reading and reopen saved surahs/ayahs | Stored on-device with surah display metadata; not intentionally uploaded by this app |\n| Reading size/mode, appearance, calculation method, madhab, and adjustments | Apply your preferences | Stored on-device; calculation settings are included in relevant AlAdhan requests |\n| Notification preferences and scheduled reminders | Prayer, optional sunrise, and daily Quran reminders | Stored on-device and scheduled with Apple's local notification system |\n| Copied or shared verse text | Your explicit copy/share action | Written to the system clipboard or passed to the destination you choose |\n\nManually selecting a city avoids using GPS for that selection, but city search still requires Apple geocoding, and AlAdhan requests still send the selected city's coordinates. If you select the optional QMİ/Minber timetable instead, Minber receives only the timetable city slug, year, and month; coordinates, madhab, and minute adjustments are not sent to Minber.\n\n## 3. External services\n\nThe current build contacts these services directly from your device:\n\n- **AlAdhan:** receives prayer location, requested date, calculation method, madhab, and minute adjustments for prayer times and sunrise. See [AlAdhan's credits and terms](https://aladhan.com/credits-and-terms).\n- **Minber.az (optional QMİ timetable):** receives a request for its city directory and the selected timetable city slug, year, and month for prayer times and sunrise, plus ordinary connection information such as IP address. GPS coordinates, madhab, manual adjustments, and notification preferences are not sent to Minber. Monthly responses are reused briefly in memory; daily prayer times use the existing on-device prayer cache. See [Minber prayer times](https://namaz.minber.az/).\n- **Quran.com / Quran Foundation:** receives requested content references and translation/language parameters. See [Quran.com's privacy policy](https://quran.com/privacy) and [Quran Foundation's developer terms](https://api-docs.quran.com/legal/developer-terms/).\n- **Apple:** provides location authorization, geocoding, local notifications, and operating-system services. See [Apple's privacy information](https://www.apple.com/legal/privacy/).\n\nThese providers may process IP addresses, server logs, and other information under their own policies. The developer does not control their retention periods. The final App Store privacy disclosures must account for the actual practices of all applicable service providers.\n\nAdhan Swift calculates prayer times on-device; the calculation library does not require a remote request. The current networking client uses an ephemeral URLSession with persistent URLCache disabled. This does not prevent providers from retaining their own request logs.\n\n## 4. Local storage, retention, and deletion\n\nPreferences, selected locations, saved cities, reading progress, and Quran favorite references are stored in the app's local UserDefaults. Fetched prayer times and available sunrise times are cached as JSON files in the app's Application Support directory. Quran responses are fetched online and are not saved as an offline content cache. The daily ayah widget stores a verse reference, without Arabic or translation text. Shared widget files are excluded from backup. These local files/settings may be included in backups according to your device and Apple's backup settings; the app does not implement its own iCloud synchronization.\n\nCurrent local preferences and saved references remain until you change/remove them or remove the app. Favorite entries can be removed through the app's star/edit controls. Removing the app removes its local app container, subject to Apple's offloading, backup, and restore behavior; offloading an app is different from deleting it.\n\nQuran content from older builds is removed from the file cache on initialization. Legacy daily ayah widget text is discarded when read. Offline Quran reading requires a future approved Content Sync integration; regular API responses are used only for online display.\n\nReading-position and favorite saves contain references and display metadata rather than additional copies of the Arabic verse or translation text. Verse and translation text are not persisted in the fetched-content cache.\n\n## 5. Notifications\n\nNotifications are local notifications scheduled on the device through Apple's UserNotifications framework. This implementation does not register for remote push notifications or send a push device token to a developer server.\n\nYou can allow or disable notifications in iOS Settings and change reminder preferences in the app. Prayer reminders and the optional sunrise reminder cover a rolling seven-day window refreshed when the app becomes active or relevant settings change. Sunrise reminders are off by default and can be enabled independently in Settings; previous preferences retain their existing prayer settings when upgrading. Sunrise uses the selected source or local calculation and the prayer location’s timezone. If a sunrise time is unavailable or already past, no sunrise reminder is scheduled for that date. Sunrise does not change the five-prayer countdown. Turning its toggle off cancels pending sunrise reminders. The selected notification sound and iOS authorization apply to both prayer and sunrise alerts. No notification preference is sent to a content provider. The daily Quran reminder repeats at 08:00 local time. Permission settings, Focus, system notification configuration, and device state can affect delivery and sound.\n\n## Home Screen widgets\n\nIf you add widgets, the app and its WidgetKit extension share local display snapshots through an App Group. These include prayer times with a city label/timezone, the daily ayah reference, selected translation/language settings, and the last-read surah/ayah reference. The daily widget is reference-only until permissions are confirmed; it does not display or persist Arabic or translation text. iOS manages rendered widget snapshots. The widget prayer snapshot does not contain GPS coordinates, and the reading snapshot does not contain verse text.\n\nThe extension can request chapter metadata from Quran.com / Quran Foundation to select today's ayah reference, without requesting verse text. For this widget metadata lookup, the provider receives the requested metadata/language parameters and connection information. Opening the online reader can then request verse/translation content as described above. Widget refresh timing is controlled by iOS. The extension does not request GPS or use a developer-operated widget server.\n\nShared snapshot files are excluded from backup and protected until the first device unlock after restart. A widget may visibly reveal content or a reading reference to someone who can view your Home Screen; you can remove the widget through iOS controls. The Continue Reading widget is marked privacy-sensitive, subject to system behavior.\n\n## 6. Copying, sharing, and support\n\nCopying an ayah writes text to the system clipboard. Clipboard availability on your other devices can depend on Apple's Universal Clipboard settings. Sharing passes the selected text to the app/service you choose, which then handles it under its own privacy terms.\n\nThe app does not automatically send diagnostic reports to the developer. Information you choose to include in a support request is handled by the channel you use, such as GitHub Issues. Public issue content can be visible to other people; email minaya.yagubova@icloud.com for private support or privacy requests.\n\n## 7. Your choices\n\n- Decline or revoke location permission in iOS Settings and use a manually selected prayer city. Live Qibla functionality requires location access.\n- Disable notification permission or individual reminder preferences.\n- Remove favorite cities, surahs, and ayahs through their controls.\n- Choose whether to copy/share content or submit a support request.\n- Delete the app to remove its local app container, subject to Apple's backup/restore behavior.\n\nThe app has no server-side account to delete. Requests about information retained by external providers should also be directed to those providers.\n\n## 8. Security and international processing\n\nAPI requests use HTTPS. Access to local app storage is subject to iOS sandboxing and platform security. No transmission or storage system can be guaranteed completely secure.\n\nRequests to third-party services may be processed in countries different from your own. The developer has not independently established every provider's hosting locations or legal transfer arrangements; these must be reviewed as appropriate before a public release.\n\n## 9. Children\n\nThe current application does not provide child accounts, age profiling, advertising, or an intentional mechanism for collecting children's personal information. This does not declare the app to be part of Apple's Kids Category. The developer must choose the appropriate App Store audience/age rating and review any additional obligations before targeting children.\n\n## 10. Changes and contact\n\nThis policy will be updated when the app's data flows, providers, retention, or features change. The date above identifies the latest revision.\n\nContact Minaya at [minaya.yagubova@icloud.com](mailto:minaya.yagubova@icloud.com) for support and privacy requests. See [CONTACT.md](CONTACT.md) for reporting guidance. Do not send sensitive information in a public issue.\n"

private let appSupportInformation = "# Contact and support\n\n**Application:** Islamic Companion (`prayeree`)\n\n**Developer:** Minaya\n\n**GitHub:** [mnyx7](https://github.com/mnyx7)\n\n**Repository:** [mnyx7/prayeree](https://github.com/mnyx7/prayeree)\n\n**Support and privacy email:** [minaya.yagubova@icloud.com](mailto:minaya.yagubova@icloud.com)\n\n## Technical support\n\nIf repository Issues are enabled and accessible, [open an issue](https://github.com/mnyx7/prayeree/issues/new) for bugs, feature requests, or documentation corrections.\n\nInclude the app version, iOS version, device model, steps to reproduce, expected behavior, and what happened. A screenshot can help. Avoid including tokens, passwords, precise location, or other personal information in a public issue.\n\nFor notifications, say whether the alert was for a prayer, sunrise, or the daily Quran reminder; include whether permission was enabled and whether the issue occurred with the app open, in the background, or closed. For prayer or sunrise times, include the city, calendar date, timezone, selected source/calculation method, and any prayer adjustments. Madhab is relevant for calculated prayer times; Minber uses a fixed city timetable. Exact GPS coordinates are not necessary for an initial report.\n\n## Privacy requests\n\nSee the [privacy policy](PRIVACY_POLICY.md). This build stores reading progress, favorites, and preferences on the device and does not provide developer-operated accounts. Removing the app removes its local app container, subject to Apple's backup/restore behavior.\n\nFor private support and privacy requests, email minaya.yagubova@icloud.com. GitHub documentation links must be accessible without signing in before using them as public App Store URLs.\n\n## Content corrections and rights\n\nFor a translation/content concern, identify the surah and ayah reference, the selected translation or edition, and the nature of the concern. Do not post an entire copyrighted translation as an attachment. Provider copyright and licensing requests should also be directed to the relevant rights holder or Quran Foundation through its [official documentation/contact information](https://api-docs.quran.com/legal/developer-terms/).\n\nFor a Minber/QMİ timetable discrepancy, include the city, date, and displayed time, and compare it with [Minber’s published timetable](https://namaz.minber.az/). Minber is a third-party distributor of QMİ-based timetables. API publishing/redistribution permission and provider corrections should be confirmed with the operator; the app does not claim QMİ endorsement.\n\nNo support response time is guaranteed.\n"
