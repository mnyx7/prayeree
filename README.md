# Islamic Companion · prayeree

A native SwiftUI app for prayer times, Qibla direction, and Quran reading, created by Minaya. Targets iPhone and iPad on iOS 17 or later, with English, Arabic, Russian, and Azerbaijani localization.

**Status:** active development. The simulator regression suite covers prayer times, sunrise, notifications, Settings, Quran, and Qibla. This is not a certification of App Store readiness; the release work below is still outstanding.

## Features

- **Prayer times:** five daily prayers, sunrise, Hijri date, countdown, date picker, automatic or manual location, favorite cities, calculation methods, madhab, and minute adjustments. Adhan Swift provides immediate on-device calculations while AlAdhan requests refresh data. The optional QMİ/Minber source uses published city timetables instead.
- **Qibla:** locally calculated bearing, live compass, permission handling, calibration guidance, and a numeric fallback on devices without a compass.
- **Quran:** surah and ayah selection, translations with native search, adjustable reading preferences, copy/share feedback, and a daily ayah fixed to the local calendar day.
- **Reading progress:** automatically saves the visible ayah for each surah. Continue reading opens the latest saved surah and verse after relaunch.
- **Quran favorites:** star surahs or ayahs, browse/search favorites, remove them, and open a saved ayah at its reference. Favorites store references and display metadata rather than duplicate verse text.
- **Notifications:** local prayer reminders, a separate opt-in sunrise reminder, a daily Quran reminder, foreground alerts, permission handling, and a test notification with feedback.
- **Appearance:** semantic light/dark colors and system/light/dark selection.

## Home Screen widgets

Three WidgetKit widgets are included: **Prayer times**, **Ayah of the Day**, and **Continue reading**. They support native Home Screen sizes and open the appropriate screen or exact ayah when tapped. See [WIDGETS.md](WIDGETS.md) for sizes, data refresh behavior, Xcode previews, and required App Group signing setup.

## Open and run

1. Clone the repository and open `IslamicApp/IslamicApp.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve **Adhan Swift 1.5.0**.
3. Select the `IslamicApp` scheme and an installed iPhone/iPad simulator.
4. Run with **Command–R**; run unit tests with **Command–U**.
5. For a physical device, select your own Apple development team and a valid bundle identifier in Signing & Capabilities. The checked-in team setting must be reviewed for your account.

The Xcode project is included. `IslamicApp/project.yml` is its XcodeGen specification; XcodeGen is not needed to open the checked-in project. Keep the specification and project settings consistent when changing configuration.

Example command-line test (replace the simulator name if needed):

```sh
xcodebuild test \
  -project IslamicApp/IslamicApp.xcodeproj \
  -scheme IslamicApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Project layout

| Path | Contents |
| --- | --- |
| `IslamicApp/App` | Startup, navigation, dependencies, and shared state |
| `IslamicApp/Core` | Models, networking, persistence, notifications, location, localization, and design system |
| `IslamicApp/Features` | Prayer Times, Qibla, Quran, and Settings |
| `IslamicApp/Resources` | Asset catalog, app icon, string catalog, previews, and dependency license |
| `IslamicApp/Shared` | App/extension display snapshots and validated widget links |
| `IslamicApp/Widgets` | WidgetKit extension, localized views, timelines, and entitlements |
| `IslamicApp/Tests` | Domain, repository, store, persistence, and notification unit tests |
| `IslamicApp/Design` | Logo explorations and previous icon assets |

Stores use `@Observable` and `@MainActor`. Views send actions to stores, repositories coordinate cache/network results, and protocol-based dependencies allow tests to use mocks.

## Services and data

