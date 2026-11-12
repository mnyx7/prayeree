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
        static let copied = LocalizedStringResource("common.copied", defaultValue: "Copied", table: "Localizable")
        static let copy = LocalizedStringResource("common.copy", defaultValue: "Copy", table: "Localizable")
        static let addCity = LocalizedStringResource("common.add_city", defaultValue: "Add city", table: "Localizable")
        static let search = LocalizedStringResource("common.search", defaultValue: "Search", table: "Localizable")
        static let cancel = LocalizedStringResource("common.cancel", defaultValue: "Cancel", table: "Localizable")
        static let done = LocalizedStringResource("common.done", defaultValue: "Done", table: "Localizable")
        static let tryAgain = LocalizedStringResource("common.try_again", defaultValue: "Try Again", table: "Localizable")
        static let retry = LocalizedStringResource("common.retry", defaultValue: "Retry", table: "Localizable")
        static let recent = LocalizedStringResource("common.recent", defaultValue: "Recent", table: "Localizable")
        static let favorites = LocalizedStringResource("common.favorites", defaultValue: "Favorites", table: "Localizable")
        static let noCitiesFound = LocalizedStringResource("common.no_cities_found", defaultValue: "No cities found", table: "Localizable")
        static let useCurrentLocation = LocalizedStringResource("common.use_current_location", defaultValue: "Use Current Location", table: "Localizable")
        static let selectCity = LocalizedStringResource("common.select_city", defaultValue: "Select City", table: "Localizable")
        static let showingCachedData = LocalizedStringResource("common.showing_cached_data", defaultValue: "Showing cached data", table: "Localizable")

        static func lastUpdated(_ time: String) -> LocalizedStringResource {
            LocalizedStringResource("common.last_updated_format", defaultValue: "Last updated at \(time)", table: "Localizable")
        }

        static func genericLoadError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_generic", defaultValue: "Something went wrong. Please try again.", table: "Localizable")
        }

        static func networkLoadError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_network", defaultValue: "Check your internet connection and try again.", table: "Localizable")
        }

        static func serviceUnavailableError() -> LocalizedStringResource {
            LocalizedStringResource("common.error_service_unavailable", defaultValue: "The service is unavailable right now.", table: "Localizable")
        }
    }

    enum PrayerName {
        static func displayName(for prayer: IslamicApp.PrayerName) -> LocalizedStringResource {
            switch prayer {
            case .fajr: return LocalizedStringResource("prayer_name.fajr", defaultValue: "Fajr", table: "Localizable")
            case .dhuhr: return LocalizedStringResource("prayer_name.dhuhr", defaultValue: "Dhuhr", table: "Localizable")
            case .asr: return LocalizedStringResource("prayer_name.asr", defaultValue: "Asr", table: "Localizable")
            case .maghrib: return LocalizedStringResource("prayer_name.maghrib", defaultValue: "Maghrib", table: "Localizable")
            case .isha: return LocalizedStringResource("prayer_name.isha", defaultValue: "Isha", table: "Localizable")
            }
        }
    }

    enum HijriMonthName {
        static func displayName(for month: IslamicApp.HijriMonth) -> LocalizedStringResource {
            switch month {
            case .muharram: return LocalizedStringResource("hijri_month.muharram", defaultValue: "Muharram", table: "Localizable")
            case .safar: return LocalizedStringResource("hijri_month.safar", defaultValue: "Safar", table: "Localizable")
            case .rabiAlAwwal: return LocalizedStringResource("hijri_month.rabi_al_awwal", defaultValue: "Rabi' al-Awwal", table: "Localizable")
            case .rabiAlThani: return LocalizedStringResource("hijri_month.rabi_al_thani", defaultValue: "Rabi' al-Thani", table: "Localizable")
            case .jumadaAlAwwal: return LocalizedStringResource("hijri_month.jumada_al_awwal", defaultValue: "Jumada al-Awwal", table: "Localizable")
            case .jumadaAlThani: return LocalizedStringResource("hijri_month.jumada_al_thani", defaultValue: "Jumada al-Thani", table: "Localizable")
            case .rajab: return LocalizedStringResource("hijri_month.rajab", defaultValue: "Rajab", table: "Localizable")
            case .shaban: return LocalizedStringResource("hijri_month.shaban", defaultValue: "Sha'ban", table: "Localizable")
            case .ramadan: return LocalizedStringResource("hijri_month.ramadan", defaultValue: "Ramadan", table: "Localizable")
            case .shawwal: return LocalizedStringResource("hijri_month.shawwal", defaultValue: "Shawwal", table: "Localizable")
            case .dhulQadah: return LocalizedStringResource("hijri_month.dhul_qadah", defaultValue: "Dhu al-Qi'dah", table: "Localizable")
            case .dhulHijjah: return LocalizedStringResource("hijri_month.dhul_hijjah", defaultValue: "Dhu al-Hijjah", table: "Localizable")
            }
        }
    }

    enum PrayerTimes {
        static let calculatedLocally = LocalizedStringResource("prayer_times.calculated_locally", defaultValue: "Calculated on your device using your prayer settings", table: "Localizable")
        static let tabTitle = LocalizedStringResource("prayer_times.tab_title", defaultValue: "Prayer Times", table: "Localizable")
        static let allPrayersComplete = LocalizedStringResource("prayer_times.all_complete", defaultValue: "All prayers for today are complete", table: "Localizable")
        static let selectDate = LocalizedStringResource("prayer_times.select_date", defaultValue: "Select Date", table: "Localizable")
        static let selectLocationPrompt = LocalizedStringResource("prayer_times.select_location_prompt", defaultValue: "Select a location to see prayer times", table: "Localizable")
        static let chooseCity = LocalizedStringResource("prayer_times.choose_city", defaultValue: "Choose City", table: "Localizable")
        static let searchForCity = LocalizedStringResource("prayer_times.search_city", defaultValue: "Search for a city", table: "Localizable")
        static let browseByCountry = LocalizedStringResource("prayer_times.browse_by_country", defaultValue: "Browse by Country", table: "Localizable")
        static let favoriteCitiesTitle = LocalizedStringResource("prayer_times.favorite_cities_title", defaultValue: "Favorite Cities", table: "Localizable")
        static let noFavoriteCities = LocalizedStringResource("prayer_times.no_favorite_cities", defaultValue: "No favorite cities yet. Tap + to find and save a city.", table: "Localizable")
        static let errorLoadFailed = LocalizedStringResource("prayer_times.error_load_failed", defaultValue: "We couldn't load prayer times. Please try again.", table: "Localizable")
        static let errorLocationDenied = LocalizedStringResource("prayer_times.error_location_denied", defaultValue: "Location access is denied. Enable it in Settings or choose a city manually.", table: "Localizable")
        static let errorLocationRestricted = LocalizedStringResource("prayer_times.error_location_restricted", defaultValue: "Location access is restricted on this device. Choose a city manually.", table: "Localizable")
        static let errorLocationUnavailable = LocalizedStringResource("prayer_times.error_location_unavailable", defaultValue: "We couldn't determine your location. Try again or choose a city manually.", table: "Localizable")

        static func searchingIn(_ country: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.searching_in_format", defaultValue: "Searching in \(country)", table: "Localizable")
        }

        static func nextPrayerCountdown(prayer: String, countdown: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.next_prayer_format", defaultValue: "Next prayer: \(prayer) in \(countdown)", table: "Localizable")
        }

        static func notificationTitle(prayer: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.notification_title_format", defaultValue: "\(prayer) Prayer", table: "Localizable")
        }

        static func notificationBody(prayer: String) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.notification_body_format", defaultValue: "It's time for \(prayer) prayer.", table: "Localizable")
        }

        /// The "day month, year AH" structure itself is language-dependent
        /// (word order, punctuation), not just the month name — this is a
        /// distinct key from HijriMonthName so both can vary independently.
        static func hijriDateLabel(day: Int, month: String, year: Int) -> LocalizedStringResource {
            LocalizedStringResource("prayer_times.hijri_date_format", defaultValue: "\(day) \(month), \(year) AH", table: "Localizable")
        }
    }

    enum Qibla {
        static let tabTitle = LocalizedStringResource("qibla.tab_title", defaultValue: "Qibla", table: "Localizable")
        static let kaaba = LocalizedStringResource("qibla.kaaba", defaultValue: "Kaaba", table: "Localizable")
        static let liveCompassUnavailable = LocalizedStringResource("qibla.live_compass_unavailable", defaultValue: "Live compass unavailable — showing the calculated direction from true north.", table: "Localizable")
        static let calibrationTitle = LocalizedStringResource("qibla.calibration_title", defaultValue: "Move your phone in a figure-8 if the direction seems incorrect.", table: "Localizable")
        static let calibrationSubtitle = LocalizedStringResource("qibla.calibration_subtitle", defaultValue: "Magnetic interference near metal objects or electronics can affect accuracy.", table: "Localizable")
        static let allowLocationAccess = LocalizedStringResource("qibla.allow_location_access", defaultValue: "Allow Location Access", table: "Localizable")
        static let permissionPromptNotDetermined = LocalizedStringResource("qibla.permission_not_determined", defaultValue: "Allow location access to find the Qibla direction from where you are.", table: "Localizable")
        static let permissionPromptDenied = LocalizedStringResource("qibla.permission_denied", defaultValue: "Location access is denied. Enable it in Settings to use the Qibla compass.", table: "Localizable")
        static let permissionPromptRestricted = LocalizedStringResource("qibla.permission_restricted", defaultValue: "Location access is restricted on this device.", table: "Localizable")
        static let permissionPromptUnknown = LocalizedStringResource("qibla.permission_unknown", defaultValue: "Something went wrong while finding your location.", table: "Localizable")

        static let directionNorth = LocalizedStringResource("qibla.direction.n", defaultValue: "N", table: "Localizable")
        static let directionNNE = LocalizedStringResource("qibla.direction.nne", defaultValue: "NNE", table: "Localizable")
        static let directionNE = LocalizedStringResource("qibla.direction.ne", defaultValue: "NE", table: "Localizable")
        static let directionENE = LocalizedStringResource("qibla.direction.ene", defaultValue: "ENE", table: "Localizable")
        static let directionEast = LocalizedStringResource("qibla.direction.e", defaultValue: "E", table: "Localizable")
        static let directionESE = LocalizedStringResource("qibla.direction.ese", defaultValue: "ESE", table: "Localizable")
        static let directionSE = LocalizedStringResource("qibla.direction.se", defaultValue: "SE", table: "Localizable")
        static let directionSSE = LocalizedStringResource("qibla.direction.sse", defaultValue: "SSE", table: "Localizable")
        static let directionSouth = LocalizedStringResource("qibla.direction.s", defaultValue: "S", table: "Localizable")
        static let directionSSW = LocalizedStringResource("qibla.direction.ssw", defaultValue: "SSW", table: "Localizable")
        static let directionSW = LocalizedStringResource("qibla.direction.sw", defaultValue: "SW", table: "Localizable")
        static let directionWSW = LocalizedStringResource("qibla.direction.wsw", defaultValue: "WSW", table: "Localizable")
        static let directionWest = LocalizedStringResource("qibla.direction.w", defaultValue: "W", table: "Localizable")
        static let directionWNW = LocalizedStringResource("qibla.direction.wnw", defaultValue: "WNW", table: "Localizable")
        static let directionNW = LocalizedStringResource("qibla.direction.nw", defaultValue: "NW", table: "Localizable")
        static let directionNNW = LocalizedStringResource("qibla.direction.nnw", defaultValue: "NNW", table: "Localizable")
    }

    enum Quran {
        static let tabTitle = LocalizedStringResource("quran.tab_title", defaultValue: "Quran", table: "Localizable")
        static let ayahOfTheDay = LocalizedStringResource("quran.ayah_of_the_day", defaultValue: "Ayah of the Day", table: "Localizable")
        static let openInReader = LocalizedStringResource("quran.open_in_reader", defaultValue: "Open in Reader", table: "Localizable")
        static let openFullReader = LocalizedStringResource("quran.open_full_reader", defaultValue: "Open Full Reader", table: "Localizable")
        static let selectSurah = LocalizedStringResource("quran.select_surah", defaultValue: "Select Surah", table: "Localizable")
        static let selectAyah = LocalizedStringResource("quran.select_ayah", defaultValue: "Select Ayah", table: "Localizable")
        static let chooseSurah = LocalizedStringResource("quran.choose_surah", defaultValue: "Choose Surah", table: "Localizable")
        static let selectSurahToStartReading = LocalizedStringResource("quran.select_surah_prompt", defaultValue: "Select a Surah to start reading", table: "Localizable")
        static let searchSurah = LocalizedStringResource("quran.search_surah", defaultValue: "Search Surah", table: "Localizable")
        static let allSurahs = LocalizedStringResource("quran.all_surahs", defaultValue: "All Surahs", table: "Localizable")
        static let results = LocalizedStringResource("quran.results", defaultValue: "Results", table: "Localizable")
        static let translation = LocalizedStringResource("quran.translation", defaultValue: "Translation", table: "Localizable")
        static let readingSettings = LocalizedStringResource("quran.reading_settings", defaultValue: "Reading Settings", table: "Localizable")
        static let readingModeSection = LocalizedStringResource("quran.reading_mode_section", defaultValue: "Reading Mode", table: "Localizable")
        static let arabicOnly = LocalizedStringResource("quran.arabic_only", defaultValue: "Arabic Only", table: "Localizable")
        static let arabicWithTranslation = LocalizedStringResource("quran.arabic_with_translation", defaultValue: "Arabic + Translation", table: "Localizable")
        static let fontSize = LocalizedStringResource("quran.font_size", defaultValue: "Font Size", table: "Localizable")
        static let errorLoadFailed = LocalizedStringResource("quran.error_load_failed", defaultValue: "We couldn't load the Quran content. Please try again.", table: "Localizable")
        static let errorSurahLoadFailed = LocalizedStringResource("quran.error_surah_load_failed", defaultValue: "We couldn't load this surah. Please try again.", table: "Localizable")

        static func ayahNumber(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource("quran.ayah_number_format", defaultValue: "Ayah \(number)", table: "Localizable")
        }

        static func quranReference(surah: Int, ayah: Int) -> LocalizedStringResource {
            LocalizedStringResource("quran.reference_format", defaultValue: "Quran \(surah):\(ayah)", table: "Localizable")
        }

        static let dailyNotificationBody = LocalizedStringResource("quran.daily_notification_body", defaultValue: "Your daily Quran ayah is ready to read.", table: "Localizable")
    }

    enum Settings {
        static func notificationsScheduled(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource("settings.notifications_scheduled", defaultValue: "\(count) reminders scheduled", table: "Localizable")
        }
        static let testNotificationScheduled = LocalizedStringResource("settings.test_notification_scheduled", defaultValue: "Test notification scheduled. It will appear in 5 seconds.", table: "Localizable")
        static let notificationFailed = LocalizedStringResource("settings.notification_failed", defaultValue: "Could not schedule the notification. Please try again.", table: "Localizable")
        static let notificationPermissionNeeded = LocalizedStringResource("settings.notification_permission_needed", defaultValue: "Allow notifications in iPhone Settings to receive reminders.", table: "Localizable")
        static let tabTitle = LocalizedStringResource("settings.tab_title", defaultValue: "Settings", table: "Localizable")
        static let locationSection = LocalizedStringResource("settings.location_section", defaultValue: "Location", table: "Localizable")
        static let locationModeLabel = LocalizedStringResource("settings.location_mode_label", defaultValue: "Location Mode", table: "Localizable")
        static let locationModeAutomatic = LocalizedStringResource("settings.location_automatic", defaultValue: "Automatic", table: "Localizable")
        static let locationModeManual = LocalizedStringResource("settings.location_manual", defaultValue: "Manual", table: "Localizable")
        static let currentCity = LocalizedStringResource("settings.current_city", defaultValue: "Current City", table: "Localizable")
        static let selectedCity = LocalizedStringResource("settings.selected_city", defaultValue: "Selected City", table: "Localizable")
        static let detecting = LocalizedStringResource("settings.detecting", defaultValue: "Detecting…", table: "Localizable")
        static let none = LocalizedStringResource("settings.none", defaultValue: "None", table: "Localizable")
        static let prayerSettingsSection = LocalizedStringResource("settings.prayer_settings_section", defaultValue: "Prayer Settings", table: "Localizable")
        static let calculationMadhab = LocalizedStringResource("settings.calculation_madhab", defaultValue: "Calculation & Madhab", table: "Localizable")
        static let manualAdjustments = LocalizedStringResource("settings.manual_adjustments", defaultValue: "Manual Adjustments", table: "Localizable")
        static let prayerNotificationsSection = LocalizedStringResource("settings.prayer_notifications_section", defaultValue: "Prayer Notifications", table: "Localizable")
        static let quranNotificationsSection = LocalizedStringResource("settings.quran_notifications_section", defaultValue: "Quran Notifications", table: "Localizable")
        static let dailyAyahReminder = LocalizedStringResource("settings.daily_ayah_reminder", defaultValue: "Daily Ayah Reminder", table: "Localizable")
        static let soundSection = LocalizedStringResource("settings.sound_section", defaultValue: "Sound", table: "Localizable")
        static let defaultSound = LocalizedStringResource("settings.default_sound", defaultValue: "Default", table: "Localizable")
        static let preview = LocalizedStringResource("settings.preview", defaultValue: "Preview", table: "Localizable")
        static let sendTestNotification = LocalizedStringResource("settings.send_test_notification", defaultValue: "Send Test Notification", table: "Localizable")
        static let testNotificationTitle = LocalizedStringResource("settings.test_notification_title", defaultValue: "Test Notification", table: "Localizable")
        static let testNotificationBody = LocalizedStringResource("settings.test_notification_body", defaultValue: "This is what your prayer reminders will look like.", table: "Localizable")
        static let appearanceSection = LocalizedStringResource("settings.appearance_section", defaultValue: "Appearance", table: "Localizable")
        static let appearanceSystem = LocalizedStringResource("settings.appearance_system", defaultValue: "System", table: "Localizable")
        static let appearanceLight = LocalizedStringResource("settings.appearance_light", defaultValue: "Light", table: "Localizable")
        static let appearanceDark = LocalizedStringResource("settings.appearance_dark", defaultValue: "Dark", table: "Localizable")
        static let informationSection = LocalizedStringResource("settings.information_section", defaultValue: "Information", table: "Localizable")
        static let aboutUs = LocalizedStringResource("settings.about_us", defaultValue: "About Us", table: "Localizable")
        static let version = LocalizedStringResource("settings.version", defaultValue: "Version", table: "Localizable")
        static let enableNotificationsInSettings = LocalizedStringResource("settings.enable_notifications", defaultValue: "Enable Notifications in Settings", table: "Localizable")
        static let allowNotifications = LocalizedStringResource("settings.allow_notifications", defaultValue: "Allow Notifications", table: "Localizable")
        static let calculationMethodSection = LocalizedStringResource("settings.calculation_method_section", defaultValue: "Calculation Method", table: "Localizable")
        static let asrMadhabSection = LocalizedStringResource("settings.asr_madhab_section", defaultValue: "Asr Madhab", table: "Localizable")
        static let madhabStandard = LocalizedStringResource("settings.madhab_standard", defaultValue: "Standard (Shafi, Maliki, Hanbali)", table: "Localizable")
        static let madhabHanafi = LocalizedStringResource("settings.madhab_hanafi", defaultValue: "Hanafi", table: "Localizable")
        static let adjustmentsFooter = LocalizedStringResource("settings.adjustments_footer", defaultValue: "Fine-tune each prayer time in minutes if it doesn't match your local mosque or preference.", table: "Localizable")
        static let aboutUsAppName = LocalizedStringResource("settings.about_app_name", defaultValue: "Islamic Companion", table: "Localizable")
        static let aboutUsBody = LocalizedStringResource("settings.about_body", defaultValue: "This app provides prayer times, Qibla direction, and the Holy Quran to support your daily worship.", table: "Localizable")
        static let aboutSection = LocalizedStringResource("settings.about_section", defaultValue: "About", table: "Localizable")

        static func versionLabel(_ version: String) -> LocalizedStringResource {
            LocalizedStringResource("settings.version_format", defaultValue: "Version \(version)", table: "Localizable")
        }

        /// Takes the already sign-formatted value ("+5", "0", "-3") — the
        /// +/- prefix is numeric formatting, not translation, so it stays in
        /// Swift (PrayerAdjustmentsView); this key only localizes the unit.
        static func minutesOffset(_ formattedValue: String) -> LocalizedStringResource {
            LocalizedStringResource("settings.minutes_offset_format", defaultValue: "\(formattedValue) min", table: "Localizable")
        }

        static func calculationMethodName(_ method: PrayerCalculationMethod) -> LocalizedStringResource {
            switch method {
            case .muslimWorldLeague: return LocalizedStringResource("calc_method.muslim_world_league", defaultValue: "Muslim World League", table: "Localizable")
            case .egyptianGeneralAuthority: return LocalizedStringResource("calc_method.egyptian", defaultValue: "Egyptian General Authority", table: "Localizable")
            case .karachi: return LocalizedStringResource("calc_method.karachi", defaultValue: "University of Islamic Sciences, Karachi", table: "Localizable")
            case .ummAlQura: return LocalizedStringResource("calc_method.umm_al_qura", defaultValue: "Umm Al-Qura University, Makkah", table: "Localizable")
            case .dubai: return LocalizedStringResource("calc_method.dubai", defaultValue: "Dubai", table: "Localizable")
            case .moonsightingCommittee: return LocalizedStringResource("calc_method.moonsighting", defaultValue: "Moonsighting Committee", table: "Localizable")
            case .northAmerica: return LocalizedStringResource("calc_method.isna", defaultValue: "Islamic Society of North America", table: "Localizable")
            case .kuwait: return LocalizedStringResource("calc_method.kuwait", defaultValue: "Kuwait", table: "Localizable")
            case .qatar: return LocalizedStringResource("calc_method.qatar", defaultValue: "Qatar", table: "Localizable")
            case .singapore: return LocalizedStringResource("calc_method.singapore", defaultValue: "Singapore", table: "Localizable")
            case .tehran: return LocalizedStringResource("calc_method.tehran", defaultValue: "Tehran", table: "Localizable")
            case .turkey: return LocalizedStringResource("calc_method.turkey", defaultValue: "Turkey (Diyanet)", table: "Localizable")
            }
        }
    }
}
