//
//  MockLocationManager.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
@testable import IslamicApp
import CoreLocation

@MainActor
final class MockLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var stubbedCoordinates: Coordinates?
    var stubbedCity: City?
    var stubbedError: Error?
    var stubbedSearchResults: [City] = []

    private(set) var requestedAuthorization = false
    private(set) var requestedCurrentLocation = false
    private(set) var lastSearchQuery: String?

    func requestWhenInUseAuthorization() async {
        requestedAuthorization = true
    }

    func requestCurrentLocation() async throws -> Coordinates {
        requestedCurrentLocation = true
        if let stubbedError { throw stubbedError }
        guard let stubbedCoordinates else { throw LocationError.locationUnavailable }
        return stubbedCoordinates
    }

    func reverseGeocodedCity(for coordinates: Coordinates) async throws -> City? {
        if let stubbedError { throw stubbedError }
        return stubbedCity
    }

    func searchCities(matching query: String) async throws -> [City] {
        lastSearchQuery = query
        if let stubbedError { throw stubbedError }
        return stubbedSearchResults
    }
}
