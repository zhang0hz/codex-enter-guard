import XCTest
@testable import CodexEnterGuardCore

final class GuardStatusFormatterTests: XCTestCase {
    func testExplainsMissingPermissions() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: true,
            listenerRunning: false,
            startAttemptCount: 1,
            observedKeyDownCount: 0,
            rewriteCount: 0,
            lastFrontmostBundleIdentifier: nil,
            lastObservedKeyCode: nil,
            lastFailure: .permissionsMissing(accessibilityGranted: false, inputMonitoringGranted: true)
        )

        let text = GuardStatusFormatter.detailText(for: status)

        XCTAssertTrue(text.contains("辅助功能：需要授权"))
        XCTAssertTrue(text.contains("输入监控：已开启"))
        XCTAssertTrue(text.contains("原因：缺少 macOS 权限"))
    }

    func testExplainsEventTapCreationFailure() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            listenerRunning: false,
            startAttemptCount: 2,
            observedKeyDownCount: 0,
            rewriteCount: 0,
            lastFrontmostBundleIdentifier: nil,
            lastObservedKeyCode: nil,
            lastFailure: .eventTapCreationFailed(accessibilityGranted: true, inputMonitoringGranted: true)
        )

        let text = GuardStatusFormatter.detailText(for: status)

        XCTAssertTrue(text.contains("键盘监听：关闭"))
        XCTAssertTrue(text.contains("原因：macOS 拒绝创建键盘监听"))
        XCTAssertTrue(text.contains("启动尝试：2"))
    }

    func testShowsRuntimeActivityWhenEventsAreSeen() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            listenerRunning: true,
            startAttemptCount: 1,
            observedKeyDownCount: 12,
            rewriteCount: 3,
            lastFrontmostBundleIdentifier: "com.openai.codex",
            lastObservedKeyCode: 36,
            lastFailure: nil
        )

        let text = GuardStatusFormatter.detailText(for: status)

        XCTAssertTrue(text.contains("键盘监听：开启"))
        XCTAssertTrue(text.contains("已看到按键：12"))
        XCTAssertTrue(text.contains("已改写回车：3"))
        XCTAssertTrue(text.contains("最近前台应用：com.openai.codex"))
        XCTAssertTrue(text.contains("最近按键码：36"))
    }

    func testShowsBothPermissionStatesWhenListenerRuns() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            listenerRunning: true,
            startAttemptCount: 1,
            observedKeyDownCount: 0,
            rewriteCount: 0,
            lastFrontmostBundleIdentifier: nil,
            lastObservedKeyCode: nil,
            lastFailure: nil
        )

        let text = GuardStatusFormatter.detailText(for: status)

        XCTAssertTrue(text.contains("辅助功能：已开启"))
        XCTAssertTrue(text.contains("输入监控：已开启"))
        XCTAssertTrue(text.contains("键盘监听：开启"))
    }

    func testShowsOperationalPermissionWhenListenerRunsDespiteStalePreflight() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: false,
            listenerRunning: true,
            startAttemptCount: 3,
            observedKeyDownCount: 1,
            rewriteCount: 0,
            lastFrontmostBundleIdentifier: "com.openai.codex",
            lastObservedKeyCode: 36,
            lastFailure: nil
        )

        let text = GuardStatusFormatter.detailText(for: status)

        XCTAssertTrue(text.contains("辅助功能：已通过监听验证"))
        XCTAssertTrue(text.contains("输入监控：已通过监听验证"))
        XCTAssertTrue(text.contains("键盘监听：开启"))
    }
}
