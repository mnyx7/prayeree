import Foundation

extension Bundle {
    var appVersionString: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    var appBuildNumberString: String {
        (infoDictionary?["CFBundleVersion"] as? String) ?? "0"
    }

    var formattedAppVersion: String {
        Bundle.formattedVersion(version: appVersionString, build: appBuildNumberString)
    }

    // Extracted as a pure static function so formatting logic is testable
    // without depending on a real bundle's Info.plist contents.
    static func formattedVersion(version: String, build: String) -> String {
        "\(version) (\(build))"
    }
}
