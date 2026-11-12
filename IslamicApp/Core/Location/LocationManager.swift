import CoreLocation

@MainActor
final class LocationManager: NSObject, LocationManaging {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<Coordinates, Error>?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUseAuthorization() async {
        guard authorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestCurrentLocation() async throws -> Coordinates {
        switch authorizationStatus {
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
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
            authorizationContinuation?.resume()
            authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        Task { @MainActor in
            locationContinuation?.resume(returning: coordinates)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
        }
    }
}
