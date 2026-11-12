import XCTest
@testable import IslamicApp

final class QiblaDirectionTests: XCTestCase {
    func testNormalizeWrapsNegativeDegrees() {
        XCTAssertEqual(QiblaDirection.normalize(-10), 350, accuracy: 0.001)
    }

    func testNormalizeWrapsAboveFullCircle() {
        XCTAssertEqual(QiblaDirection.normalize(370), 10, accuracy: 0.001)
    }

    func testInitializerNormalizesBearing() {
        let direction = QiblaDirection(bearingDegrees: 400)
        XCTAssertEqual(direction.bearingDegrees, 40, accuracy: 0.001)
    }

    func testRelativeAngleIsZeroWhenFacingQibla() {
        let direction = QiblaDirection(bearingDegrees: 120)
        let heading = CompassHeading(magneticHeadingDegrees: 120, trueHeadingDegrees: 120, accuracyDegrees: 5)
        XCTAssertEqual(direction.relativeAngle(from: heading), 0, accuracy: 0.001)
    }

    func testRelativeAnglePrefersTrueHeadingOverMagnetic() {
        let direction = QiblaDirection(bearingDegrees: 90)
        let heading = CompassHeading(magneticHeadingDegrees: 45, trueHeadingDegrees: 90, accuracyDegrees: 5)
        XCTAssertEqual(direction.relativeAngle(from: heading), 0, accuracy: 0.001)
    }

    func testRelativeAngleFallsBackToMagneticHeadingWhenTrueHeadingUnavailable() {
        let direction = QiblaDirection(bearingDegrees: 90)
        let heading = CompassHeading(magneticHeadingDegrees: 90, trueHeadingDegrees: nil, accuracyDegrees: 5)
        XCTAssertEqual(direction.relativeAngle(from: heading), 0, accuracy: 0.001)
    }
}
