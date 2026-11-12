# Islamic Companion

Current update: the Xcode project and app icon are included. Prayer times now have immediate on-device calculations using Adhan Swift 1.5.0 when the remote provider is unavailable. Settings and Home share saved cities, with add/remove/reorder controls through the Home favorites menu. Quran uses paginated verse requests, translation search, and Saheeh International resource ID 20. The app builds and all 113 simulator unit tests pass; older phase-by-phase notes below describe the initial implementation.
Latest polish: Quran pickers use native automatic search placement; the active city is highlighted and repeated selections skip reloading. Daily ayahs are fixed per local day and translation-independent, with a midnight refresh. Copy provides visible and haptic feedback. Notification permission requests, foreground presentation, daily reminders without a location, and foreground schedule renewal are wired up; the test-notification button reports permission or scheduling failures.


A native iOS companion app for daily worship: accurate prayer times with reminders, a Qibla compass, and a full Quran reader with translations — built calm, accessible, and offline-resilient by default.

## Feature Overview

- **Prayer Times** — five daily prayers with a live countdown to the next one, Hijri date, automatic or manual location, favorite/recent cities, configurable calculation method and madhab, per-prayer manual minute adjustments.
- **Qibla** — a live compass pointing toward the Kaaba, computed locally from device coordinates, with a numeric fallback when no magnetometer is available and calibration guidance when accuracy drops.
- **Quran** — all 114 surahs, ayah-by-ayah reading with translations, a daily ayah card, adjustable font size, Arabic-only or Arabic+translation modes, copy/share.
- **Settings** — location mode, calculation method/madhab, per-prayer notification toggles, daily Quran reminder, appearance (system/light/dark), About.
- Offline-first throughout: every screen shows cached content immediately and refreshes in the background, never blocking on the network when there's something usable to show.
- English and Arabic localization, including full right-to-left support for Arabic Quran text regardless of the app's display language.

## Architecture

**Store-based, unidirectional data flow. No ViewModels, anywhere.**

Each feature owns a single `@Observable` **Store** — a `@MainActor` class with a nested `State` struct and a nested `Action` enum. Views read `State` reactively and send `Action`s through a single `send(_:)` entry point; the Store is the only thing that mutates its own state. Side effects (networking, caching, location, compass, notifications) never happen in a View — they happen inside a Store, through injected protocol-typed dependencies.

```text
SwiftUI View
    │  reads State
    │  sends Action  →  store.send(.refreshRequested)
    ▼
Feature Store (State + Action, @MainActor @Observable)
    │  calls
    ▼
Repository (cache-first orchestration)
    │  combines
    ├──► Service (protocol) → APIClient → remote API
    └──► CacheStore (protocol) → FileCacheStore → disk
    │
    ▼
DTO → Mapper → Domain Model
    │
    ▼
back into Store.State  →  View re-renders
```

### State ownership

- **`AppState`** (owned by `AppStore`, in `App/`) holds only what's genuinely cross-cutting: location source mode + resolved coordinates + selected city/country, appearance mode, prayer calculation method/madhab/adjustments, and notification authorization status. Every field here is needed by more than one feature.
- **Feature-local state** (selected date, active sheet, search results, loading/error state, reading preferences, etc.) lives entirely inside that feature's own `Store.State` and is never duplicated into `AppState`.
- Cross-feature coordination — e.g. "the user changed calculation method, prayer notifications need rescheduling" — flows through `AppStore`, never through direct Store-to-Store calls. `SettingsStore` and `PrayerTimesStore` both call `appStore.send(...)`; `AppStore` is the one place that reacts and coordinates.

### Dependency injection

There is exactly one composition root: **`AppEnvironment`** (`App/AppEnvironment.swift`). It constructs every concrete production dependency — `APIClient`, `FileCacheStore`, `UserDefaultsPreferencesStore`, `LocationManager`, `CompassManager`, `QiblaCalculator`, `NotificationManager`, and the two notification schedulers — exactly once, behind their protocols. Nothing outside `AppEnvironment.live()` ever calls a concrete initializer for a production dependency.

Feature Stores never construct their own repositories or services from scratch — `RootTabView.init` builds each feature's repository from `environment`'s already-injected `apiClient`/`cacheStore`, then hands it to that feature's Store. Detail-scoped Stores (like `QuranReaderStore`, one per surah) follow the same rule one level down: `QuranStore.makeReaderStore(for:)` composes a `QuranReaderStore` from its own already-injected dependencies, never from raw concrete types.

