import CoreLocation

enum LocationError: Error, Equatable, Sendable {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case reverseGeocodingFailed
    case citySearchFailed
}

/// Main-actor isolated: CLLocationManager's delegate callbacks arrive on an
/// unspecified thread and this protocol's implementations bridge them back
/// to the main actor internally, so callers never have to think about it.
@MainActor
protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization() async
    func requestCurrentLocation() async throws -> Coordinates
    func reverseGeocodedCity(for coordinates: Coordinates) async throws -> City?
    /// Forward-geocodes a free-text query (e.g. "Istanbul, Turkey") into
    /// candidate cities — powers manual city search without a bundled dataset.
    func searchCities(matching query: String) async throws -> [City]
}
