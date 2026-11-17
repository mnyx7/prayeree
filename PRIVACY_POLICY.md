# Islamic Companion — Privacy Policy

**Last updated:** 17 November 2026

**Developer:** Minaya ([mnyx7](https://github.com/mnyx7))

## 1. Scope

This document explains the current data flows in Islamic Companion (`prayeree`), an iOS application providing prayer times, Qibla direction, and Quran reading. It distinguishes information kept on your device from information sent to external providers to deliver requested features.

The current app has no developer-operated account, login, advertising, analytics, payment, or cloud-sync service. The app does not intentionally transmit reading progress or favorite verse references to the developer. External services still receive the information necessary to answer API requests, including ordinary connection information.

## 2. Information and purposes

| Information | Purpose | Where it is processed/stored |
| --- | --- | --- |
| Current coordinates, if you allow location access | Automatic prayer location and Qibla bearing | Coordinates are used on-device, may be stored as the last resolved location, are sent to AlAdhan when that source is used for prayer/sunrise requests, and can be sent to Apple for reverse geocoding |
| Manually selected cities, favorites, and recent cities | Prayer location and quick switching | Stored on-device; AlAdhan receives selected coordinates for its prayer/sunrise requests. With QMİ/Minber selected, Minber receives a timetable city slug, year, and month instead |
| City search text | Find a city or country/city combination | Sent to Apple's geocoding service; query/results can remain temporarily in app memory |
| Compass heading and accuracy | Show the direction toward the Kaaba | Used on-device; no app code sends heading data to the developer or content providers |
| Surah/ayah references, translation choice, and language | Retrieve Quran content | Sent in requests to Quran.com / Quran Foundation; the provider also receives ordinary request/connection information such as IP address |
| Reading position and Quran favorite references | Continue reading and reopen saved surahs/ayahs | Stored on-device with surah display metadata; not intentionally uploaded by this app |
| Reading size/mode, appearance, calculation method, madhab, and adjustments | Apply your preferences | Stored on-device; calculation settings are included in relevant AlAdhan requests |
| Notification preferences and scheduled reminders | Prayer, optional sunrise, and daily Quran reminders | Stored on-device and scheduled with Apple's local notification system |
| Copied or shared verse text | Your explicit copy/share action | Written to the system clipboard or passed to the destination you choose |

Manually selecting a city avoids using GPS for that selection, but city search still requires Apple geocoding, and AlAdhan requests still send the selected city's coordinates. If you select the optional QMİ/Minber timetable instead, Minber receives only the timetable city slug, year, and month; coordinates, madhab, and minute adjustments are not sent to Minber.

## 3. External services

The current build contacts these services directly from your device:

- **AlAdhan:** receives prayer location, requested date, calculation method, madhab, and minute adjustments for prayer times and sunrise. See [AlAdhan's credits and terms](https://aladhan.com/credits-and-terms).
- **Minber.az (optional QMİ timetable):** receives a request for its city directory and the selected timetable city slug, year, and month for prayer times and sunrise, plus ordinary connection information such as IP address. GPS coordinates, madhab, manual adjustments, and notification preferences are not sent to Minber. Monthly responses are reused briefly in memory; daily prayer times use the existing on-device prayer cache. See [Minber prayer times](https://namaz.minber.az/).
- **Quran.com / Quran Foundation:** receives requested content references and translation/language parameters. See [Quran.com's privacy policy](https://quran.com/privacy) and [Quran Foundation's developer terms](https://api-docs.quran.com/legal/developer-terms/).
- **Apple:** provides location authorization, geocoding, local notifications, and operating-system services. See [Apple's privacy information](https://www.apple.com/legal/privacy/).

These providers may process IP addresses, server logs, and other information under their own policies. The developer does not control their retention periods. The final App Store privacy disclosures must account for the actual practices of all applicable service providers.

Adhan Swift calculates prayer times on-device; the calculation library does not require a remote request. The current networking client uses an ephemeral URLSession with persistent URLCache disabled. This does not prevent providers from retaining their own request logs.

## 4. Local storage, retention, and deletion

Preferences, selected locations, saved cities, reading progress, and Quran favorite references are stored in the app's local UserDefaults. Fetched prayer times and available sunrise times are cached as JSON files in the app's Application Support directory. Quran responses are fetched online and are not saved as an offline content cache. The daily ayah widget stores a verse reference, without Arabic or translation text. Shared widget files are excluded from backup. These local files/settings may be included in backups according to your device and Apple's backup settings; the app does not implement its own iCloud synchronization.

Current local preferences and saved references remain until you change/remove them or remove the app. Favorite entries can be removed through the app's star/edit controls. Removing the app removes its local app container, subject to Apple's offloading, backup, and restore behavior; offloading an app is different from deleting it.

Quran content from older builds is removed from the file cache on initialization. Legacy daily ayah widget text is discarded when read. Offline Quran reading requires a future approved Content Sync integration; regular API responses are used only for online display.

Reading-position and favorite saves contain references and display metadata rather than additional copies of the Arabic verse or translation text. Verse and translation text are not persisted in the fetched-content cache.

## 5. Notifications

Notifications are local notifications scheduled on the device through Apple's UserNotifications framework. This implementation does not register for remote push notifications or send a push device token to a developer server.

You can allow or disable notifications in iOS Settings and change reminder preferences in the app. Prayer reminders and the optional sunrise reminder cover a rolling seven-day window refreshed when the app becomes active or relevant settings change. Sunrise reminders are off by default and can be enabled independently in Settings; previous preferences retain their existing prayer settings when upgrading. Sunrise uses the selected source or local calculation and the prayer location’s timezone. If a sunrise time is unavailable or already past, no sunrise reminder is scheduled for that date. Sunrise does not change the five-prayer countdown. Turning its toggle off cancels pending sunrise reminders. The selected notification sound and iOS authorization apply to both prayer and sunrise alerts. No notification preference is sent to a content provider. The daily Quran reminder repeats at 08:00 local time. Permission settings, Focus, system notification configuration, and device state can affect delivery and sound.

## Home Screen widgets

If you add widgets, the app and its WidgetKit extension share local display snapshots through an App Group. These include prayer times with a city label/timezone, the daily ayah reference, selected translation/language settings, and the last-read surah/ayah reference. The daily widget is reference-only until permissions are confirmed; it does not display or persist Arabic or translation text. iOS manages rendered widget snapshots. The widget prayer snapshot does not contain GPS coordinates, and the reading snapshot does not contain verse text.

The extension can request chapter metadata from Quran.com / Quran Foundation to select today's ayah reference, without requesting verse text. For this widget metadata lookup, the provider receives the requested metadata/language parameters and connection information. Opening the online reader can then request verse/translation content as described above. Widget refresh timing is controlled by iOS. The extension does not request GPS or use a developer-operated widget server.

Shared snapshot files are excluded from backup and protected until the first device unlock after restart. A widget may visibly reveal content or a reading reference to someone who can view your Home Screen; you can remove the widget through iOS controls. The Continue Reading widget is marked privacy-sensitive, subject to system behavior.

## 6. Copying, sharing, and support

Copying an ayah writes text to the system clipboard. Clipboard availability on your other devices can depend on Apple's Universal Clipboard settings. Sharing passes the selected text to the app/service you choose, which then handles it under its own privacy terms.

The app does not automatically send diagnostic reports to the developer. Information you choose to include in a support request is handled by the channel you use, such as GitHub Issues. Public issue content can be visible to other people; email minaya.yagubova@icloud.com for private support or privacy requests.

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

This policy will be updated when the app's data flows, providers, retention, or features change. The date above identifies the latest revision.

Contact Minaya at [minaya.yagubova@icloud.com](mailto:minaya.yagubova@icloud.com) for support and privacy requests. See [CONTACT.md](CONTACT.md) for reporting guidance. Do not send sensitive information in a public issue.
