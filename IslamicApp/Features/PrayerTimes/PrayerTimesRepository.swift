//
//  PrayerTimesRepository.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct PrayerTimesRepository: PrayerTimesRepositoryProtocol {
    let service: any PrayerTimesServiceProtocol
    let cacheStore: any CacheStore

    func prayerTimes(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment,
        timeZoneIdentifier: String? = nil
    ) -> AsyncStream<PrayerTimesRepositoryResult> {
        let key = Self.cacheKey(
            dateComponents: dateComponents,
            coordinates: coordinates,
            calculationMethod: calculationMethod,
            madhab: madhab,
            adjustment: adjustment
        )

        return AsyncStream { continuation in
            let task = Task {
                let cached = await cacheStore.value(for: key, as: PrayerTimes.self)
                let local = timeZoneIdentifier.flatMap {
                    LocalPrayerTimesCalculator.calculate(dateComponents: dateComponents,
                        coordinates: coordinates, calculationMethod: calculationMethod,
                        madhab: madhab, adjustment: adjustment, timeZoneIdentifier: $0)
                }
                if cached == nil, let local {
                    continuation.yield(PrayerTimesRepositoryResult(prayerTimes: local,
                        freshness: .calculated(fetchedAt: Date()), error: nil))
                }
                if let cached {
                    continuation.yield(
                        PrayerTimesRepositoryResult(
                            prayerTimes: cached.value,
                            freshness: .cached(fetchedAt: cached.fetchedAt),
                            error: nil
                        )
                    )
                }

                do {
                    let fresh = try await service.fetchPrayerTimes(
                        dateComponents: dateComponents,
                        coordinates: coordinates,
                        calculationMethod: calculationMethod,
                        madhab: madhab,
                        adjustment: adjustment
                    )
                    await cacheStore.save(fresh, for: key)
                    continuation.yield(
                        PrayerTimesRepositoryResult(prayerTimes: fresh, freshness: .fresh(fetchedAt: Date()), error: nil)
                    )
                } catch {
                    let networkError = (error as? NetworkError) ?? .transportError(error.localizedDescription)
                    if let cached {
                        continuation.yield(
                            PrayerTimesRepositoryResult(
                                prayerTimes: cached.value,
                                freshness: .cached(fetchedAt: cached.fetchedAt),
                                error: networkError
                            )
                        )
                    } else if let local {
                        continuation.yield(PrayerTimesRepositoryResult(prayerTimes: local,
                            freshness: .calculated(fetchedAt: Date()), error: networkError))
                    } else {
                        continuation.yield(
                            PrayerTimesRepositoryResult(prayerTimes: nil, freshness: .none, error: networkError)
                        )
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Coordinates are rounded to 2 decimal places (~1.1km) so minor GPS
    /// jitter between launches still hits the same cache entry; combined
    /// with date/method/madhab/adjustment so any of those changing yields a
    /// distinct key, per the Phase 0 cache-key contract.
    static func cacheKey(
        dateComponents: DateComponents,
        coordinates: Coordinates,
        calculationMethod: PrayerCalculationMethod,
        madhab: MadhabOption,
        adjustment: PrayerAdjustment
    ) -> CacheKey {
        let rounded = coordinates.rounded(toDecimalPlaces: 2)
        let dateKey = "\(dateComponents.year ?? 0)-\(dateComponents.month ?? 0)-\(dateComponents.day ?? 0)"
        let adjustmentKey = PrayerName.allCases
            .map { String(adjustment.minutes(for: $0)) }
            .joined(separator: ",")
        let identifier = [
            dateKey,
            "\(rounded.latitude)",
            "\(rounded.longitude)",
            "\(calculationMethod.rawValue)",
            "\(madhab.rawValue)",
            adjustmentKey
        ].joined(separator: "_")
        return CacheKey(namespace: "prayerTimes", identifier: identifier)
    }
}
