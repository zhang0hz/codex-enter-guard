import XCTest
@testable import CodexEnterGuardCore

final class PermissionProbePolicyTests: XCTestCase {
    func testProbesWhileProtectionIsEnabledAndListenerIsStopped() {
        XCTAssertTrue(
            PermissionProbePolicy.shouldProbeListener(
                remainingProbeAttempts: 3,
                protectionEnabled: true,
                listenerRunning: false
            )
        )
    }

    func testDoesNotProbeWhenAttemptsAreExhausted() {
        XCTAssertFalse(
            PermissionProbePolicy.shouldProbeListener(
                remainingProbeAttempts: 0,
                protectionEnabled: true,
                listenerRunning: false
            )
        )
    }

    func testDoesNotProbeWhenProtectionIsPaused() {
        XCTAssertFalse(
            PermissionProbePolicy.shouldProbeListener(
                remainingProbeAttempts: 3,
                protectionEnabled: false,
                listenerRunning: false
            )
        )
    }

    func testDoesNotProbeWhenListenerIsAlreadyRunning() {
        XCTAssertFalse(
            PermissionProbePolicy.shouldProbeListener(
                remainingProbeAttempts: 3,
                protectionEnabled: true,
                listenerRunning: true
            )
        )
    }
}
