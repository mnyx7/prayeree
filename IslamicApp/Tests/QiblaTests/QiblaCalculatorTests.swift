import XCTest
@testable import IslamicApp

final class QiblaCalculatorTests: XCTestCase {
    private let sut = QiblaCalculator()

    // On the Kaaba's own meridian, south of it, the great-circle bearing
    // reduces exactly to due north — a zero-ambiguity check on the formula's
    // sign conventions rather than a value that depends on trig-table lookup.
    func testBearingIsDueNorthWhenOriginIsSouthOnSameMeridian() {
        let origin = Coordinates(latitude: 0, longitude: QiblaCalculator.kaaba.longitude)

        let direction = sut.bearing(from: origin)

        XCTAssertEqual(direction.bearingDegrees, 0, accuracy: 0.01)
    }

    // Symmetric case: due south of the Kaaba on the same meridian, the
    // bearing back to it reduces exactly to due south.
    func testBearingIsDueSouthWhenOriginIsNorthOnSameMeridian() {
        let origin = Coordinates(latitude: 45, longitude: QiblaCalculator.kaaba.longitude)

        let direction = sut.bearing(from: origin)

        XCTAssertEqual(direction.bearingDegrees, 180, accuracy: 0.01)
    }

    func testBearingFromEquatorNinetyDegreesWestOfKaabaMeridian() {
        let origin = Coordinates(latitude: 0, longitude: QiblaCalculator.kaaba.longitude - 90)

        let direction = sut.bearing(from: origin)

        XCTAssertEqual(direction.bearingDegrees, 68.6, accuracy: 0.5)
    }

    func testBearingIsAlwaysNormalizedToFullCircleRange() {
        let origin = Coordinates(latitude: 40.7128, longitude: -74.0060) // New York City

        let direction = sut.bearing(from: origin)

        XCTAssertGreaterThanOrEqual(direction.bearingDegrees, 0)
        XCTAssertLessThan(direction.bearingDegrees, 360)
    }

    func testBearingFromKaabaCoordinatesDoesNotCrash() {
        let direction = sut.bearing(from: QiblaCalculator.kaaba)

        XCTAssertFalse(direction.bearingDegrees.isNaN)
    }

    // Known-city checks (Phase 6 requirement). Expected values are commonly
    // published Qibla bearings for these cities, independently cross-checked
    // by hand-deriving the great-circle formula; tolerance allows for minor
    // rounding differences between sources.
    func testBearingFromNewYorkCityMatchesPublishedValue() {
        let newYorkCity = Coordinates(latitude: 40.7128, longitude: -74.0060)

        let direction = sut.bearing(from: newYorkCity)

        XCTAssertEqual(direction.bearingDegrees, 58.5, accuracy: 1.0)
    }

    func testBearingFromLondonMatchesPublishedValue() {
        let london = Coordinates(latitude: 51.5074, longitude: -0.1278)

        let direction = sut.bearing(from: london)

        XCTAssertEqual(direction.bearingDegrees, 119.0, accuracy: 1.0)
    }
}
