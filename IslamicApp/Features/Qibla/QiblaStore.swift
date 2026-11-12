import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class QiblaStore {
    struct State: Equatable, Sendable {
        var authorizationStatus: CLAuthorizationStatus
        var coordinates: Coordinates?
        var heading: CompassHeading?
        var bearing: QiblaDirection?
        var relativeAngle: Double
        var isCompassAccurate: Bool
        var loadingState: LoadingState
        var isCalibrationVisible: Bool
        var errorMessage: String?
    }

    enum Action: Sendable {
        case screenAppeared
        case locationPermissionRequested
        case authorizationChanged(CLAuthorizationStatus)
        case locationUpdated(Coordinates)
        case headingUpdated(CompassHeading)
        case calibrationHelpTapped
        case retryTapped
        case screenDisappeared
        case locationFailed(String)
    }

    private(set) var state: State
    private let locationManager: any LocationManaging
    private let compassManager: any CompassManaging
    private let qiblaCalculator: any QiblaCalculating

    private var headingTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?

    init(
        locationManager: any LocationManaging,
        compassManager: any CompassManaging,
        qiblaCalculator: any QiblaCalculating
    ) {
        self.locationManager = locationManager
        self.compassManager = compassManager
        self.qiblaCalculator = qiblaCalculator
        self.state = State(
            authorizationStatus: locationManager.authorizationStatus,
            coordinates: nil,
            heading: nil,
            bearing: nil,
            relativeAngle: 0,
            isCompassAccurate: true,
            loadingState: .idle,
            isCalibrationVisible: false,
            errorMessage: nil
        )
    }

    func send(_ action: Action) {
        switch action {
        case .screenAppeared:
            state.authorizationStatus = locationManager.authorizationStatus
            state.loadingState = .loading
            state.errorMessage = nil
            resolveLocationAndStartCompass()

        case .locationPermissionRequested:
            Task { [weak self] in
                guard let self else { return }
                await self.locationManager.requestWhenInUseAuthorization()
                self.send(.authorizationChanged(self.locationManager.authorizationStatus))
            }

        case .authorizationChanged(let status):
            state.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                resolveLocationAndStartCompass()
            }

        case .locationUpdated(let coordinates):
            state.coordinates = coordinates
            state.bearing = qiblaCalculator.bearing(from: coordinates)
            state.loadingState = .loaded
            updateRelativeAngle()

        case .headingUpdated(let heading):
            state.heading = heading
            state.isCompassAccurate = heading.isAccurate
            state.isCalibrationVisible = !heading.isAccurate
            updateRelativeAngle()

        case .calibrationHelpTapped:
            state.isCalibrationVisible = true

        case .retryTapped:
            state.errorMessage = nil
            state.loadingState = .loading
            resolveLocationAndStartCompass()

        case .screenDisappeared:
            stopCompass()
            locationTask?.cancel()
            locationTask = nil

        case .locationFailed(let message):
            state.errorMessage = message
            state.loadingState = .failed
        }
    }

    private func resolveLocationAndStartCompass() {
        switch state.authorizationStatus {
        case .notDetermined:
            send(.locationPermissionRequested)
            return
        case .denied:
            state.errorMessage = String(localized: LocalizedKey.Qibla.permissionPromptDenied)
            state.loadingState = .failed
            return
        case .restricted:
            state.errorMessage = String(localized: LocalizedKey.Qibla.permissionPromptRestricted)
            state.loadingState = .failed
            return
        default:
            break
        }

        locationTask?.cancel()
        locationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let coordinates = try await self.locationManager.requestCurrentLocation()
                guard !Task.isCancelled else { return }
                self.send(.locationUpdated(coordinates))
            } catch {
                guard !Task.isCancelled else { return }
                self.send(.locationFailed(self.message(for: error)))
            }
        }

        startCompassIfNeeded()
    }

    private func startCompassIfNeeded() {
        guard headingTask == nil else { return }
        let stream = compassManager.headingUpdates()
        headingTask = Task { [weak self] in
            for await heading in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.headingUpdated(heading))
            }
        }
    }

    private func stopCompass() {
        headingTask?.cancel()
        headingTask = nil
        compassManager.stopUpdatingHeading()
    }

    private func updateRelativeAngle() {
        guard let bearing = state.bearing, let heading = state.heading else { return }
        state.relativeAngle = bearing.relativeAngle(from: heading)
    }

    private func message(for error: Error) -> String {
        switch error as? LocationError {
        case .permissionDenied:
            return String(localized: LocalizedKey.Qibla.permissionPromptDenied)
        case .permissionRestricted:
            return String(localized: LocalizedKey.Qibla.permissionPromptRestricted)
        case .locationUnavailable, .reverseGeocodingFailed, .citySearchFailed, .none:
            return String(localized: LocalizedKey.Qibla.permissionPromptUnknown)
        }
    }
}
