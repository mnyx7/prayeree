//
//  DataFreshness.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum DataFreshness: Equatable, Sendable {
    case calculated(fetchedAt: Date)
    case none
    case fresh(fetchedAt: Date)
    case cached(fetchedAt: Date)

    var lastUpdated: Date? {
        switch self {
        case .none: return nil
        case .fresh(let date), .cached(let date), .calculated(let date): return date
        }
    }

    var isCached: Bool {
        if case .cached = self { return true }
        return false
    }
}