| Service | Purpose | Information sent by this implementation |
| --- | --- | --- |
| [Minber.az](https://namaz.minber.az/api) | Optional QMİ published prayer timetable for supported Azerbaijani cities | Timetable city slug, year, and month; no coordinates or madhab sent |
| [AlAdhan](https://aladhan.com/prayer-times-api) | Remote prayer times and Hijri date | Coordinates, requested date, calculation method, madhab, and adjustments |
| [Quran.com API v4](https://api-docs.quran.foundation/) | Quran text, translations, chapters, and daily verse | Requested content references, translation/language choices, and ordinary connection information such as IP address |
| Apple CoreLocation / geocoding | Location, city search, and reverse geocoding | Location or city search text needed for the requested lookup |
| [Adhan Swift](https://github.com/batoulapps/adhan-swift) | On-device prayer calculations | No network request by the calculation library |

The current legacy Quran and AlAdhan endpoint calls do not contain API keys. This does **not** establish production authorization or permission to redistribute every translation. Review provider requirements before release; never put a future API secret into source code or the mobile binary.

## Persistence and notifications

Settings, selected locations, favorite cities, reading progress, and Quran favorite references are stored locally using UserDefaults. Fetched prayer times are stored as JSON in the app's Application Support cache directory. Quran content is fetched online without a persistent content cache. HTTP requests use an ephemeral session without URLCache persistence.

**Quran storage:** legacy Quran cache files are purged, and new Quran responses are not persisted. Offline Quran text support requires an approved Content Sync integration. The daily ayah widget displays and stores only a verse reference until permissions are confirmed, and opens the online reader when tapped.

Notifications use Apple's `UserNotifications` framework. No push-notification server, Firebase account, or per-notification service fee is involved. Prayer and enabled sunrise reminders are scheduled for seven days and refreshed when the app becomes active or settings change. Sunrise is off by default and keeps its own notification identifiers; missing or past sunrise times are skipped. The existing notification sound and iOS permission settings apply. Disabling sunrise removes pending sunrise alerts. Without reopening the app, those prayer reminders eventually run out. The Quran reminder repeats daily at 08:00 local time. Delivery and sound depend on permission, Focus, and device notification settings.

Reading progress and favorites are local to the device; there is no developer-operated account system or cross-device sync. Prayer-time fallback remains available without a connection. Quran text and city searches require connectivity.

## Privacy and support

- [Privacy policy draft](PRIVACY_POLICY.md)
- [Contact and support](CONTACT.md)

These files describe the current implementation. Review them before publishing and provide publicly reachable URLs in App Store Connect. If the repository is private, its files and Issues cannot serve as public support/privacy links.

## App Store release work still required

- **Original launcher artwork:** the current launcher icon was rendered from Apple's `moon.stars` SF Symbol. Apple prohibits system-provided images, or substantially/confusingly similar artwork, in app icons/logos. Replace it with original artwork before submission. See [Xcode and Apple SDKs Agreement, section 2.10](https://images.apple.com/legal/sla/docs/xcode.pdf). SF Symbols can remain in the permitted in-app UI.
- **Privacy manifest:** the app now bundles a UserDefaults reason declaration, and the widget has its own manifest. Review the aggregate privacy report and final data disclosures before submission. See [Apple's required-reason API guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
- **Quran provider authorization and content rights:** confirm production access, translation coverage, source attribution, and caching/offline use with Quran Foundation. Its [developer terms](https://api-docs.quran.com/legal/developer-terms/) limit ordinary API caching and require Content Sync for supported offline resources. Provider and selected translation credits appear in Quran screens.
- **Minber production use:** request written confirmation for App Store redistribution, caching, widget use, attribution, and request limits. A public endpoint is not a record of approval. No Minber publishing confirmation is recorded in this project.
- **Public privacy and support:** finalize the policy, a reachable support contact, and public URLs. Complete App Store privacy answers based on actual provider practices; do not assume that off-device API requests mean “no data collected.”
- **Release configuration:** confirm the bundle ID and signing team, matching app/extension version/build values (currently 1.0.0/1), App Group provisioning, iPad orientations/multitasking, export-compliance declaration, and a signed Release archive. A passing simulator build does not establish that a distributable archive is valid.
- **Real-device and UI verification:** test notifications with the app open/backgrounded/closed, permission denial and recovery, Qibla on hardware, city switching, reader scroll restoration, favorites, large text, Arabic/RTL, offline errors, and iPad layouts. Unit tests do not cover all these interactions.
- **Store listing:** provide accurate screenshots, age rating, description, category, support and privacy links, and review notes. Do not advertise complete offline content, permanent reminders, or guaranteed prayer-time accuracy.

The release audit was paused at the developer's request before these remaining items were implemented.

## Credits and source licensing

- Developed by **Minaya** ([GitHub: mnyx7](https://github.com/mnyx7)).
- Quran data is obtained from Quran.com / Quran Foundation; translations remain subject to their respective rights and provider terms.
- Prayer and sunrise data are obtained from AlAdhan or the selected QMİ-based Minber.az timetable; local calculations use Batoul Apps' Adhan Swift. Minber.az is a third-party distributor, not an official API endorsement by QMİ.
- Adhan Swift's MIT license is included in [`IslamicApp/Resources/Adhan-LICENSE.txt`](IslamicApp/Resources/Adhan-LICENSE.txt).

No license for this application's original source code has been selected. The bundled dependency license does not automatically license the entire application under MIT.

### Optional QMİ timetable via Minber

In Settings → Prayer settings → Calculation method, choose **Qafqaz Müsəlmanları İdarəsi (Minber)**. Existing methods, default settings, and saved method IDs are unchanged. Minber uses the selected supported Azerbaijani city’s published timetable; it is not a calculated approximation. The existing madhab preference is retained but its control is disabled for this source, because the published Asr time is fixed. Minute adjustments still apply locally.

The app requests Minber’s city directory and monthly JSON schedule over HTTPS. Supported cities are matched by directory names with a few transliteration aliases; unsupported/foreign/unresolved cities and unavailable dates show an error rather than using Baku or another calculation method. The source’s Hijri date and Asia/Baku timezone are used. Cached daily times retain the existing offline behavior; monthly responses are reused in memory for 15 minutes. Countdown, widgets, and the seven-day notification window use the same repository results. Attribution is shown in the method name and Settings explanation.

Provider: https://namaz.minber.az/api and `/json/{city}/{year}/{month}`. Minber states that the schedules are based on QMİ-provided tables; this is a third-party distribution, not a claim of an official QMİ API or endorsement.

Sunrise is shown after Fajr on the Prayer Times homepage. It uses AlAdhan’s `Sunrise`, Minber’s `gunes`, or Adhan Swift’s local sunrise, formatted in the prayer location’s timezone. It is optional for compatibility with existing cached schedules and is kept separate from the five prayers, countdown selection and prayer adjustments. Settings offers a separate optional sunrise notification, off by default. Missing sunrise data does not prevent the prayer schedule from loading.