**Store lifecycle**: the four tab-level Stores (`PrayerTimesStore`, `QiblaStore`, `QuranStore`, `SettingsStore`) are created once in `RootTabView.init` and held in `@State` for the app's lifetime, so switching tabs never resets a screen's state. `QuranReaderStore` is the one exception — it's a detail screen, scoped to navigation lifetime, built fresh per surah.

## Folder Structure

```text
IslamicApp/
├── App/                    Composition root, global state, root navigation
├── Core/
│   ├── Networking/          Generic HTTP client, Endpoint protocol
│   ├── Persistence/         File cache + UserDefaults-backed preferences
│   ├── Notifications/       UNUserNotificationCenter wrapper + 2 schedulers
│   ├── Location/            CoreLocation wrapper, compass, Qibla math
│   ├── DesignSystem/        Color/type/spacing/radius tokens, shared components
│   ├── Localization/        LocalizedKey namespace, LocalizationManager
│   ├── Utilities/           Date formatting, Hijri calendar, small extensions
│   └── Models/               Domain models (Common / Prayer / Qibla / Quran)
├── Features/
│   ├── PrayerTimes/         Store, data layer (DTO/Mapper/Service/Repository), View, Components, Sheets
│   ├── Qibla/                Store, View, Components
│   ├── Quran/                2 Stores (top-level + reader), data layer, 3 top-level Views, Components
│   └── Settings/             Store, View, 3 sub-screens, Components
├── Resources/
│   ├── Localizable.xcstrings  English + Arabic, 150 keys
│   ├── Assets.xcassets         10 semantic color sets (light + dark)
│   └── PreviewContent/         Sample data + fake environment for SwiftUI Previews
└── Tests/
    ├── AppTests/ PrayerTimesTests/ QiblaTests/ QuranTests/ SettingsTests/
    └── TestSupport/          Mocks, in-memory fakes, shared test environment factory
```

