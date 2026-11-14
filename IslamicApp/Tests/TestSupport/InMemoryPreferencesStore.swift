//
//  InMemoryPreferencesStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation
@testable import IslamicApp
final class InMemoryPreferencesStore: PreferencesStore, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func value<Value: Codable & Sendable>(for key: String, as type: Value.Type) -> Value? {
        storage[key] as? Value
    }

    func setValue<Value: Codable & Sendable>(_ value: Value?, for key: String) {
        storage[key] = value
    }
}
