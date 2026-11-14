//
//  QiblaCalculating.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

protocol QiblaCalculating: Sendable {
    func bearing(from origin: Coordinates) -> QiblaDirection
}
