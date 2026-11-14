//
//  PrayerTimesServiceProtocol.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

protocol PrayerTimesServiceProtocol: Sendable {
    func fetchPrayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment
    ) async throws -> PrayerTimes
}
