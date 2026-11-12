import Foundation

/// Local-only great-circle initial-bearing calculation — no network call
/// needed, so Qibla direction is available even fully offline once the
/// device's coordinates are known.
struct QiblaCalculator: QiblaCalculating {
    static let kaaba = Coordinates(latitude: 21.4225, longitude: 39.8262)

    func bearing(from origin: Coordinates) -> QiblaDirection {
        let lat1 = origin.latitude * .pi / 180
        let lon1 = origin.longitude * .pi / 180
        let lat2 = Self.kaaba.latitude * .pi / 180
        let lon2 = Self.kaaba.longitude * .pi / 180

        let deltaLon = lon2 - lon1
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearingRadians = atan2(y, x)
        let bearingDegrees = bearingRadians * 180 / .pi

        return QiblaDirection(bearingDegrees: bearingDegrees)
    }
}
