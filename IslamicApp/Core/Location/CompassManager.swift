//
//  CompassManager.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import CoreLocation

@MainActor
final class CompassManager: NSObject, CompassManaging {
    // Deliberately its own CLLocationManager instance rather than sharing
    // LocationManager's — a CLLocationManager has exactly one delegate, and
    // heading updates (continuous, tab-scoped) have a different lifecycle
    // than one-shot location resolution.
    private let manager = CLLocationManager()
    private var streamID = UUID()
    private var continuation: AsyncStream<CompassHeading>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
    }

    func headingUpdates() -> AsyncStream<CompassHeading> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            let streamID = UUID()
            self.streamID = streamID
            self.continuation = continuation
            guard CLLocationManager.headingAvailable() else {
                continuation.finish()
                return
            }
            self.manager.headingFilter = 1
            self.manager.startUpdatingHeading()
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.streamID == streamID else { return }
                    self.manager.stopUpdatingHeading()
                }
            }
        }
    }

    func stopUpdatingHeading() {
        manager.stopUpdatingHeading()
        continuation?.finish()
        continuation = nil
    }
}

extension CompassManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = CompassHeading(
            magneticHeadingDegrees: newHeading.magneticHeading,
            trueHeadingDegrees: newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil,
            accuracyDegrees: newHeading.headingAccuracy
        )
        Task { @MainActor in
            self.continuation?.yield(heading)
        }
    }
}