`Core` never imports `Features`. `Features` never import each other — the one place two features share behavior (Settings' city search mirrors PrayerTimes') is done by re-implementing the same *pattern* against shared `PreferencesStore` keys, not by importing code across the feature boundary. `App` is the only layer allowed to depend on `Features`, and does so exactly once (`AppStore`'s notification-rescheduling coordinator uses `PrayerTimesRepository`).

## Remote Data Sources

| Domain | Provider | Auth | Notes |
|---|---|---|---|
| Prayer times, Hijri date | [AlAdhan API](https://aladhan.com/prayer-times-api) (`api.aladhan.com/v1`) | None | Free, public. Supports calculation method, madhab (`school`), and per-prayer minute offsets (`tune`) as query params. |
| Quran text, translations, daily ayah | [Quran.com API v4](https://quran.com/api) (`api.quran.com/api/v4`) | None for read endpoints | Public, no key. No documented rate-limit SLA — the app leans on cache-first behavior specifically because of this. |
| Reverse geocoding, city search | `CLGeocoder` (CoreLocation) | None (on-device) | Also used for "search for a city" — see Known Limitations for why there's no bundled country/city dataset. |
| Country list | `Locale.isoRegionCodes` (Foundation) | None | Derived at runtime, not fetched or bundled. |

No API keys are required anywhere in this app. There is nothing to configure in that respect before building.

## Cache Behavior

Every remote-backed screen (Prayer Times, Qibla's location, Quran) follows the same cache-first contract, implemented once per feature's Repository:

1. Check `FileCacheStore` for a valid entry.
2. If present, yield it immediately (`freshness: .cached`) — the screen renders without waiting on the network.
3. Fetch fresh data from the network.
4. On success: save to cache, yield again (`freshness: .fresh`).
5. On failure: if a cached value exists, keep showing it with the error attached (the UI shows a "showing cached data" banner, not an error screen). Only when there is **no** cache and the network also fails does the screen show a full error state.

Cached: prayer times (keyed by date + rounded coordinates + calculation method + madhab + adjustments), the surah list, fetched ayahs (per surah + translation), the daily ayah (partitioned by calendar day, so it's stable all day rather than re-randomizing per visit), the translation list, favorite/recent cities, favorite/recent surahs, reading preferences, notification preferences, and the entire `AppState` blob (location mode, appearance, calculation settings) — everything except live notification-authorization status, which is always re-queried from the OS.

## Notification Behavior

- Authorization is requested **contextually** (from Settings, when the user acts), never at launch.
- Prayer notifications use a **rolling 7-day window**, recomputed — not just re-sent — whenever the app launches or relevant state changes (location, calculation method, madhab, adjustments, per-prayer toggles, sound). The coordinator lives in `AppStore`, the only place that watches all of those inputs at once.
- Every prayer notification has a **stable, deterministic identifier**: `prayer.<name>.<yyyyMMdd>`. Rescheduling always cancels-then-replaces by that identifier, so there are never duplicates.
- The daily Quran reminder uses a single fixed identifier (`quran.dailyAyah`) at a fixed 8:00 AM local time (the spec calls for a toggle, not a custom time picker).
- **Known limitation**: there is no `BGAppRefreshTask` registered, so the 7-day window only recomputes while the app is actually opened. A DST transition occurring while the app stays backgrounded for several days won't be caught until the next launch.
- **Custom notification sounds**: iOS requires a bundled `.caf`/`.aiff`/`.wav` asset (≤30s) for a custom `UNNotificationSound`; none ships in this V1, so the sound picker offers only "Default." The architecture (identifier plumbing, sound name parameter threaded through both schedulers) is ready for real sound files to be dropped in later.
- Notifications are never scheduled from a View — only from `SettingsStore` (test notification, permission request) and `AppStore` (the rescheduling coordinator).

## Location Permission Behavior

Two explicit modes, `LocationSourceMode.automatic` / `.manual(country:city:)` — switching between them is always a direct user action (a toggle in Settings, or "Use Current Location" in a picker), never silent.

- **Automatic**: requests when-in-use authorization only when the user opts in, resolves a one-shot location via `CLLocationManager.requestLocation()`, reverse-geocodes to a city name via `CLGeocoder`. On denial, restriction, or failure, the app falls back to the last manually-selected city rather than blocking the screen.
- **Manual**: city search via `CLGeocoder` forward-geocoding (debounced 400ms), plus recents and favorites. The full country list (for "browse by country") comes from `Locale.isoRegionCodes`, not a bundled dataset — see Known Limitations for why.
- Qibla additionally uses **continuous heading updates** while its tab is visible only — both the location request and the compass stream are torn down in `.screenDisappeared`, unlike Prayer Times' comparatively cheap countdown timer.

## Compass Limitations

- Qibla direction itself is computed **locally** via the great-circle initial-bearing formula — it needs only the device's coordinates, not live network access.
- Devices without a magnetometer (some iPads, all Simulators) report `CLLocationManager.headingAvailable() == false`; the app falls back to showing the calculated numeric bearing with an explicit "live compass unavailable" message instead of a dead compass needle.
- When heading accuracy is poor (`headingAccuracy > 15°`), a calibration hint appears: *"Move your phone in a figure-8 if the direction seems incorrect,"* with a note that magnetic interference near metal or electronics can affect accuracy.

## Localization

- English and Arabic, via `Resources/Localizable.xcstrings` (150 keys, both languages complete — **representative, not professionally reviewed** translations).
- Every user-facing string in every View, and every Store-generated error/notification message, resolves through `Core/Localization/LocalizedKey` — a namespaced set of `LocalizedStringResource` constants, deliberately keyed by stable dotted identifiers (`"prayer_times.tab_title"`) separate from their English `defaultValue`, so renaming the English copy never touches the key and API-provider naming never leaks into display text.
- The countdown's on-screen "01:24" format is intentionally unchanged for VoiceOver-unfriendliness reasons — instead, `.accessibilityLabel` carries a separately-pluralized natural-language phrase ("Next prayer: Maghrib in 24 minutes"), using `String(localized:defaultValue:)`'s automatic ICU plural-rule resolution rather than a hand-rolled singular/plural check, because Arabic has six plural categories (zero/one/two/few/many/other) that a naive check would get wrong.
- Arabic Quran text is forced right-to-left via `.environment(\.layoutDirection, .rightToLeft)` regardless of the app's display language — Quranic Arabic should read right-to-left even for an English-locale user. General app layout mirrors automatically under an Arabic system locale via SwiftUI's built-in RTL support; nothing forces a direction elsewhere.
- `LocalizationManager.isRightToLeft` exposes the current language's direction for the few places that need to know explicitly rather than relying on automatic mirroring.

## Dark Mode

Dark mode is a genuinely distinct palette, not `.opacity()` inversion. Ten semantic color tokens (`Core/DesignSystem/AppColor.swift`) each have independently-chosen light/dark values in `Assets.xcassets`: background (primary/elevated), text (primary/secondary), accent, divider, cached-data banner, warning, error, and a dedicated Quran-reading background. The accent color specifically goes from a deeper teal in light mode to a brighter, more saturated teal in dark mode — a straight inversion would have made it *less* visible against a dark background, which is backwards for accessible dark-mode design.

"Active prayer" highlighting has no color asset of its own — it's `accent.opacity(0.12)`, computed in code, since it's structurally a *use* of the one controlled accent color rather than an independent hue.

## Testing

**Test doubles** (`Tests/TestSupport/`): `MockAPIClient` (closure-based, inspects the `Endpoint` type to decide what to return), `InMemoryCacheStore`, `InMemoryPreferencesStore`, `MockLocationManager`, `MockCompassManager`, `MockNotificationManager`, and `TestEnvironmentFactory` (builds a full `AppEnvironment` from all of the above, shared across every Store test to avoid repeating a 9-parameter construction).

**Coverage**: domain logic (prayer ordering, countdown math, Qibla bearing including algebraically-exact and known-city cases, reading-preference clamping), infrastructure (file cache read/write/eviction, preferences persistence, mock API behavior), every Store (`PrayerTimesStore`, `QiblaStore`, `QuranStore`, `QuranReaderStore`, `SettingsStore`, `AppStore`), both repositories' cache-first and stale-fallback behavior, and notification scheduling decisions (identifier generation, disabled-prayer skipping, past-time skipping, cancel-scoping, no-duplicate-on-reschedule).

Tests never hit real networking, location services, or notification delivery — everything routes through the mocks above. Async Store tests that depend on an internally-spawned `Task` completing use a short `Task.sleep` after dispatching the triggering action, since Stores don't expose an "await all in-flight work" hook; this is a known small source of potential timing flakiness, flagged rather than hidden.

To run: once the project is open in Xcode (see Configuration below), `Cmd+U` runs the full suite, or `xcodebuild test -scheme IslamicApp -destination 'platform=iOS Simulator,name=iPhone 15'` from the command line.

## Configuration Instructions

This repository contains Swift source files and a real `Assets.xcassets`/`Localizable.xcstrings`, but **no `.xcodeproj` has been generated** — that's the one manual step standing between this code and a running app:

1. Create a new iOS App project in Xcode (SwiftUI interface, Swift language), targeting **iOS 17.0+**.
2. Add every file under `App/`, `Core/`, `Features/`, and `Resources/` to the app target; add every file under `Tests/` to a new unit test target.
3. Add to the app target's `Info.plist` (or the target's Info tab):
   - `NSLocationWhenInUseUsageDescription` — required before `requestWhenInUseAuthorization()` will do anything but silently fail. Something like: *"Your location is used to calculate accurate prayer times and Qibla direction."*
4. No third-party dependencies to resolve — there are none (see Phase 0 assumption). System frameworks used: `CoreLocation`, `UserNotifications`, `CryptoKit`, `AudioToolbox`, `Observation`. Modern Xcode links these automatically from `import` statements; no manual linking step should be needed.
5. No API keys, `.env` files, or secrets of any kind — every remote data source is unauthenticated (see Remote Data Sources above).
6. Optional: add an `AppIcon.appiconset` inside `Assets.xcassets` — none is included, since generating real icon image assets isn't possible from source text alone.

## API-Key Handling

None required. Both remote APIs (AlAdhan, Quran.com) are public and unauthenticated for the endpoints this app uses. If a future provider swap requires a key, the `Endpoint` protocol's `headers` property is the intended injection point — it should read from a build configuration or Keychain, never a literal in source.

## Known Limitations

- **No `.xcodeproj`** — this is source only; see Configuration Instructions.
- **No `AppIcon`** — requires real image assets not creatable from text.
- **Arabic translations are representative, not professionally reviewed** — flagged from Phase 0 onward; a native-speaker pass is recommended before shipping.
- **No background notification refresh** — the 7-day rolling window only recomputes on launch/foreground; a DST change during several backgrounded days could produce a stale-by-an-hour notification until the next open.
- **Custom notification sounds are architecturally ready but not populated** — V1 ships no bundled audio assets, so only "Default" is selectable.
- **Manual country/city picker has no bundled dataset** — deliberately amended from the original Phase 0 plan to use `Locale.isoRegionCodes` + `CLGeocoder` forward search instead, after determining a hand-authored dataset would only cover a token handful of cities. This means city search requires network/Apple geocoding availability rather than working fully offline.
- **The countdown-plural String Catalog entry** (`prayer_times.countdown_accessibility_format`) uses the most intricate part of the `.xcstrings` schema (multi-argument plural variation) and hasn't been verified against a live Xcode build.
- **Async Store test timing** — a handful of Store tests use `Task.sleep` to wait for internally-spawned work rather than a proper completion hook; see Testing above.
- **Store-test coverage is "at least," not exhaustive** — each Store's tests hit the specific behaviors Phase 13 named explicitly; concurrent-action edge cases and permission-denial branches have thinner coverage than the happy paths.

## Future Roadmap

Explicitly prepared for but not built in V1 (per the original scope):

- **Widgets** — next-prayer and daily-ayah WidgetKit targets. Domain models are already `Codable`/`Sendable`, and migrating `FileCacheStore`/`UserDefaultsPreferencesStore` to an App Group container is a scoped, low-risk follow-up.
- **Quran bookmarks & last-read position** — `QuranBookmark` exists as a model and `.bookmarkTapped`/`currentReadingPosition` exist in `QuranReaderStore`, but nothing persists yet.
- **Quran audio recitation, Juz navigation, continue-reading** — not modeled yet.
- **Monthly prayer calendar, missed-prayer tracking, tasbih counter, Ramadan mode, fasting times** — out of scope for V1 per the original spec; nothing in the current architecture blocks adding them.
- **Multiple saved cities beyond favorites/recents, Apple Watch companion** — not started.
- **Background notification refresh** (`BGAppRefreshTask`) — would close the DST-while-backgrounded gap noted above.
- **Bundled custom notification sound assets.**

## Final Verification

| Area | Status | Notes |
|---|---|---|
| Project structure | Complete | Every file from the approved structure exists (153 Swift files); no `.xcodeproj` — see Configuration Instructions. |
| Store architecture | Complete | 6 Stores (4 tab-level + 1 detail-scoped + AppStore), all `@Observable @MainActor` with nested `State`/`Action`; zero ViewModels anywhere (verified via repo-wide search). |
| Networking | Complete | Generic `Endpoint`/`APIClient`, two providers (AlAdhan, Quran.com), no API keys needed. |
| Cache | Complete | File-based, cache-first with stale fallback, verified by dedicated repository tests for both features. |
| Prayer times | Complete | 5 daily prayers, countdown with day-rollover, calculation method + madhab + manual adjustments, favorites/recents. |
| Qibla | Complete | Local great-circle calculation, live compass with numeric fallback, calibration guidance. |
| Quran | Complete | 114 surahs, ayah reader, translations, daily ayah, font size, Arabic-only/with-translation modes. |
| Settings | Complete | Location mode, calculation settings, per-prayer + daily-ayah notification toggles, sound (Default only — see Known Limitations), appearance, About. |
| Notifications | Complete | Rolling 7-day window, stable identifiers, cancel-and-reschedule, contextual permission requests; no background refresh (see Known Limitations). |
| Localization | Complete | English + Arabic, 150 keys, RTL for Quran text, pluralized accessibility label; one plural schema entry unverified against a live build. |
| Dark mode | Complete | 10 independently-tuned semantic color tokens, not inversion. |
| Tests | Complete | 26 test files covering domain logic, infrastructure, all 6 Stores, both repositories' cache behavior, and notification scheduling; not yet compiled/run (no `.xcodeproj`). |

### Pre-flight checks performed before this README was written

- ✅ No `ViewModel` type anywhere in the codebase (repo-wide search).
- ✅ No `TODO`/`FIXME`/placeholder markers in any production file.
- ✅ Every `AppColor.*`, `AppSpacing.*`, `AppRadius.*`, `AppTypography.*`, and `LocalizedKey.*.*` reference used anywhere in `App/`/`Features/` resolves to an actual declaration (cross-checked programmatically, not by inspection).
- ✅ Every one of the 13 protocols in `Core`/`Features` has exactly one production conformance; 6 also have a dedicated `Mock*`/`InMemory*` test double, and the remaining protocols (both repositories, both notification schedulers, `QiblaCalculating`) are exercised through their real implementations composed with `MockAPIClient`/`InMemoryCacheStore`/`MockNotificationManager` in tests instead.
- ✅ `Core` contains zero references to any `Features` type; `Features` contain zero cross-feature type references (one apparent hit was a false positive — `Features/Settings/PrayerAdjustmentsView.swift` and `PrayerCalculationSettingsView.swift` reference `SettingsStore`, their own feature's Store, not another feature's).
- ✅ No hardcoded user-facing string literals remain outside 4 deliberately-non-linguistic exceptions (a surah-number numeral, a fixed Arabic sample phrase used to preview font size, and two degree-symbol placeholders).
- ⚠️ `Resources/PreviewContent/PreviewData.swift` was missing until this phase — it was explicitly deferred in Phase 2 pending real feature Views, and never revisited once they existed. Created now with representative sample data for all four domains.
