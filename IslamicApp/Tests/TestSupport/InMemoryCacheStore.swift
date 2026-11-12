import Foundation
@testable import IslamicApp
import Foundation

actor InMemoryCacheStore: CacheStore {
    private var storage: [CacheKey: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func value<Value: Codable & Sendable>(for key: CacheKey, as type: Value.Type) async -> CachedValue<Value>? {
        guard let data = storage[key] else { return nil }
        return try? decoder.decode(CachedValue<Value>.self, from: data)
    }

    func save<Value: Codable & Sendable>(_ value: Value, for key: CacheKey) async {
        let cached = CachedValue(value: value, fetchedAt: Date())
        guard let data = try? encoder.encode(cached) else { return }
        storage[key] = data
    }

    func removeValue(for key: CacheKey) async {
        storage[key] = nil
    }
}
