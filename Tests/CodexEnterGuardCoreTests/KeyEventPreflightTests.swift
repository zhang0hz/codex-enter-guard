import XCTest
@testable import CodexEnterGuardCore

final class KeyEventPreflightTests: XCTestCase {
    func testIgnoresNonReturnKeysBeforeReadingFrontmostApplication() {
        XCTAssertFalse(
            KeyEventPreflight.shouldReadFrontmostApplication(
                keyCode: 0,
                modifierFlags: []
            )
        )
    }

    func testReadsFrontmostApplicationForPlainReturn() {
        XCTAssertTrue(
            KeyEventPreflight.shouldReadFrontmostApplication(
                keyCode: KeyCodes.returnOrEnter,
                modifierFlags: []
            )
        )
    }

    func testDoesNotReadFrontmostApplicationForCommandReturn() {
        XCTAssertFalse(
            KeyEventPreflight.shouldReadFrontmostApplication(
                keyCode: KeyCodes.returnOrEnter,
                modifierFlags: [.command]
            )
        )
    }
}

