//
//  CachedValue.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct CachedValue<Value: Codable & Sendable>: Codable, Sendable {
    let value: Value
    let fetchedAt: Date
}
