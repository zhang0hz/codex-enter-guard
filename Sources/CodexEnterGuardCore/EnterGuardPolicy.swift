public enum KeyEventPhase: Equatable {
    case keyDown
    case keyUp
}

public struct KeyModifierFlags: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shift = KeyModifierFlags(rawValue: 1 << 0)
    public static let control = KeyModifierFlags(rawValue: 1 << 1)
    public static let option = KeyModifierFlags(rawValue: 1 << 2)
    public static let command = KeyModifierFlags(rawValue: 1 << 3)
    public static let function = KeyModifierFlags(rawValue: 1 << 4)
    public static let numericPad = KeyModifierFlags(rawValue: 1 << 5)

    public var containsAnyModifier: Bool {
        !isEmpty
    }

    public var containsBlockingModifier: Bool {
        !intersection([.shift, .control, .option, .command, .function]).isEmpty
    }
}

public enum KeyCodes {
    public static let returnOrEnter: UInt16 = 36
    public static let keypadEnter: UInt16 = 76

    public static func isReturnOrEnter(_ keyCode: UInt16) -> Bool {
        keyCode == returnOrEnter || keyCode == keypadEnter
    }
}

public struct KeyEventSnapshot: Equatable {
    public let frontmostBundleIdentifier: String?
    public let keyCode: UInt16
    public let modifierFlags: KeyModifierFlags
    public let phase: KeyEventPhase

    public init(
        frontmostBundleIdentifier: String?,
        keyCode: UInt16,
        modifierFlags: KeyModifierFlags,
        phase: KeyEventPhase
    ) {
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.phase = phase
    }
}

public struct EnterGuardPolicy: Sendable {
    private let targetBundleIdentifier: String

    public init(targetBundleIdentifier: String) {
        self.targetBundleIdentifier = targetBundleIdentifier
    }

    public func shouldRewriteToShiftReturn(_ event: KeyEventSnapshot) -> Bool {
        guard event.phase == .keyDown else {
            return false
        }

        guard event.frontmostBundleIdentifier == targetBundleIdentifier else {
            return false
        }

        guard event.keyCode == KeyCodes.returnOrEnter || event.keyCode == KeyCodes.keypadEnter else {
            return false
        }

        return !event.modifierFlags.containsBlockingModifier
    }
}
