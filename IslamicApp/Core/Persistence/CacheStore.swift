//
//  CacheStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

protocol CacheStore: Sendable {
    func value<Value: Codable & Sendable>(for key: CacheKey, as type: Value.Type) async -> CachedValue<Value>?
    func save<Value: Codable & Sendable>(_ value: Value, for key: CacheKey) async
    func removeValue(for key: CacheKey) async
}
