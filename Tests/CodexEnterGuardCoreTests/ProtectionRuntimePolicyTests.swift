import XCTest
@testable import CodexEnterGuardCore

final class ProtectionRuntimePolicyTests: XCTestCase {
    func testPausingProtectionStopsListener() {
        XCTAssertEqual(
            ProtectionRuntimePolicy.listenerAction(
                protectionEnabled: false,
                listenerRunning: true,
                accessibilityGranted: true,
                inputMonitoringGranted: true
            ),
            .stop
        )
    }

    func testEnablingProtectionStartsListenerWhenPermissionsAreReady() {
        XCTAssertEqual(
            ProtectionRuntimePolicy.listenerAction(
                protectionEnabled: true,
                listenerRunning: false,
                accessibilityGranted: true,
                inputMonitoringGranted: true
            ),
            .start
        )
    }

    func testEnablingProtectionDoesNothingWhenPermissionsAreMissing() {
        XCTAssertEqual(
            ProtectionRuntimePolicy.listenerAction(
                protectionEnabled: true,
                listenerRunning: false,
                accessibilityGranted: true,
                inputMonitoringGranted: false
            ),
            .none
        )
    }
}

