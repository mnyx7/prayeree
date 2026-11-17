# Home Screen widgets

Islamic Companion includes a WidgetKit extension named `IslamicAppWidgets` with three separate widgets:

| Widget | Sizes | Tap action |
| --- | --- | --- |
| Prayer times | Small, medium | Open Prayer Times |
| Ayah of the Day | Small, medium, large | Open the displayed surah and ayah |
| Continue reading | Small, medium | Resume the last saved surah and ayah |

The widgets use native WidgetKit containers, light/dark adaptation, English/Arabic strings, and the app's green accent. Widget previews are available at the bottom of `IslamicApp/Widgets/CompanionWidgets.swift` in Xcode.

## Signing and App Group setup

The app and extension share display snapshots through this App Group:

```text
group.com.minayayagubova.islamiccompanion
```

The entitlements and target settings are already checked in. On the Apple developer team used to sign the app:

1. Select the `IslamicApp` target in Xcode → Signing & Capabilities.
2. Enable App Groups and register/select the identifier above.
3. Select `IslamicAppWidgets` and enable the **same** group, using the **same development team**.
4. Let automatic signing update the provisioning profiles for both targets. If using manual profiles, regenerate both profiles with App Groups enabled.
5. Build and run the containing app on your iPhone/iPad once.

The app identifier is `com.minayayagubova.islamiccompanion`; the extension identifier is `com.minayayagubova.islamiccompanion.widgets`. Change the group, both entitlements, `CompanionWidgets.appGroup`, and target settings together if you change bundle identifiers.

Without a provisioned App Group, the app can still run, but the extension cannot access its saved prayer/reading data and will show its setup/empty state. An unsigned simulator build does not verify developer-account capability registration.

## Add a widget

After installing and opening the app, choose a prayer location, open Quran, and read a few ayahs. Then long-press the Home Screen → Edit/Add Widget → search for **Islamic Companion**. Choose a widget and size, then add it. Exact menu wording depends on your iOS version.

## Data and refresh behavior

### Prayer times

For calculated methods, the app publishes seven days of on-device prayer calculations using the current location, method, madhab, timezone, and adjustments. With QMİ/Minber selected, published timetable days loaded by the app populate the forecast instead; no other calculation method is substituted. Fresh prayer data loaded by the app can update the corresponding day. Widget timelines advance at prayer boundaries and local midnight without needing a network request for each change. The medium widget includes the day's five prayer times. Sunrise appears in the app and can have its own Settings reminder; it is not added as a sixth prayer to the widget countdown.

The widget uses the last location/settings supplied by the app; it does not request GPS permission or track location itself. Reopen the app to refresh the forecast after travel or once the seven-day forecast runs out. Expired forecasts show an open-app prompt rather than old times presented as current.

### Ayah of the Day

The widget currently displays **only the surah/ayah reference** and an open-reader action, as requested until Quran permissions are confirmed. It uses the same local-date selection algorithm as the app. It can obtain the reference from chapter metadata without fetching verse text; it does not display or persist Arabic or translation text. Tapping the widget opens that ayah in the app's online reader.

The reference expires at local midnight. WidgetKit controls when background refreshes run, so an exact midnight update is not guaranteed. When no current reference is available, an open-app prompt appears instead of yesterday's reference.

### Continue reading

Visible-ayah changes are saved immediately to the shared snapshot. Timeline reload requests are debounced while scrolling and flushed when the app becomes inactive, to avoid repeatedly spending WidgetKit's refresh budget. Tapping resumes the exact saved verse. No verse text is stored in this progress snapshot.

## Storage and privacy

Only widget display snapshots and Quran translation/language settings are copied to the App Group, not the app's entire preferences database. Prayer snapshots contain the city label, timezone, and calculated times; they do not include GPS coordinates. Reading snapshots contain a surah label/reference and ayah number. The daily shared snapshot contains only the verse reference and translation/language preferences, not Arabic or translation text.

Shared files are written atomically, excluded from backup, and protected until the first device unlock following a restart. The Continue Reading view is marked privacy-sensitive. The extension's daily-verse requests have the same provider/privacy considerations as the main app. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## Verification

The app and embedded extension build together. The regression suite covers snapshot round trips, missing App Group handling, forecast rollover, daily-verse expiry, selected-translation checks, saved-reading publication, URL validation, and exact-ayah routing.

A signed physical-device run is still required to verify App Group provisioning, widget gallery behavior/layout, Home Screen updates, and warm/cold-launch navigation. These checks do not resolve the other App Store release requirements documented in [README.md](README.md).
