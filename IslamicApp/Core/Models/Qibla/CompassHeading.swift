/// Plain, Sendable mirror of `CLHeading` — kept independent of CoreLocation
/// types so Store `State` never has to carry a non-Sendable SDK class.
struct CompassHeading: Equatable, Sendable {
    let magneticHeadingDegrees: Double
    let trueHeadingDegrees: Double?
    /// Mirrors `CLHeading.headingAccuracy`; negative means invalid.
    let accuracyDegrees: Double

    var isAccurate: Bool {
        accuracyDegrees >= 0 && accuracyDegrees <= 15
    }
}
