//
//  LocalizedKey.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// Every user-facing string in the app, namespaced by screen. Each key is a
/// stable dotted identifier (e.g. "prayer_times.title") kept deliberately
/// separate from its English `defaultValue` — the identifier never changes
/// even if the English copy is reworded, and it's never shown to a user, so
/// it stays independent of any provider/API naming (AlAdhan, Quran.com).
///
/// `LocalizedStringResource` is what SwiftUI's `Text` and `Button` resolve
/// directly against Resources/Localizable.xcstrings; `defaultValue` is the
/// fallback shown if a language (or the catalog itself) is missing an entry,
/// satisfying the "ensure English fallback behavior" requirement structurally
/// rather than by convention.
enum LocalizedKey {
    enum Common {
        static var copied: LocalizedStringResource { LocalizedStringResource("common.copied", defaultValue: "Copied", table: "Localizable", locale: LocalizationManager.locale) }
        static var copy: LocalizedStringResource { LocalizedStringResource("common.copy", defaultValue: "Copy", table: "Localizable", locale: LocalizationManager.locale) }
        static var addCity: LocalizedStringResource { LocalizedStringResource("common.add_city", defaultValue: "Add city", table: "Localizable", locale: LocalizationManager.locale) }
        static var search: LocalizedStringResource { LocalizedStringResource("common.search", defaultValue: "Search", table: "Localizable", locale: LocalizationManager.locale) }
        static var cancel: LocalizedStringResource { LocalizedStringResource("common.cancel", defaultValue: "Cancel", table: "Localizable", locale: LocalizationManager.locale) }
        static var done: LocalizedStringResource { LocalizedStringResource("common.done", defaultValue: "Done", table: "Localizable", locale: LocalizationManager.locale) }
        static var tryAgain: LocalizedStringResource { LocalizedStringResource("common.try_again", defaultValue: "Try Again", table: "Localizable", locale: LocalizationManager.locale) }
        static var retry: LocalizedStringResource { LocalizedStringResource("common.retry", defaultValue: "Retry", table: "Localizable", locale: LocalizationManager.locale) }
        static var recent: LocalizedStringResource { LocalizedStringResource("common.recent", defaultValue: "Recent", table: "Localizable", locale: LocalizationManager.locale) }
        static var favorites: LocalizedStringResource { LocalizedStringResource("common.favorites", defaultValue: "Favorites", table: "Localizable", locale: LocalizationManager.locale) }
        static var noCitiesFound: LocalizedStringResource { LocalizedStringResource("common.no_cities_found", defaultValue: "No cities found", table: "Localizable", locale: LocalizationManager.locale) }
        static var useCurrentLocation: LocalizedStringResource { LocalizedStringResource("common.use_current_location", defaultValue: "Use Current Location", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectCity: LocalizedStringResource { LocalizedStringResource("common.select_city", defaultValue: "Select City", table: "Localizable", locale: LocalizationManager.locale) }
        static var showingCachedData: LocalizedStringResource { LocalizedStringResource("common.showing_cached_data", defaultValue: "Showing cached data", table: "Localizable", locale: LocalizationManager.locale) }

        static func lastUpdated(_ time: String) -> LocalizedStringResource {
            LocalizedStringResource("common.last_updated_format", defaultValue: "Last updated at \(time)", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func genericLoadError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_generic", defaultValue: "Something went wrong. Please try again.", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func networkLoadError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_network", defaultValue: "Check your internet connection and try again.", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func serviceUnavailableError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_service_unavailable", defaultValue: "The service is unavailable right now.", table: "Localizable", locale: LocalizationManager.locale)
        }
    }

    enum PrayerName {
        static func displayName(for prayer: IslamicApp.PrayerName) -> LocalizedStringResource {
            switch prayer {
            case .fajr: return LocalizedStringResource("prayer_name.fajr", defaultValue: "Fajr", table: "Localizable", locale: LocalizationManager.locale)
            case .dhuhr: return LocalizedStringResource("prayer_name.dhuhr", defaultValue: "Dhuhr", table: "Localizable", locale: LocalizationManager.locale)
            case .asr: return LocalizedStringResource("prayer_name.asr", defaultValue: "Asr", table: "Localizable", locale: LocalizationManager.locale)
            case .maghrib: return LocalizedStringResource("prayer_name.maghrib", defaultValue: "Maghrib", table: "Localizable", locale: LocalizationManager.locale)
            case .isha: return LocalizedStringResource("prayer_name.isha", defaultValue: "Isha", table: "Localizable", locale: LocalizationManager.locale)
            }
        }
    }

    enum HijriMonthName {
        static func displayName(for month: IslamicApp.HijriMonth) -> LocalizedStringResource {
            switch month {
            case .muharram: return LocalizedStringResource("hijri_month.muharram", defaultValue: "Muharram", table: "Localizable", locale: LocalizationManager.locale)
            case .safar: return LocalizedStringResource("hijri_month.safar", defaultValue: "Safar", table: "Localizable", locale: LocalizationManager.locale)
            case .rabiAlAwwal: return LocalizedStringResource("hijri_month.rabi_al_awwal", defaultValue: "Rabi' al-Awwal", table: "Localizable", locale: LocalizationManager.locale)
            case .rabiAlThani: return LocalizedStringResource("hijri_month.rabi_al_thani", defaultValue: "Rabi' al-Thani", table: "Localizable", locale: LocalizationManager.locale)
            case .jumadaAlAwwal: return LocalizedStringResource("hijri_month.jumada_al_awwal", defaultValue: "Jumada al-Awwal", table: "Localizable", locale: LocalizationManager.locale)
            case .jumadaAlThani: return LocalizedStringResource("hijri_month.jumada_al_thani", defaultValue: "Jumada al-Thani", table: "Localizable", locale: LocalizationManager.locale)
            case .rajab: return LocalizedStringResource("hijri_month.rajab", defaultValue: "Rajab", table: "Localizable", locale: LocalizationManager.locale)
            case .shaban: return LocalizedStringResource("hijri_month.shaban", defaultValue: "Sha'ban", table: "Localizable", locale: LocalizationManager.locale)
            case .ramadan: return LocalizedStringResource("hijri_month.ramadan", defaultValue: "Ramadan", table: "Localizable", locale: LocalizationManager.locale)
            case .shawwal: return LocalizedStringResource("hijri_month.shawwal", defaultValue: "Shawwal", table: "Localizable", locale: LocalizationManager.locale)
            case .dhulQadah: return LocalizedStringResource("hijri_month.dhul_qadah", defaultValue: "Dhu al-Qi'dah", table: "Localizable", locale: LocalizationManager.locale)
            case .dhulHijjah: return LocalizedStringResource("hijri_month.dhul_hijjah", defaultValue: "Dhu al-Hijjah", table: "Localizable", locale: LocalizationManager.locale)
            }
        }
    }

    enum PrayerTimes {
        static var sunriseNotificationBody: LocalizedStringResource { LocalizedStringResource("prayer_times.sunrise_notification_body", defaultValue: "The sun is rising in your selected location.", table: "Localizable", locale: LocalizationManager.locale) }
        static var sunrise: LocalizedStringResource { LocalizedStringResource("prayer_times.sunrise", defaultValue: "Sunrise", table: "Localizable", locale: LocalizationManager.locale) }
        static var calculatedLocally: LocalizedStringResource { LocalizedStringResource("prayer_times.calculated_locally", defaultValue: "Calculated on your device using your prayer settings", table: "Localizable", locale: LocalizationManager.locale) }
        static var tabTitle: LocalizedStringResource { LocalizedStringResource("prayer_times.tab_title", defaultValue: "Prayer Times", table: "Localizable", locale: LocalizationManager.locale) }
        static var allPrayersComplete: LocalizedStringResource { LocalizedStringResource("prayer_times.all_complete", defaultValue: "All prayers for today are complete", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectDate: LocalizedStringResource { LocalizedStringResource("prayer_times.select_date", defaultValue: "Select Date", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectLocationPrompt: LocalizedStringResource { LocalizedStringResource("prayer_times.select_location_prompt", defaultValue: "Select a location to see prayer times", table: "Localizable", locale: LocalizationManager.locale) }
        static var chooseCity: LocalizedStringResource { LocalizedStringResource("prayer_times.choose_city", defaultValue: "Choose City", table: "Localizable", locale: LocalizationManager.locale) }
        static var searchForCity: LocalizedStringResource { LocalizedStringResource("prayer_times.search_city", defaultValue: "Search for a city", table: "Localizable", locale: LocalizationManager.locale) }
        static var browseByCountry: LocalizedStringResource { LocalizedStringResource("prayer_times.browse_by_country", defaultValue: "Browse by Country", table: "Localizable", locale: LocalizationManager.locale) }
        static var favoriteCitiesTitle: LocalizedStringResource { LocalizedStringResource("prayer_times.favorite_cities_title", defaultValue: "Favorite Cities", table: "Localizable", locale: LocalizationManager.locale) }
        static var noFavoriteCities: LocalizedStringResource { LocalizedStringResource("prayer_times.no_favorite_cities", defaultValue: "No favorite cities yet. Tap + to find and save a city.", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorLoadFailed: LocalizedStringResource { LocalizedStringResource("prayer_times.error_load_failed", defaultValue: "We couldn't load prayer times. Please try again.", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorLocationDenied: LocalizedStringResource { LocalizedStringResource("prayer_times.error_location_denied", defaultValue: "Location access is denied. Enable it in Settings or choose a city manually.", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorLocationRestricted: LocalizedStringResource { LocalizedStringResource("prayer_times.error_location_restricted", defaultValue: "Location access is restricted on this device. Choose a city manually.", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorLocationUnavailable: LocalizedStringResource { LocalizedStringResource("prayer_times.error_location_unavailable", defaultValue: "We couldn't determine your location. Try again or choose a city manually.", table: "Localizable", locale: LocalizationManager.locale) }

        static func searchingIn(_ country: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.searching_in_format", defaultValue: "Searching in \(country)", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func nextPrayerCountdown(prayer: String, countdown: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.next_prayer_format", defaultValue: "Next prayer: \(prayer) in \(countdown)", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func notificationTitle(prayer: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.notification_title_format", defaultValue: "\(prayer) Prayer", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func notificationBody(prayer: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.notification_body_format", defaultValue: "It's time for \(prayer) prayer.", table: "Localizable", locale: LocalizationManager.locale)
        }

        /// The "day month, year AH" structure itself is language-dependent
        /// (word order, punctuation), not just the month name — this is a
        /// distinct key from HijriMonthName so both can vary independently.
        static func hijriDateLabel(day: Int, month: String, year: Int) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.hijri_date_format", defaultValue: "\(day) \(month), \(year) AH", table: "Localizable", locale: LocalizationManager.locale)
        }
    }

    enum Qibla {
        static var tabTitle: LocalizedStringResource { LocalizedStringResource("qibla.tab_title", defaultValue: "Qibla", table: "Localizable", locale: LocalizationManager.locale) }
        static var kaaba: LocalizedStringResource { LocalizedStringResource("qibla.kaaba", defaultValue: "Kaaba", table: "Localizable", locale: LocalizationManager.locale) }
        static var liveCompassUnavailable: LocalizedStringResource { LocalizedStringResource("qibla.live_compass_unavailable", defaultValue: "Live compass unavailable — showing the calculated direction from true north.", table: "Localizable", locale: LocalizationManager.locale) }
        static var calibrationTitle: LocalizedStringResource { LocalizedStringResource("qibla.calibration_title", defaultValue: "Move your phone in a figure-8 if the direction seems incorrect.", table: "Localizable", locale: LocalizationManager.locale) }
        static var calibrationSubtitle: LocalizedStringResource { LocalizedStringResource("qibla.calibration_subtitle", defaultValue: "Magnetic interference near metal objects or electronics can affect accuracy.", table: "Localizable", locale: LocalizationManager.locale) }
        static var allowLocationAccess: LocalizedStringResource { LocalizedStringResource("qibla.allow_location_access", defaultValue: "Allow Location Access", table: "Localizable", locale: LocalizationManager.locale) }
        static var permissionPromptNotDetermined: LocalizedStringResource { LocalizedStringResource("qibla.permission_not_determined", defaultValue: "Allow location access to find the Qibla direction from where you are.", table: "Localizable", locale: LocalizationManager.locale) }
        static var permissionPromptDenied: LocalizedStringResource { LocalizedStringResource("qibla.permission_denied", defaultValue: "Location access is denied. Enable it in Settings to use the Qibla compass.", table: "Localizable", locale: LocalizationManager.locale) }
        static var permissionPromptRestricted: LocalizedStringResource { LocalizedStringResource("qibla.permission_restricted", defaultValue: "Location access is restricted on this device.", table: "Localizable", locale: LocalizationManager.locale) }
        static var permissionPromptUnknown: LocalizedStringResource { LocalizedStringResource("qibla.permission_unknown", defaultValue: "Something went wrong while finding your location.", table: "Localizable", locale: LocalizationManager.locale) }

        static var directionNorth: LocalizedStringResource { LocalizedStringResource("qibla.direction.n", defaultValue: "N", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionNNE: LocalizedStringResource { LocalizedStringResource("qibla.direction.nne", defaultValue: "NNE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionNE: LocalizedStringResource { LocalizedStringResource("qibla.direction.ne", defaultValue: "NE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionENE: LocalizedStringResource { LocalizedStringResource("qibla.direction.ene", defaultValue: "ENE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionEast: LocalizedStringResource { LocalizedStringResource("qibla.direction.e", defaultValue: "E", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionESE: LocalizedStringResource { LocalizedStringResource("qibla.direction.ese", defaultValue: "ESE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionSE: LocalizedStringResource { LocalizedStringResource("qibla.direction.se", defaultValue: "SE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionSSE: LocalizedStringResource { LocalizedStringResource("qibla.direction.sse", defaultValue: "SSE", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionSouth: LocalizedStringResource { LocalizedStringResource("qibla.direction.s", defaultValue: "S", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionSSW: LocalizedStringResource { LocalizedStringResource("qibla.direction.ssw", defaultValue: "SSW", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionSW: LocalizedStringResource { LocalizedStringResource("qibla.direction.sw", defaultValue: "SW", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionWSW: LocalizedStringResource { LocalizedStringResource("qibla.direction.wsw", defaultValue: "WSW", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionWest: LocalizedStringResource { LocalizedStringResource("qibla.direction.w", defaultValue: "W", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionWNW: LocalizedStringResource { LocalizedStringResource("qibla.direction.wnw", defaultValue: "WNW", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionNW: LocalizedStringResource { LocalizedStringResource("qibla.direction.nw", defaultValue: "NW", table: "Localizable", locale: LocalizationManager.locale) }
        static var directionNNW: LocalizedStringResource { LocalizedStringResource("qibla.direction.nnw", defaultValue: "NNW", table: "Localizable", locale: LocalizationManager.locale) }
    }

    enum Quran {
        static var noFavorites: LocalizedStringResource { LocalizedStringResource("quran.no_favorites", defaultValue: "Tap the star beside a surah or ayah to save it here.", table: "Localizable", locale: LocalizationManager.locale) }
        static var favoriteAyahs: LocalizedStringResource { LocalizedStringResource("quran.favorite_ayahs", defaultValue: "Favorite Ayahs", table: "Localizable", locale: LocalizationManager.locale) }
        static var favoriteSurahs: LocalizedStringResource { LocalizedStringResource("quran.favorite_surahs", defaultValue: "Favorite Surahs", table: "Localizable", locale: LocalizationManager.locale) }
        static var removeFavorite: LocalizedStringResource { LocalizedStringResource("quran.remove_favorite", defaultValue: "Remove from favorites", table: "Localizable", locale: LocalizationManager.locale) }
        static var addFavorite: LocalizedStringResource { LocalizedStringResource("quran.add_favorite", defaultValue: "Add to favorites", table: "Localizable", locale: LocalizationManager.locale) }
        static var continueReading: LocalizedStringResource { LocalizedStringResource("quran.continue_reading", defaultValue: "Continue reading", table: "Localizable", locale: LocalizationManager.locale) }
        static var progressSaved: LocalizedStringResource { LocalizedStringResource("quran.progress_saved", defaultValue: "Reading progress saved automatically", table: "Localizable", locale: LocalizationManager.locale) }
        static var tabTitle: LocalizedStringResource { LocalizedStringResource("quran.tab_title", defaultValue: "Quran", table: "Localizable", locale: LocalizationManager.locale) }
        static var ayahOfTheDay: LocalizedStringResource { LocalizedStringResource("quran.ayah_of_the_day", defaultValue: "Ayah of the Day", table: "Localizable", locale: LocalizationManager.locale) }
        static var openInReader: LocalizedStringResource { LocalizedStringResource("quran.open_in_reader", defaultValue: "Open in Reader", table: "Localizable", locale: LocalizationManager.locale) }
        static var openFullReader: LocalizedStringResource { LocalizedStringResource("quran.open_full_reader", defaultValue: "Open Full Reader", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectSurah: LocalizedStringResource { LocalizedStringResource("quran.select_surah", defaultValue: "Select Surah", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectAyah: LocalizedStringResource { LocalizedStringResource("quran.select_ayah", defaultValue: "Select Ayah", table: "Localizable", locale: LocalizationManager.locale) }
        static var chooseSurah: LocalizedStringResource { LocalizedStringResource("quran.choose_surah", defaultValue: "Choose Surah", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectSurahToStartReading: LocalizedStringResource { LocalizedStringResource("quran.select_surah_prompt", defaultValue: "Select a Surah to start reading", table: "Localizable", locale: LocalizationManager.locale) }
        static var searchSurah: LocalizedStringResource { LocalizedStringResource("quran.search_surah", defaultValue: "Search Surah", table: "Localizable", locale: LocalizationManager.locale) }
        static var allSurahs: LocalizedStringResource { LocalizedStringResource("quran.all_surahs", defaultValue: "All Surahs", table: "Localizable", locale: LocalizationManager.locale) }
        static var results: LocalizedStringResource { LocalizedStringResource("quran.results", defaultValue: "Results", table: "Localizable", locale: LocalizationManager.locale) }
        static var translation: LocalizedStringResource { LocalizedStringResource("quran.translation", defaultValue: "Translation", table: "Localizable", locale: LocalizationManager.locale) }
        static var readingSettings: LocalizedStringResource { LocalizedStringResource("quran.reading_settings", defaultValue: "Reading Settings", table: "Localizable", locale: LocalizationManager.locale) }
        static var readingModeSection: LocalizedStringResource { LocalizedStringResource("quran.reading_mode_section", defaultValue: "Reading Mode", table: "Localizable", locale: LocalizationManager.locale) }
        static var arabicOnly: LocalizedStringResource { LocalizedStringResource("quran.arabic_only", defaultValue: "Arabic Only", table: "Localizable", locale: LocalizationManager.locale) }
        static var arabicWithTranslation: LocalizedStringResource { LocalizedStringResource("quran.arabic_with_translation", defaultValue: "Arabic + Translation", table: "Localizable", locale: LocalizationManager.locale) }
        static var fontSize: LocalizedStringResource { LocalizedStringResource("quran.font_size", defaultValue: "Font Size", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorLoadFailed: LocalizedStringResource { LocalizedStringResource("quran.error_load_failed", defaultValue: "We couldn't load the Quran content. Please try again.", table: "Localizable", locale: LocalizationManager.locale) }
        static var errorSurahLoadFailed: LocalizedStringResource { LocalizedStringResource("quran.error_surah_load_failed", defaultValue: "We couldn't load this surah. Please try again.", table: "Localizable", locale: LocalizationManager.locale) }

        static func ayahNumber(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource("quran.ayah_number_format", defaultValue: "Ayah \(number)", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func quranReference(surah: Int, ayah: Int) -> LocalizedStringResource {
            LocalizedStringResource("quran.reference_format", defaultValue: "Quran \(surah):\(ayah)", table: "Localizable", locale: LocalizationManager.locale)
        }

        static var dailyNotificationBody: LocalizedStringResource { LocalizedStringResource("quran.daily_notification_body", defaultValue: "Your daily Quran ayah is ready to read.", table: "Localizable", locale: LocalizationManager.locale) }
    }

    enum Settings {
        static var sunriseReminderInfo: LocalizedStringResource { LocalizedStringResource("settings.sunrise_reminder_info", defaultValue: "Sunrise has its own optional reminder. Open the app regularly to refresh the seven-day reminder schedule.", table: "Localizable", locale: LocalizationManager.locale) }
        static var dataSources: LocalizedStringResource { LocalizedStringResource("settings.data_sources", defaultValue: "Data sources", table: "Localizable", locale: LocalizationManager.locale) }
        static var creditAladhan: LocalizedStringResource { LocalizedStringResource("settings.credit_aladhan", defaultValue: "Prayer times and sunrise • AlAdhan", table: "Localizable", locale: LocalizationManager.locale) }
        static var creditMinber: LocalizedStringResource { LocalizedStringResource("settings.credit_minber", defaultValue: "QMİ timetable and sunrise • Minber.az", table: "Localizable", locale: LocalizationManager.locale) }
        static var creditAdhan: LocalizedStringResource { LocalizedStringResource("settings.credit_adhan", defaultValue: "On-device calculations • Adhan Swift", table: "Localizable", locale: LocalizationManager.locale) }
        static var minberSourceNote: LocalizedStringResource { LocalizedStringResource("settings.minber_source_note", defaultValue: "Minber.az is a third-party source for QMİ-based city timetables.", table: "Localizable", locale: LocalizationManager.locale) }
        static var sunriseAbout: LocalizedStringResource { LocalizedStringResource("settings.sunrise_about", defaultValue: "Sunrise appears between Fajr and Dhuhr and has an optional reminder. The next-prayer countdown follows the five daily prayers.", table: "Localizable", locale: LocalizationManager.locale) }
        static var language: LocalizedStringResource {
            LocalizedStringResource("settings.language", defaultValue: "Language", table: "Localizable", locale: LocalizationManager.locale)
        }
        static var languageSystem: LocalizedStringResource {
            LocalizedStringResource("settings.language_system", defaultValue: "Follow iOS Settings", table: "Localizable", locale: LocalizationManager.locale)
        }

        static func notificationsScheduled(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("settings.notifications_scheduled", defaultValue: "\(count) reminders scheduled", table: "Localizable", locale: LocalizationManager.locale)
        }
        static var testNotificationScheduled: LocalizedStringResource { LocalizedStringResource("settings.test_notification_scheduled", defaultValue: "Test notification scheduled. It will appear in 5 seconds.", table: "Localizable", locale: LocalizationManager.locale) }
        static var notificationFailed: LocalizedStringResource { LocalizedStringResource("settings.notification_failed", defaultValue: "Could not schedule the notification. Please try again.", table: "Localizable", locale: LocalizationManager.locale) }
        static var notificationPermissionNeeded: LocalizedStringResource { LocalizedStringResource("settings.notification_permission_needed", defaultValue: "Allow notifications in iPhone Settings to receive reminders.", table: "Localizable", locale: LocalizationManager.locale) }
        static var tabTitle: LocalizedStringResource { LocalizedStringResource("settings.tab_title", defaultValue: "Settings", table: "Localizable", locale: LocalizationManager.locale) }
        static var locationSection: LocalizedStringResource { LocalizedStringResource("settings.location_section", defaultValue: "Location", table: "Localizable", locale: LocalizationManager.locale) }
        static var locationModeLabel: LocalizedStringResource { LocalizedStringResource("settings.location_mode_label", defaultValue: "Location Mode", table: "Localizable", locale: LocalizationManager.locale) }
        static var locationModeAutomatic: LocalizedStringResource { LocalizedStringResource("settings.location_automatic", defaultValue: "Automatic", table: "Localizable", locale: LocalizationManager.locale) }
        static var locationModeManual: LocalizedStringResource { LocalizedStringResource("settings.location_manual", defaultValue: "Manual", table: "Localizable", locale: LocalizationManager.locale) }
        static var currentCity: LocalizedStringResource { LocalizedStringResource("settings.current_city", defaultValue: "Current City", table: "Localizable", locale: LocalizationManager.locale) }
        static var selectedCity: LocalizedStringResource { LocalizedStringResource("settings.selected_city", defaultValue: "Selected City", table: "Localizable", locale: LocalizationManager.locale) }
        static var detecting: LocalizedStringResource { LocalizedStringResource("settings.detecting", defaultValue: "Detecting…", table: "Localizable", locale: LocalizationManager.locale) }
        static var none: LocalizedStringResource { LocalizedStringResource("settings.none", defaultValue: "None", table: "Localizable", locale: LocalizationManager.locale) }
        static var prayerSettingsSection: LocalizedStringResource { LocalizedStringResource("settings.prayer_settings_section", defaultValue: "Prayer Settings", table: "Localizable", locale: LocalizationManager.locale) }
        static var calculationMadhab: LocalizedStringResource { LocalizedStringResource("settings.calculation_madhab", defaultValue: "Calculation & Madhab", table: "Localizable", locale: LocalizationManager.locale) }
        static var manualAdjustments: LocalizedStringResource { LocalizedStringResource("settings.manual_adjustments", defaultValue: "Manual Adjustments", table: "Localizable", locale: LocalizationManager.locale) }
        static var prayerNotificationsSection: LocalizedStringResource { LocalizedStringResource("settings.prayer_notifications_section", defaultValue: "Prayer & Sunrise Notifications", table: "Localizable", locale: LocalizationManager.locale) }
        static var quranNotificationsSection: LocalizedStringResource { LocalizedStringResource("settings.quran_notifications_section", defaultValue: "Quran Notifications", table: "Localizable", locale: LocalizationManager.locale) }
        static var dailyAyahReminder: LocalizedStringResource { LocalizedStringResource("settings.daily_ayah_reminder", defaultValue: "Daily Ayah Reminder", table: "Localizable", locale: LocalizationManager.locale) }
        static var soundSection: LocalizedStringResource { LocalizedStringResource("settings.sound_section", defaultValue: "Sound", table: "Localizable", locale: LocalizationManager.locale) }
        static var defaultSound: LocalizedStringResource { LocalizedStringResource("settings.default_sound", defaultValue: "Default", table: "Localizable", locale: LocalizationManager.locale) }
        static var preview: LocalizedStringResource { LocalizedStringResource("settings.preview", defaultValue: "Preview", table: "Localizable", locale: LocalizationManager.locale) }
        static var sendTestNotification: LocalizedStringResource { LocalizedStringResource("settings.send_test_notification", defaultValue: "Send Test Notification", table: "Localizable", locale: LocalizationManager.locale) }
        static var testNotificationTitle: LocalizedStringResource { LocalizedStringResource("settings.test_notification_title", defaultValue: "Test Notification", table: "Localizable", locale: LocalizationManager.locale) }
        static var testNotificationBody: LocalizedStringResource { LocalizedStringResource("settings.test_notification_body", defaultValue: "This is what your prayer reminders will look like.", table: "Localizable", locale: LocalizationManager.locale) }
        static var appearanceSection: LocalizedStringResource { LocalizedStringResource("settings.appearance_section", defaultValue: "Appearance", table: "Localizable", locale: LocalizationManager.locale) }
        static var appearanceSystem: LocalizedStringResource { LocalizedStringResource("settings.appearance_system", defaultValue: "System", table: "Localizable", locale: LocalizationManager.locale) }
        static var appearanceLight: LocalizedStringResource { LocalizedStringResource("settings.appearance_light", defaultValue: "Light", table: "Localizable", locale: LocalizationManager.locale) }
        static var appearanceDark: LocalizedStringResource { LocalizedStringResource("settings.appearance_dark", defaultValue: "Dark", table: "Localizable", locale: LocalizationManager.locale) }
        static var informationSection: LocalizedStringResource { LocalizedStringResource("settings.information_section", defaultValue: "Information", table: "Localizable", locale: LocalizationManager.locale) }
        static var aboutUs: LocalizedStringResource { LocalizedStringResource("settings.about_us", defaultValue: "About Us", table: "Localizable", locale: LocalizationManager.locale) }
        static var version: LocalizedStringResource { LocalizedStringResource("settings.version", defaultValue: "Version", table: "Localizable", locale: LocalizationManager.locale) }
        static var enableNotificationsInSettings: LocalizedStringResource { LocalizedStringResource("settings.enable_notifications", defaultValue: "Enable Notifications in Settings", table: "Localizable", locale: LocalizationManager.locale) }
        static var allowNotifications: LocalizedStringResource { LocalizedStringResource("settings.allow_notifications", defaultValue: "Allow Notifications", table: "Localizable", locale: LocalizationManager.locale) }
        static var calculationMethodSection: LocalizedStringResource { LocalizedStringResource("settings.calculation_method_section", defaultValue: "Calculation Method", table: "Localizable", locale: LocalizationManager.locale) }
        static var asrMadhabSection: LocalizedStringResource { LocalizedStringResource("settings.asr_madhab_section", defaultValue: "Asr Madhab", table: "Localizable", locale: LocalizationManager.locale) }
        static var madhabStandard: LocalizedStringResource { LocalizedStringResource("settings.madhab_standard", defaultValue: "Standard (Shafi, Maliki, Hanbali)", table: "Localizable", locale: LocalizationManager.locale) }
        static var madhabHanafi: LocalizedStringResource { LocalizedStringResource("settings.madhab_hanafi", defaultValue: "Hanafi", table: "Localizable", locale: LocalizationManager.locale) }
        static var adjustmentsFooter: LocalizedStringResource { LocalizedStringResource("settings.adjustments_footer", defaultValue: "Fine-tune each prayer time in minutes if it doesn't match your local mosque or preference.", table: "Localizable", locale: LocalizationManager.locale) }
        static var aboutUsAppName: LocalizedStringResource { LocalizedStringResource("settings.about_app_name", defaultValue: "Islamic Companion", table: "Localizable", locale: LocalizationManager.locale) }
        static var aboutUsBody: LocalizedStringResource { LocalizedStringResource("settings.about_body", defaultValue: "This app provides prayer times, Qibla direction, and the Holy Quran to support your daily worship.", table: "Localizable", locale: LocalizationManager.locale) }
        static var aboutSection: LocalizedStringResource { LocalizedStringResource("settings.about_section", defaultValue: "About", table: "Localizable", locale: LocalizationManager.locale) }

        static func versionLabel(_ version: String) -> LocalizedStringResource {
            LocalizedStringResource("settings.version_format", defaultValue: "Version \(version)", table: "Localizable", locale: LocalizationManager.locale)
        }

        /// Takes the already sign-formatted value ("+5", "0", "-3") — the
        /// +/- prefix is numeric formatting, not translation, so it stays in
        /// Swift (PrayerAdjustmentsView); this key only localizes the unit.
        static func minutesOffset(_ formattedValue: String) -> LocalizedStringResource {
            LocalizedStringResource("settings.minutes_offset_format", defaultValue: "\(formattedValue) min", table: "Localizable", locale: LocalizationManager.locale)
        }

        static var minberExplanation: LocalizedStringResource { LocalizedStringResource("settings.minber_explanation", defaultValue: "Uses the selected Azerbaijani city’s published QMİ timetable via Minber.az. Madhab selection does not change this fixed timetable. Your madhab preference is kept for other methods.", table: "Localizable", locale: LocalizationManager.locale) }
        static var minberUnavailable: LocalizedStringResource { LocalizedStringResource("prayer_times.minber_unavailable", defaultValue: "No Minber timetable is available for this city or date. Choose a supported Azerbaijani city, or select another calculation method.", table: "Localizable", locale: LocalizationManager.locale) }
        static func calculationMethodName(_ method: PrayerCalculationMethod) -> LocalizedStringResource {
            switch method {
            case .muslimWorldLeague: return LocalizedStringResource("calc_method.muslim_world_league", defaultValue: "Muslim World League", table: "Localizable", locale: LocalizationManager.locale)
            case .egyptianGeneralAuthority: return LocalizedStringResource("calc_method.egyptian", defaultValue: "Egyptian General Authority", table: "Localizable", locale: LocalizationManager.locale)
            case .karachi: return LocalizedStringResource("calc_method.karachi", defaultValue: "University of Islamic Sciences, Karachi", table: "Localizable", locale: LocalizationManager.locale)
            case .ummAlQura: return LocalizedStringResource("calc_method.umm_al_qura", defaultValue: "Umm Al-Qura University, Makkah", table: "Localizable", locale: LocalizationManager.locale)
            case .dubai: return LocalizedStringResource("calc_method.dubai", defaultValue: "Dubai", table: "Localizable", locale: LocalizationManager.locale)
            case .moonsightingCommittee: return LocalizedStringResource("calc_method.moonsighting", defaultValue: "Moonsighting Committee", table: "Localizable", locale: LocalizationManager.locale)
            case .northAmerica: return LocalizedStringResource("calc_method.isna", defaultValue: "Islamic Society of North America", table: "Localizable", locale: LocalizationManager.locale)
            case .kuwait: return LocalizedStringResource("calc_method.kuwait", defaultValue: "Kuwait", table: "Localizable", locale: LocalizationManager.locale)
            case .qatar: return LocalizedStringResource("calc_method.qatar", defaultValue: "Qatar", table: "Localizable", locale: LocalizationManager.locale)
            case .singapore: return LocalizedStringResource("calc_method.singapore", defaultValue: "Singapore", table: "Localizable", locale: LocalizationManager.locale)
            case .tehran: return LocalizedStringResource("calc_method.tehran", defaultValue: "Tehran", table: "Localizable", locale: LocalizationManager.locale)
            case .qmiMinber: return LocalizedStringResource("calc_method.qmi_minber", defaultValue: "Qafqaz Müsəlmanları İdarəsi (Minber)", table: "Localizable", locale: LocalizationManager.locale)
            case .turkey: return LocalizedStringResource("calc_method.turkey", defaultValue: "Turkey (Diyanet)", table: "Localizable", locale: LocalizationManager.locale)
            }
        }
    }
}
