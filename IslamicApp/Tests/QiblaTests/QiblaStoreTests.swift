//
//  QiblaStoreTests.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import XCTest
import CoreLocation
@testable import IslamicApp

@MainActor
final class QiblaStoreTests: XCTestCase {
    private func makeStore(testEnv: TestEnvironment) -> QiblaStore {
        QiblaStore(
            locationManager: testEnv.locationManager,
            compassManager: testEnv.compassManager,
            qiblaCalculator: QiblaCalculator()
        )
    }

    func testScreenAppearedWithNotDeterminedRequestsPermission() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.locationManager.authorizationStatus = .notDetermined
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(testEnv.locationManager.requestedAuthorization)
    }

    func testScreenAppearedWithAuthorizedComputesBearing() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.locationManager.authorizationStatus = .authorizedWhenInUse
        testEnv.locationManager.stubbedCoordinates = Coordinates(latitude: 40.7128, longitude: -74.0060) // NYC
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(store.state.bearing)
        XCTAssertEqual(store.state.bearing?.bearingDegrees ?? -1, 58.5, accuracy: 1.0)
    }

    func testHeadingUpdateComputesRelativeAngle() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.locationManager.authorizationStatus = .authorizedWhenInUse
        testEnv.locationManager.stubbedCoordinates = Coordinates(latitude: 21.0, longitude: 39.0)
        let store = makeStore(testEnv: testEnv)
        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(100))
        let bearing = store.state.bearing!.bearingDegrees

        let heading = CompassHeading(magneticHeadingDegrees: bearing, trueHeadingDegrees: bearing, accuracyDegrees: 5)
        store.send(.headingUpdated(heading))

        XCTAssertEqual(store.state.relativeAngle, 0, accuracy: 0.01)
        XCTAssertEqual(store.state.heading, heading)
    }

    func testCalibrationVisibleWhenHeadingInaccurate() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)
        let inaccurateHeading = CompassHeading(magneticHeadingDegrees: 10, trueHeadingDegrees: 10, accuracyDegrees: 45)

        store.send(.headingUpdated(inaccurateHeading))

        XCTAssertTrue(store.state.isCalibrationVisible)
        XCTAssertFalse(store.state.isCompassAccurate)
    }

    func testScreenDisappearedStopsCompass() {
        let testEnv = TestEnvironmentFactory.make()
        let store = makeStore(testEnv: testEnv)

        store.send(.screenDisappeared)

        XCTAssertTrue(testEnv.compassManager.didStop)
    }

    func testDeniedPermissionSetsErrorMessage() async {
        let testEnv = TestEnvironmentFactory.make()
        testEnv.locationManager.authorizationStatus = .denied
        let store = makeStore(testEnv: testEnv)

        store.send(.screenAppeared)
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(store.state.errorMessage)
        XCTAssertEqual(store.state.loadingState, .failed)
    }
}
