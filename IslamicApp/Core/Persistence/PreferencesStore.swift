/// Synchronous by design — UserDefaults (the only realistic V1 backing store)
/// is already thread-safe and effectively instantaneous, so wrapping it in
/// async/await would add ceremony without a real benefit.
protocol PreferencesStore: Sendable {
    func value<Value: Codable & Sendable>(for key: String, as type: Value.Type) -> Value?
    func setValue<Value: Codable & Sendable>(_ value: Value?, for key: String)
}
