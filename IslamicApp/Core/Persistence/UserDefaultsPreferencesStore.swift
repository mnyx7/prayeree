//
//  UserDefaultsPreferencesStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

final class UserDefaultsPreferencesStore: PreferencesStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func value<Value: Codable & Sendable>(for key: String, as type: Value.Type) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    func setValue<Value: Codable & Sendable>(_ value: Value?, for key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
