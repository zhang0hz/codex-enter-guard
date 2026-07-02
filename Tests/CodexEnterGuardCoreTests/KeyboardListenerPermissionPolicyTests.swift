import XCTest
@testable import CodexEnterGuardCore

final class KeyboardListenerPermissionPolicyTests: XCTestCase {
    func testCannotStartWhenInputMonitoringIsGrantedWithoutAccessibility() {
        XCTAssertFalse(
            KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: false,
                inputMonitoringGranted: true
            )
        )
    }

    func testCannotStartWithoutInputMonitoring() {
        XCTAssertFalse(
            KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: true,
                inputMonitoringGranted: false
            )
        )
    }

    func testCannotStartWhenBothPermissionsAreMissing() {
        XCTAssertFalse(
            KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: false,
                inputMonitoringGranted: false
            )
        )
    }

    func testCanStartWhenBothPermissionsAreGranted() {
        XCTAssertTrue(
            KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
    }

    func testAutoStartsWhenPermissionsBecomeReadyAndListenerIsStopped() {
        XCTAssertTrue(
            KeyboardListenerPermissionPolicy.shouldAutoStartListener(
                accessibilityGranted: true,
                inputMonitoringGranted: true,
                listenerRunning: false,
                protectionEnabled: true
            )
        )
    }

    func testDoesNotAutoStartWhenProtectionIsPaused() {
        XCTAssertFalse(
            KeyboardListenerPermissionPolicy.shouldAutoStartListener(
                accessibilityGranted: true,
                inputMonitoringGranted: true,
                listenerRunning: false,
                protectionEnabled: false
            )
        )
    }
}
