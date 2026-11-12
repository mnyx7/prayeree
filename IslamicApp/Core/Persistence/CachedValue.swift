import Foundation

struct CachedValue<Value: Codable & Sendable>: Codable, Sendable {
    let value: Value
    let fetchedAt: Date
}
