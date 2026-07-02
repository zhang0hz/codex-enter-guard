import XCTest
@testable import CodexEnterGuardCore

final class StartupStatusPresenterTests: XCTestCase {
    func testRunningListenerTakesPrecedenceOverStalePermissionPreflight() {
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

        let presentation = StartupStatusPresenter.presentation(for: status)

        XCTAssertEqual(presentation.title, "状态：已就绪")
        XCTAssertFalse(presentation.message.contains("状态：需要授权"))
    }

    func testShowsListenerFailureInsteadOfPermissionPromptWhenPermissionsAreGranted() {
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

        let presentation = StartupStatusPresenter.presentation(for: status)

        XCTAssertEqual(presentation.title, "状态：监听失败")
        XCTAssertTrue(presentation.message.contains("权限已开启"))
        XCTAssertTrue(presentation.message.contains("macOS 拒绝创建键盘监听"))
    }

    func testMissingPermissionMessageMentionsResetWhenSystemSettingsLookEnabled() {
        let status = GuardRuntimeStatus(
            accessibilityGranted: false,
            inputMonitoringGranted: false,
            listenerRunning: false,
            startAttemptCount: 4,
            observedKeyDownCount: 0,
            rewriteCount: 0,
            lastFrontmostBundleIdentifier: nil,
            lastObservedKeyCode: nil,
            lastFailure: .permissionsMissing(accessibilityGranted: false, inputMonitoringGranted: false)
        )

        let presentation = StartupStatusPresenter.presentation(for: status)

        XCTAssertTrue(presentation.message.contains("重置授权记录"))
    }
}
