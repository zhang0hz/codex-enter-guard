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

    func testCanStartWhenBothPermissionsAreGranted() {
        XCTAssertTrue(
            KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: true,
                inputMonitoringGranted: true
            )
        )
    }
}
