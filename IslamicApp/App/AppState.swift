//
//  AppState.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import UserNotifications

/// Global, cross-cutting state only — anything only one screen renders stays
/// feature-local in that feature's own Store.State (see Phase 0 contract).
struct AppState: Equatable, Sendable {
    var locationSourceMode: LocationSourceMode
    /// The coordinates currently in effect for Prayer Times / Qibla, kept in
    /// sync by AppStore regardless of whether they came from GPS or a
    /// manually selected city.
    var resolvedCoordinates: Coordinates?
    var selectedCountry: Country?
    var selectedCity: City?
    var appearanceMode: AppAppearanceMode
    var calculationMethod: PrayerCalculationMethod
    var madhab: MadhabOption
    var prayerAdjustment: PrayerAdjustment
    /// Queried live from the OS (see AppStore.refreshNotificationAuthorizationStatus)
    /// rather than persisted — the user can flip this in system Settings
    /// outside the app, so a cached value could go stale.
    var notificationAuthorizationStatus: UNAuthorizationStatus

    static let initial = AppState(
        locationSourceMode: .automatic,
        resolvedCoordinates: nil,
        selectedCountry: nil,
        selectedCity: nil,
        appearanceMode: .system,
        calculationMethod: .muslimWorldLeague,
        madhab: .shafiMalikiHanbali,
        prayerAdjustment: .zero,
        notificationAuthorizationStatus: .notDetermined
    )
}

extension AppState: Codable {
    private enum CodingKeys: String, CodingKey {
        case locationSourceMode, resolvedCoordinates, selectedCountry, selectedCity
        case appearanceMode, calculationMethod, madhab, prayerAdjustment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locationSourceMode = try container.decode(LocationSourceMode.self, forKey: .locationSourceMode)
        resolvedCoordinates = try container.decodeIfPresent(Coordinates.self, forKey: .resolvedCoordinates)
        selectedCountry = try container.decodeIfPresent(Country.self, forKey: .selectedCountry)
        selectedCity = try container.decodeIfPresent(City.self, forKey: .selectedCity)
        appearanceMode = try container.decode(AppAppearanceMode.self, forKey: .appearanceMode)
        calculationMethod = try container.decode(PrayerCalculationMethod.self, forKey: .calculationMethod)
        madhab = try container.decode(MadhabOption.self, forKey: .madhab)
        prayerAdjustment = try container.decode(PrayerAdjustment.self, forKey: .prayerAdjustment)
        notificationAuthorizationStatus = .notDetermined
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locationSourceMode, forKey: .locationSourceMode)
        try container.encodeIfPresent(resolvedCoordinates, forKey: .resolvedCoordinates)
        try container.encodeIfPresent(selectedCountry, forKey: .selectedCountry)
        try container.encodeIfPresent(selectedCity, forKey: .selectedCity)
        try container.encode(appearanceMode, forKey: .appearanceMode)
        try container.encode(calculationMethod, forKey: .calculationMethod)
        try container.encode(madhab, forKey: .madhab)
        try container.encode(prayerAdjustment, forKey: .prayerAdjustment)
    }
}
