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
