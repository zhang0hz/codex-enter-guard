import XCTest

final class PackageScriptTests: XCTestCase {
    func testPackageScriptDocumentsReleaseBundleSteps() throws {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Scripts/package.sh")
        let script = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(script.contains("swift build -c release"))
        XCTAssertTrue(script.contains("Packaging/Info.plist"))
        XCTAssertTrue(script.contains("Contents/MacOS/CodexSendGuard"))
        XCTAssertTrue(script.contains("strip -x"))
        XCTAssertTrue(script.contains("ditto -c -k --keepParent"))
        XCTAssertTrue(script.contains("--norsrc"))
        XCTAssertTrue(script.contains("--noextattr"))
    }
}
