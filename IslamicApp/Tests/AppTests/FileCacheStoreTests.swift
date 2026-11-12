import XCTest
@testable import IslamicApp

final class FileCacheStoreTests: XCTestCase {
    private var directory: URL!
    private var sut: FileCacheStore!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileCacheStoreTests-\(UUID().uuidString)", isDirectory: true)
        sut = FileCacheStore(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        sut = nil
        directory = nil
        super.tearDown()
    }

    func testReadingMissingValueReturnsNil() async {
        let result = await sut.value(for: CacheKey(namespace: "test", identifier: "missing"), as: String.self)
        XCTAssertNil(result)
    }

    func testWriteThenReadRoundTrips() async {
        let key = CacheKey(namespace: "test", identifier: "surahList")
        await sut.save(["Al-Fatiha", "Al-Baqarah"], for: key)

        let result = await sut.value(for: key, as: [String].self)
        XCTAssertEqual(result?.value, ["Al-Fatiha", "Al-Baqarah"])
    }

    func testSavedValueRecordsFetchTimestamp() async {
        let key = CacheKey(namespace: "test", identifier: "timestamped")
        let before = Date()
        await sut.save(42, for: key)
        let after = Date()

        let result = await sut.value(for: key, as: Int.self)
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result!.fetchedAt, before)
        XCTAssertLessThanOrEqual(result!.fetchedAt, after)
    }

    // "Expiration" at this generic infra layer means explicit invalidation
    // (removeValue) plus an accurate fetchedAt for callers to compute
    // staleness themselves — per Phase 0, domain-specific TTL rules (e.g.
    // "valid only for today") belong to feature repositories, not this layer.
    func testRemoveValueExpiresEntry() async {
        let key = CacheKey(namespace: "test", identifier: "toExpire")
        await sut.save("stale candidate", for: key)
        let beforeRemoval = await sut.value(for: key, as: String.self)
        XCTAssertNotNil(beforeRemoval)

        await sut.removeValue(for: key)

        let afterRemoval = await sut.value(for: key, as: String.self)
        XCTAssertNil(afterRemoval)
    }

    func testOverwritingKeyReplacesPreviousValue() async {
        let key = CacheKey(namespace: "test", identifier: "overwrite")
        await sut.save("first", for: key)
        await sut.save("second", for: key)

        let result = await sut.value(for: key, as: String.self)
        XCTAssertEqual(result?.value, "second")
    }
}
