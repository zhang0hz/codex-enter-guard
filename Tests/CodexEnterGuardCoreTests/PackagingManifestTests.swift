import XCTest

final class PackagingManifestTests: XCTestCase {
    func testPackagingInfoPlistHasMenuBarIdentity() throws {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Packaging/Info.plist")
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["CFBundleDisplayName"] as? String, "Codex 防误发")
        XCTAssertEqual(plist["CFBundleIdentifier"] as? String, "local.codex-send-guard")
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, "CodexSendGuard")
        XCTAssertEqual(plist["LSUIElement"] as? Bool, true)
        XCTAssertNil(plist["NSAppleEventsUsageDescription"])
    }
}

