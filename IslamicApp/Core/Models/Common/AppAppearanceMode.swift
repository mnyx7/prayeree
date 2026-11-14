//
//  AppAppearanceMode.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum AppAppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
}
