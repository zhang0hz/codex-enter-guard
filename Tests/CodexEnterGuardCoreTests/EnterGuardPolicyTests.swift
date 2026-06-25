import XCTest
@testable import CodexEnterGuardCore

final class EnterGuardPolicyTests: XCTestCase {
    private let policy = EnterGuardPolicy(targetBundleIdentifier: "com.openai.codex")

    func testRewritesPlainReturnWhenCodexIsFrontmost() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: KeyCodes.returnOrEnter,
            modifierFlags: [],
            phase: .keyDown
        )

        XCTAssertTrue(policy.shouldRewriteToShiftReturn(event))
    }

    func testRewritesPlainKeypadEnterWhenCodexIsFrontmost() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: KeyCodes.keypadEnter,
            modifierFlags: [],
            phase: .keyDown
        )

        XCTAssertTrue(policy.shouldRewriteToShiftReturn(event))
    }

    func testDoesNotRewriteCommandReturnSoCodexCanSend() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: KeyCodes.returnOrEnter,
            modifierFlags: [.command],
            phase: .keyDown
        )

        XCTAssertFalse(policy.shouldRewriteToShiftReturn(event))
    }

    func testDoesNotRewriteShiftReturnToAvoidLoops() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: KeyCodes.returnOrEnter,
            modifierFlags: [.shift],
            phase: .keyDown
        )

        XCTAssertFalse(policy.shouldRewriteToShiftReturn(event))
    }

    func testDoesNotRewriteWhenAnotherAppIsFrontmost() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.apple.TextEdit",
            keyCode: KeyCodes.returnOrEnter,
            modifierFlags: [],
            phase: .keyDown
        )

        XCTAssertFalse(policy.shouldRewriteToShiftReturn(event))
    }

    func testDoesNotRewriteKeyUpEvents() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: KeyCodes.returnOrEnter,
            modifierFlags: [],
            phase: .keyUp
        )

        XCTAssertFalse(policy.shouldRewriteToShiftReturn(event))
    }

    func testDoesNotRewriteOtherKeys() {
        let event = KeyEventSnapshot(
            frontmostBundleIdentifier: "com.openai.codex",
            keyCode: 0,
            modifierFlags: [],
            phase: .keyDown
        )

        XCTAssertFalse(policy.shouldRewriteToShiftReturn(event))
    }
}
