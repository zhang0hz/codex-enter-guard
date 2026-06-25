import XCTest
@testable import CodexEnterGuardCore

final class AppCopyTests: XCTestCase {
    func testDisplayNameUsesClearPurposeDrivenName() {
        XCTAssertEqual(AppCopy.displayName, "Codex 防误发")
    }

    func testStatusTitleIsVisibleWhenEnabled() {
        XCTAssertEqual(AppCopy.statusTitle(isEnabled: true), "⌘↵")
    }

    func testStatusTitleShowsPausedState() {
        XCTAssertEqual(AppCopy.statusTitle(isEnabled: false), "⌘↵ 暂停")
    }

    func testStartupPermissionMessageExplainsWhereTheAppIs() {
        XCTAssertTrue(AppCopy.permissionNoticeMessage.contains("Codex 防误发"))
        XCTAssertTrue(AppCopy.permissionNoticeMessage.contains("辅助功能"))
        XCTAssertTrue(AppCopy.permissionNoticeMessage.contains("输入监控"))
    }

    func testReadyMessageExplainsCodexSendBehavior() {
        XCTAssertTrue(AppCopy.readyMessage.contains("回车键"))
        XCTAssertTrue(AppCopy.readyMessage.contains("Command + 回车键"))
    }
}
