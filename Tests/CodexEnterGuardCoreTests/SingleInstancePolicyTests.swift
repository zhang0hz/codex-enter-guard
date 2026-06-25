import XCTest
@testable import CodexEnterGuardCore

final class SingleInstancePolicyTests: XCTestCase {
    func testAllowsFirstRunningInstance() {
        XCTAssertTrue(SingleInstancePolicy.shouldContinueLaunching(runningInstanceCountForBundleIdentifier: 1))
    }

    func testStopsSecondRunningInstance() {
        XCTAssertFalse(SingleInstancePolicy.shouldContinueLaunching(runningInstanceCountForBundleIdentifier: 2))
    }

    func testTreatsUnknownCountAsSafeToLaunch() {
        XCTAssertTrue(SingleInstancePolicy.shouldContinueLaunching(runningInstanceCountForBundleIdentifier: 0))
    }
}
