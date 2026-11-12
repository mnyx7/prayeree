import Foundation

struct QiblaDirection: Equatable, Sendable {
    /// True-north relative bearing to the Kaaba, normalized to [0, 360).
    let bearingDegrees: Double

    init(bearingDegrees: Double) {
        self.bearingDegrees = QiblaDirection.normalize(bearingDegrees)
    }

    static func normalize(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    /// Angle between this bearing and the device's current heading, normalized
    /// to [0, 360). A value of 0 means the device is pointing at the Qibla.
    func relativeAngle(from heading: CompassHeading) -> Double {
        let deviceHeading = heading.trueHeadingDegrees ?? heading.magneticHeadingDegrees
        return QiblaDirection.normalize(bearingDegrees - deviceHeading)
    }
}
