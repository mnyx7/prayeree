//
//  FileCacheStore.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

/// An actor rather than a lock-guarded class — cache reads/writes are
/// naturally serialized without extra synchronization code, and the type
/// gets Sendable conformance for free.
actor FileCacheStore: CacheStore {
    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL = FileCacheStore.defaultDirectory()) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Remove legacy Quran content copies before any cache reads.
        for url in (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [] {
            if url.lastPathComponent.hasPrefix("quran.") { try? FileManager.default.removeItem(at: url) }
        }
        var excludedDirectory = directory
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try? excludedDirectory.setResourceValues(flags)
    }

    static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Cache", isDirectory: true)
    }

    func value<Value: Codable & Sendable>(for key: CacheKey, as type: Value.Type) async -> CachedValue<Value>? {
        guard !key.namespace.hasPrefix("quran."),
              let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        return try? decoder.decode(CachedValue<Value>.self, from: data)
    }

    func save<Value: Codable & Sendable>(_ value: Value, for key: CacheKey) async {
        guard !key.namespace.hasPrefix("quran.") else { return }
        let cached = CachedValue(value: value, fetchedAt: Date())
        guard let data = try? encoder.encode(cached) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    func removeValue(for key: CacheKey) async {
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    private func fileURL(for key: CacheKey) -> URL {
        directory.appendingPathComponent(key.storageFileName)
    }
}
