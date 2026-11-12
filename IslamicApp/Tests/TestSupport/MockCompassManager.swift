import Foundation
@testable import IslamicApp
@MainActor
final class MockCompassManager: CompassManaging {
    private(set) var didStop = false
    private var continuation: AsyncStream<CompassHeading>.Continuation?

    func headingUpdates() -> AsyncStream<CompassHeading> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stopUpdatingHeading() {
        didStop = true
        continuation?.finish()
        continuation = nil
    }

    /// Test-only hook to push a heading value as if the sensor produced it.
    func simulateHeading(_ heading: CompassHeading) {
        continuation?.yield(heading)
    }
}
