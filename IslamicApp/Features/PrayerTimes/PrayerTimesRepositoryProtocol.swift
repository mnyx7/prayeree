//
//  PrayerTimesRepositoryProtocol.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// `prayerTimes` is nil only when there is no usable cache AND the network
/// call failed — the one true error state. Any other combination (fresh
/// success, or cached value with a background refresh failure) still
/// carries usable data; `error` alongside a populated value just means
/// "the refresh didn't succeed, here's what we still have."
struct PrayerTimesRepositoryResult: Sendable {
    let prayerTimes: PrayerTimes?
    let freshness: DataFreshness
    let error: NetworkError?
}

protocol PrayerTimesRepositoryProtocol: Sendable {
    /// Yields up to twice: once immediately with cached data (if any), then
    /// again once the network attempt resolves — matching the cache-first,
    /// network-refresh strategy from the architecture contract.
    func prayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment,
        timeZoneIdentifier: String?
    ) -> AsyncStream<PrayerTimesRepositoryResult>
}

extension PrayerTimesRepositoryProtocol {
    func prayerTimes(dateComponents: DateComponents, coordinates: Coordinates,
                     calculationMethod: PrayerCalculationMethod, madhab: MadhabOption,
                     adjustment: PrayerAdjustment) -> AsyncStream<PrayerTimesRepositoryResult> {
        prayerTimes(dateComponents: dateComponents, coordinates: coordinates,
                    calculationMethod: calculationMethod, madhab: madhab,
                    adjustment: adjustment, timeZoneIdentifier: nil)
    }
}
