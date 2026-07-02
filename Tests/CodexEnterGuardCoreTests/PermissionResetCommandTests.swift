import XCTest
@testable import CodexEnterGuardCore

final class PermissionResetCommandTests: XCTestCase {
    func testResetCommandsUseMacOSPrivacyServicesForThisApp() {
        let commands = PermissionResetCommand.commands(bundleIdentifier: "local.codex-send-guard")

        XCTAssertEqual(commands.count, 2)
        XCTAssertEqual(commands[0].executablePath, "/usr/bin/tccutil")
        XCTAssertEqual(commands[0].arguments, ["reset", "Accessibility", "local.codex-send-guard"])
        XCTAssertEqual(commands[1].executablePath, "/usr/bin/tccutil")
        XCTAssertEqual(commands[1].arguments, ["reset", "ListenEvent", "local.codex-send-guard"])
    }
}
