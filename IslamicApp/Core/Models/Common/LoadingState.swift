//
//  LoadingState.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

/// Tracks the fetch lifecycle of a feature screen. The actual payload
/// (e.g. `PrayerTimes?`) is stored separately in the owning Store's `State`
/// so stale content can remain visible while a refresh is `.loading`.
enum LoadingState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed
}
