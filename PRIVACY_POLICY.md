# Islamic Companion — Privacy Policy

**Draft updated:** 14 November 2026

**Developer:** Minaya ([mnyx7](https://github.com/mnyx7))

> Draft for the current development build. This policy must be reviewed, completed with a verified public/private contact route, and published at a publicly reachable URL before App Store release. It is not yet an effective policy for a public release. See the release requirements in the [README](README.md).

## 1. Scope

This document explains the current data flows in Islamic Companion (`prayeree`), an iOS application providing prayer times, Qibla direction, and Quran reading. It distinguishes information kept on your device from information sent to external providers to deliver requested features.

The current app has no developer-operated account, login, advertising, analytics, payment, or cloud-sync service. The app does not intentionally transmit reading progress or favorite verse references to the developer. External services still receive the information necessary to answer API requests, including ordinary connection information.

## 2. Information and purposes

| Information | Purpose | Where it is processed/stored |
| --- | --- | --- |
| Current coordinates, if you allow location access | Automatic prayer location and Qibla bearing | Coordinates are used on-device, may be stored as the last resolved location, are sent to AlAdhan for prayer-time requests, and can be sent to Apple for reverse geocoding |
| Manually selected cities, favorites, and recent cities | Prayer location and quick switching | Stored on-device; selected coordinates are sent to AlAdhan when requesting prayer times |
| City search text | Find a city or country/city combination | Sent to Apple's geocoding service; query/results can remain temporarily in app memory |
| Compass heading and accuracy | Show the direction toward the Kaaba | Used on-device; no app code sends heading data to the developer or content providers |
| Surah/ayah references, translation choice, and language | Retrieve Quran content | Sent in requests to Quran.com / Quran Foundation; the provider also receives ordinary request/connection information such as IP address |
| Reading position and Quran favorite references | Continue reading and reopen saved surahs/ayahs | Stored on-device with surah display metadata; not intentionally uploaded by this app |
| Reading size/mode, appearance, calculation method, madhab, and adjustments | Apply your preferences | Stored on-device; calculation settings are included in relevant AlAdhan requests |
| Notification preferences and scheduled reminders | Prayer and daily Quran reminders | Stored on-device and scheduled with Apple's local notification system |
| Copied or shared verse text | Your explicit copy/share action | Written to the system clipboard or passed to the destination you choose |

Manually selecting a city avoids using GPS for that selection, but city search still requires Apple geocoding, and remote prayer-time requests still send the selected city's coordinates to AlAdhan.

## 3. External services

The current build contacts these services directly from your device:

- **AlAdhan:** receives prayer location, requested date, calculation method, madhab, and minute adjustments. See [AlAdhan's credits and terms](https://aladhan.com/credits-and-terms).
- **Quran.com / Quran Foundation:** receives requested content references and translation/language parameters. See [Quran.com's privacy policy](https://quran.com/privacy) and [Quran Foundation's developer terms](https://api-docs.quran.com/legal/developer-terms/).
- **Apple:** provides location authorization, geocoding, local notifications, and operating-system services. See [Apple's privacy information](https://www.apple.com/legal/privacy/).

These providers may process IP addresses, server logs, and other information under their own policies. The developer does not control their retention periods. The final App Store privacy disclosures must account for the actual practices of all applicable service providers.

Adhan Swift calculates prayer times on-device; the calculation library does not require a remote request. The current networking client uses an ephemeral URLSession with persistent URLCache disabled. This does not prevent providers from retaining their own request logs.

## 4. Local storage, retention, and deletion

Preferences, selected locations, saved cities, reading progress, and Quran favorite references are stored in the app's local UserDefaults. Fetched prayer and Quran content is cached as JSON files in the app's Application Support directory. These local files/settings may be included in backups according to your device and Apple's backup settings; the app does not implement its own iCloud synchronization.

Current local preferences and saved references remain until you change/remove them or remove the app. Favorite entries can be removed through the app's star/edit controls. Removing the app removes its local app container, subject to Apple's offloading, backup, and restore behavior; offloading an app is different from deleting it.

**Development-build retention limitation:** the current JSON cache has no automatic expiry or in-app clear-all control. Before public release, its Quran-content retention/offline behavior must be brought into compliance with the provider's storage and Content Sync requirements. This draft does not claim that indefinite cached Quran storage is authorized.

Reading-position and favorite saves contain references and display metadata rather than additional copies of the Arabic verse or translation text. The separate fetched-content cache can contain that text.

## 5. Notifications

Notifications are local notifications scheduled on the device through Apple's UserNotifications framework. This implementation does not register for remote push notifications or send a push device token to a developer server.

You can allow or disable notifications in iOS Settings and change reminder preferences in the app. Prayer reminders currently cover a rolling seven-day window refreshed when the app becomes active or relevant settings change. The daily Quran reminder repeats at 08:00 local time. Permission settings, Focus, system notification configuration, and device state can affect delivery and sound.

## 6. Copying, sharing, and support

Copying an ayah writes text to the system clipboard. Clipboard availability on your other devices can depend on Apple's Universal Clipboard settings. Sharing passes the selected text to the app/service you choose, which then handles it under its own privacy terms.

The app does not automatically send diagnostic reports to the developer. Information you choose to include in a support request is handled by the channel you use, such as GitHub Issues. Public issue content can be visible to other people; use a verified private contact route for sensitive requests once one is provided.

## 7. Your choices

- Decline or revoke location permission in iOS Settings and use a manually selected prayer city. Live Qibla functionality requires location access.
- Disable notification permission or individual reminder preferences.
- Remove favorite cities, surahs, and ayahs through their controls.
- Choose whether to copy/share content or submit a support request.
- Delete the app to remove its local app container, subject to Apple's backup/restore behavior.

The app has no server-side account to delete. Requests about information retained by external providers should also be directed to those providers.

## 8. Security and international processing

API requests use HTTPS. Access to local app storage is subject to iOS sandboxing and platform security. No transmission or storage system can be guaranteed completely secure.

Requests to third-party services may be processed in countries different from your own. The developer has not independently established every provider's hosting locations or legal transfer arrangements; these must be reviewed as appropriate before a public release.

## 9. Children

The current application does not provide child accounts, age profiling, advertising, or an intentional mechanism for collecting children's personal information. This does not declare the app to be part of Apple's Kids Category. The developer must choose the appropriate App Store audience/age rating and review any additional obligations before targeting children.

## 10. Changes and contact

This policy should be updated when the app's data flows, providers, retention, or features change. A published policy should state its effective date.

For the current developer profile and available support channels, see [CONTACT.md](CONTACT.md). A verified private support/privacy email and public policy/support URLs are still outstanding before App Store release. Do not send sensitive information in a public issue.
