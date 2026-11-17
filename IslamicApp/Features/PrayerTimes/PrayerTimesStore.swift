//
//  PrayerTimesStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class PrayerTimesStore {
    struct State: Equatable, Sendable {
        var selectedDate: Date
        var prayerTimes: PrayerTimes?
        var nextPrayer: PrayerTime?
        var remainingCountdown: TimeInterval
        var loadingState: LoadingState
        var freshness: DataFreshness
        var lastUpdated: Date?
        var activeSheet: ActiveSheet?
        var errorMessage: String?
        var isRefreshing: Bool
        var citySearchQuery: String
        var citySearchResults: [City]
        var isSearchingCities: Bool
        var selectedCountryForCitySearch: Country?
    }

    enum ActiveSheet: Identifiable, Equatable, Sendable {
        case datePicker
        case citySelector
        case favoriteCities

        var id: Self { self }
    }

    enum Action: Sendable {
        case screenAppeared
        case configurationChanged
        case refreshRequested
        case dateTapped
        case dateSelected(Date)
        case locationTapped
        case citySelected(City)
        case currentLocationRequested
        case locationResolved(Coordinates)
        case locationRequestFailed(String)
        case prayerDataLoaded(PrayerTimesRepositoryResult)
        case favoriteToggled(City)
        case favoriteCitiesReordered([City])
        case favoriteCitiesTapped
        case recentCitySelected(City)
        case countdownTicked(Date)
        case retryTapped
        case sheetDismissed
        case citySearchQueryChanged(String)
        case citySearchResultsLoaded([City])
        case countrySelectedForSearch(Country?)
    }

    private(set) var state: State
    private let appStore: AppStore
    private let repository: any PrayerTimesRepositoryProtocol
    private let locationManager: any LocationManaging
    private let preferencesStore: any PreferencesStore
    private let widgetPublisher: AppWidgetPublisher?
    private let now: @Sendable () -> Date

    private var lastLoadTrigger: RefreshTrigger?
    private var lastLoadDate: DateComponents?
    private var loadTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var citySearchTask: Task<Void, Never>?

    private static let citySearchDebounce: Duration = .milliseconds(400)

    var prayerTimeZoneIdentifier: String {
        if case .manual(_, let city) = locationSourceMode { return city.timeZoneIdentifier }
        if let city = selectedCity, city.coordinates == resolvedCoordinates { return city.timeZoneIdentifier }
        return TimeZone.current.identifier
    }

    var activeCityID: String? {
        if case .manual(_, let city) = locationSourceMode { return city.id }
        return nil
    }

    var selectedCity: City? { appStore.state.selectedCity }
    var favoriteCities: [City] { appStore.favoriteCities }
    var recentCities: [City] { appStore.recentCities }
    var selectedCountry: Country? { appStore.state.selectedCountry }
    var resolvedCoordinates: Coordinates? { appStore.state.resolvedCoordinates }
    var locationSourceMode: LocationSourceMode { appStore.state.locationSourceMode }

    /// Includes location so changes made in Settings refresh an already-visible screen.
    struct RefreshTrigger: Equatable {
        let calculationMethod: PrayerCalculationMethod
        let madhab: MadhabOption
        let adjustment: PrayerAdjustment
        let coordinates: Coordinates?
        let locationMode: LocationSourceMode
        let timetableCity: City?
    }

    var refreshTrigger: RefreshTrigger {
        RefreshTrigger(
            calculationMethod: appStore.state.calculationMethod,
            madhab: appStore.state.madhab,
            adjustment: appStore.state.prayerAdjustment,
            coordinates: resolvedCoordinates,
            locationMode: locationSourceMode,
            timetableCity: appStore.state.calculationMethod == .qmiMinber ? appStore.state.selectedCity : nil
        )
    }

    init(
        appStore: AppStore,
        repository: any PrayerTimesRepositoryProtocol,
        locationManager: any LocationManaging,
        preferencesStore: any PreferencesStore,
        now: @escaping @Sendable () -> Date = { Date() },
        widgetPublisher: AppWidgetPublisher? = nil
    ) {
        self.appStore = appStore
        self.repository = repository
        self.locationManager = locationManager
        self.preferencesStore = preferencesStore
        self.now = now
        self.widgetPublisher = widgetPublisher
        self.state = State(
            selectedDate: now(),
            prayerTimes: nil,
            nextPrayer: nil,
            remainingCountdown: 0,
            loadingState: .idle,
            freshness: .none,
            lastUpdated: nil,
            activeSheet: nil,
            errorMessage: nil,
            isRefreshing: false,
            citySearchQuery: "",
            citySearchResults: [],
            isSearchingCities: false,
            selectedCountryForCitySearch: nil
        )
    }

    func send(_ action: Action) {
        switch action {
        case .screenAppeared:
            startCountdownIfNeeded()
            if resolvedCoordinates != nil {
                load()
            } else if case .automatic = locationSourceMode {
                requestCurrentLocation()
            }

        case .configurationChanged:
            if lastLoadTrigger != refreshTrigger { load() }

        case .refreshRequested:
            load(forceRefreshIndicator: true)

        case .dateTapped:
            state.activeSheet = .datePicker

        case .dateSelected(let date):
            state.selectedDate = date
            state.activeSheet = nil
            load()

        case .locationTapped:
            state.activeSheet = .citySelector

        case .citySelected(let city):
            state.activeSheet = nil
            state.citySearchQuery = ""
            state.citySearchResults = []
            state.selectedCountryForCitySearch = nil
            if activeCityID == city.id {
                if !favoriteCities.contains(where: { $0.id == city.id }) { appStore.send(.favoriteCityToggled(city)) }
                return
            }
            let country = Country(code: city.countryCode)
            appStore.send(.locationSourceModeChanged(.manual(country: country, city: city)))
            load()

        case .currentLocationRequested:
            appStore.send(.locationSourceModeChanged(.automatic))
            requestCurrentLocation()

        case .locationResolved(let coordinates):
            appStore.send(.coordinatesResolved(coordinates))
            load()

        case .locationRequestFailed(let message):
            // Per spec section C: fall back to the last manual city rather
            // than blocking the screen, but only when we have nothing to show
            // yet — a failure on a later re-request shouldn't wipe an already
            // successfully-loaded screen.
            if state.prayerTimes == nil, let fallbackCity = appStore.state.selectedCity {
                state.errorMessage = message
                appStore.send(.coordinatesResolved(fallbackCity.coordinates))
                load()
            } else {
                state.errorMessage = message
                state.loadingState = .failed
            }

        case .prayerDataLoaded(let result):
            apply(result)

        case .favoriteToggled(let city):
            toggleFavorite(city)

        case .favoriteCitiesReordered(let cities):
            appStore.send(.favoriteCitiesReordered(cities))

        case .favoriteCitiesTapped:
            state.activeSheet = .favoriteCities

        case .recentCitySelected(let city):
            send(.citySelected(city))

        case .countdownTicked(let currentTime):
            updateCountdown(now: currentTime)

        case .retryTapped:
            load(forceRefreshIndicator: true)

        case .sheetDismissed:
            state.activeSheet = nil

        case .citySearchQueryChanged(let query):
            state.citySearchQuery = query
            searchCities(matching: query)

        case .citySearchResultsLoaded(let results):
            state.citySearchResults = results
            state.isSearchingCities = false

        case .countrySelectedForSearch(let country):
            state.selectedCountryForCitySearch = country
            state.citySearchQuery = ""
            state.citySearchResults = []
        }
    }

    // MARK: - Loading

    private func load(forceRefreshIndicator: Bool = false) {
        loadTask?.cancel()
        guard let coordinates = resolvedCoordinates else {
            state.errorMessage = nil
            state.loadingState = .idle
            return
        }
        if forceRefreshIndicator { state.isRefreshing = true }
        if state.prayerTimes == nil { state.loadingState = .loading }
        state.errorMessage = nil

        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: state.selectedDate)
        if lastLoadTrigger != refreshTrigger || lastLoadDate != dateComponents {
            state.prayerTimes = nil
            state.nextPrayer = nil
            state.remainingCountdown = 0
            state.freshness = .none
            state.loadingState = .loading
        }
        lastLoadTrigger = refreshTrigger
        lastLoadDate = dateComponents
        let stream = repository.prayerTimes(
            dateComponents: dateComponents,
            coordinates: coordinates,
            calculationMethod: appStore.state.calculationMethod,
            madhab: appStore.state.madhab,
            adjustment: appStore.state.prayerAdjustment,
            city: appStore.state.selectedCity,
            timeZoneIdentifier: prayerTimeZoneIdentifier
        )
        loadTask = Task { [weak self] in
            for await result in stream {
                guard let self, !Task.isCancelled else { return }
                self.send(.prayerDataLoaded(result))
            }
        }
    }

    private func apply(_ result: PrayerTimesRepositoryResult) {
        state.isRefreshing = false
        if let prayerTimes = result.prayerTimes {
            widgetPublisher?.publishPrayerTimes(prayerTimes)
            state.prayerTimes = prayerTimes
            state.freshness = result.freshness
            state.lastUpdated = result.freshness.lastUpdated
            state.loadingState = .loaded
            state.errorMessage = nil
            updateCountdown(now: now())
        } else {
            state.loadingState = .failed
            state.errorMessage = message(for: result.error)
        }
    }

    private func message(for error: NetworkError?) -> String {
        if appStore.state.calculationMethod == .qmiMinber {
            switch error {
            case .invalidResponse?, .decodingFailed?: return String(localized: LocalizedKey.Settings.minberUnavailable)
            default: break
            }
        }
        switch error {
        case .none:
            return String(localized: LocalizedKey.Common.genericLoadError())
        case .invalidURL, .invalidResponse, .decodingFailed:
            return String(localized: LocalizedKey.PrayerTimes.errorLoadFailed)
        case .httpStatus:
            return String(localized: LocalizedKey.Common.serviceUnavailableError())
        case .transportError, .cancelled:
            return String(localized: LocalizedKey.Common.networkLoadError())
        }
    }

    // MARK: - Countdown

    private func startCountdownIfNeeded() {
        guard countdownTask == nil else { return }
        countdownTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.send(.countdownTicked(self.now()))
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func updateCountdown(now currentTime: Date) {
        guard let prayerTimes = state.prayerTimes else {
            state.nextPrayer = nil
            state.remainingCountdown = 0
            return
        }
        if let next = prayerTimes.nextPrayer(after: currentTime) {
            state.nextPrayer = next
            state.remainingCountdown = next.remaining(from: currentTime)
            return
        }
        // All of today's prayers have passed. Only auto-advance when the user
        // is looking at "today" — a deliberately-picked past/future date should
        // not silently jump forward.
        state.nextPrayer = nil
        state.remainingCountdown = 0
        guard Calendar.current.isDateInToday(state.selectedDate),
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.date) else { return }
        state.selectedDate = tomorrow
        load()
    }

    // MARK: - Location

    private func requestCurrentLocation() {
        Task { [weak self] in
            guard let self else { return }
            await self.locationManager.requestWhenInUseAuthorization()
            do {
                let coordinates = try await self.locationManager.requestCurrentLocation()
                guard case .automatic = self.locationSourceMode else { return }
                self.send(.locationResolved(coordinates))
                if let city = try? await self.locationManager.reverseGeocodedCity(for: coordinates) {
                    self.appStore.send(.cityResolved(city))
                }
            } catch {
                self.send(.locationRequestFailed(self.message(forLocation: error)))
            }
        }
    }

    private func message(forLocation error: Error) -> String {
        switch error as? LocationError {
        case .permissionDenied:
            return String(localized: LocalizedKey.PrayerTimes.errorLocationDenied)
        case .permissionRestricted:
            return String(localized: LocalizedKey.PrayerTimes.errorLocationRestricted)
        case .locationUnavailable, .reverseGeocodingFailed, .citySearchFailed, .none:
            return String(localized: LocalizedKey.PrayerTimes.errorLocationUnavailable)
        }
    }

    private func searchCities(matching query: String) {
        citySearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state.citySearchResults = []
            state.isSearchingCities = false
            return
        }
        state.isSearchingCities = true
        let scopedQuery = state.selectedCountryForCitySearch.map { "\(trimmed), \($0.name)" } ?? trimmed
        citySearchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.citySearchDebounce)
            guard let self, !Task.isCancelled else { return }
            let results = (try? await self.locationManager.searchCities(matching: scopedQuery)) ?? []
            guard !Task.isCancelled else { return }
            self.send(.citySearchResultsLoaded(results))
        }
    }

    // MARK: - Favorites & Recents

    private func toggleFavorite(_ city: City) {
        appStore.send(.favoriteCityToggled(city))
    }
}
