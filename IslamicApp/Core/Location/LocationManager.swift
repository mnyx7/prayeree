//
//  LocationManager.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import CoreLocation

@MainActor
final class LocationManager: NSObject, LocationManaging {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var authorizationContinuations: [CheckedContinuation<Void, Never>] = []
    private var locationContinuations: [UUID: CheckedContinuation<Coordinates, Error>] = [:]
    private var locationTimeout: Task<Void, Never>?
    private var recentLocation: CLLocation?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization() async {
        guard authorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            let shouldRequest = authorizationContinuations.isEmpty
            authorizationContinuations.append(continuation)
            if shouldRequest { manager.requestWhenInUseAuthorization() }
        }
    }

    func requestCurrentLocation() async throws -> Coordinates {
        await requestWhenInUseAuthorization()
        switch authorizationStatus {
        case .denied: throw LocationError.permissionDenied
        case .restricted: throw LocationError.permissionRestricted
        case .authorizedAlways, .authorizedWhenInUse: break
        default: throw LocationError.locationUnavailable
        }
        try Task.checkCancellation()
        // Share a short-lived fix across prayer times, Settings, and Qibla.
        if let location = recentLocation ?? manager.location,
           Self.isUsableRecentLocation(location) {
            return Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                let shouldRequest = locationContinuations.isEmpty
                locationContinuations[id] = continuation
                if shouldRequest {
                    manager.requestLocation()
                    locationTimeout = Task { [weak self] in
                        do { try await Task.sleep(for: .seconds(15)) } catch { return }
                        self?.finishLocation(.failure(LocationError.locationUnavailable))
                    }
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.locationContinuations.removeValue(forKey: id)?.resume(throwing: CancellationError())
                if self?.locationContinuations.isEmpty == true {
                    self?.manager.stopUpdatingLocation()
                    self?.locationTimeout?.cancel()
                }
            }
        }
    }

    static func isUsableRecentLocation(_ location: CLLocation, now: Date = Date()) -> Bool {
        let age = now.timeIntervalSince(location.timestamp)
        return age >= 0 && age <= 60 && location.horizontalAccuracy >= 0
            && location.horizontalAccuracy <= 100
            && CLLocationCoordinate2DIsValid(location.coordinate)
    }

    private func finishLocation(_ result: Result<Coordinates, Error>) {
        locationTimeout?.cancel()
        locationTimeout = nil
        let continuations = locationContinuations.values
        locationContinuations.removeAll()
        for continuation in continuations { continuation.resume(with: result) }
    }

    func reverseGeocodedCity(for coordinates: Coordinates) async throws -> City? {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks?.first else {
            throw LocationError.reverseGeocodingFailed
        }
        return Self.city(from: placemark, coordinates: coordinates)
    }

    func searchCities(matching query: String) async throws -> [City] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        guard let placemarks = try? await geocoder.geocodeAddressString(query) else {
            throw LocationError.citySearchFailed
        }
        return placemarks.compactMap { placemark -> City? in
            guard let location = placemark.location else { return nil }
            let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            return Self.city(from: placemark, coordinates: coordinates)
        }
    }

    private static func city(from placemark: CLPlacemark, coordinates: Coordinates) -> City? {
        guard let cityName = placemark.locality ?? placemark.administrativeArea,
              let countryCode = placemark.isoCountryCode else {
            return nil
        }
        let timeZoneIdentifier = placemark.timeZone?.identifier ?? TimeZone.current.identifier
        let slug = "\(countryCode)-\(cityName)"
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return City(
            id: slug,
            name: cityName,
            countryCode: countryCode,
            coordinates: coordinates,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard self.manager.authorizationStatus != .notDetermined else { return }
            let continuations = self.authorizationContinuations
            self.authorizationContinuations.removeAll()
            for continuation in continuations { continuation.resume() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last(where: { $0.horizontalAccuracy >= 0 && CLLocationCoordinate2DIsValid($0.coordinate) }) else { return }
        let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            self.recentLocation = location
            self.finishLocation(.success(coordinates))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.finishLocation(.failure(LocationError.locationUnavailable))
        }
    }
}
