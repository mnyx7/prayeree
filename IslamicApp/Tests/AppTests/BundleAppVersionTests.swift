import XCTest
@testable import IslamicApp

final class BundleAppVersionTests: XCTestCase {
    func testFormattedVersionCombinesVersionAndBuild() {
        XCTAssertEqual(Bundle.formattedVersion(version: "1.2.0", build: "45"), "1.2.0 (45)")
    }

    func testFormattedVersionHandlesZeroBuild() {
        XCTAssertEqual(Bundle.formattedVersion(version: "1.0.0", build: "0"), "1.0.0 (0)")
    }

    func testTestBundleExposesNonEmptyVersionStrings() {
        let bundle = Bundle(for: BundleAppVersionTests.self)
        XCTAssertFalse(bundle.appVersionString.isEmpty)
        XCTAssertFalse(bundle.appBuildNumberString.isEmpty)
    }
}
