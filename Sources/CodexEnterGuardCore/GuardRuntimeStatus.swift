public enum GuardStartFailure: Equatable, Sendable {
    case permissionsMissing(accessibilityGranted: Bool, inputMonitoringGranted: Bool)
    case eventTapCreationFailed(accessibilityGranted: Bool, inputMonitoringGranted: Bool)
    case eventTapDisabledByTimeout
    case eventTapDisabledByUserInput

    public var displayMessage: String {
        switch self {
        case .permissionsMissing:
            return "缺少 macOS 权限"
        case .eventTapCreationFailed:
            return "macOS 拒绝创建键盘监听"
        case .eventTapDisabledByTimeout:
            return "macOS 因超时关闭了键盘监听"
        case .eventTapDisabledByUserInput:
            return "macOS 在用户输入期间关闭了键盘监听"
        }
    }
}

public struct GuardRuntimeStatus: Equatable, Sendable {
    public let accessibilityGranted: Bool
    public let inputMonitoringGranted: Bool
    public let listenerRunning: Bool
    public let startAttemptCount: Int
    public let observedKeyDownCount: Int
    public let rewriteCount: Int
    public let lastFrontmostBundleIdentifier: String?
    public let lastObservedKeyCode: UInt16?
    public let lastFailure: GuardStartFailure?

    public init(
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool,
        listenerRunning: Bool,
        startAttemptCount: Int,
        observedKeyDownCount: Int,
        rewriteCount: Int,
        lastFrontmostBundleIdentifier: String?,
        lastObservedKeyCode: UInt16?,
        lastFailure: GuardStartFailure?
    ) {
        self.accessibilityGranted = accessibilityGranted
        self.inputMonitoringGranted = inputMonitoringGranted
        self.listenerRunning = listenerRunning
        self.startAttemptCount = startAttemptCount
        self.observedKeyDownCount = observedKeyDownCount
        self.rewriteCount = rewriteCount
        self.lastFrontmostBundleIdentifier = lastFrontmostBundleIdentifier
        self.lastObservedKeyCode = lastObservedKeyCode
        self.lastFailure = lastFailure
    }
}

public enum GuardStatusFormatter {
    public static func detailText(for status: GuardRuntimeStatus) -> String {
        var lines = [
            "辅助功能：\(status.accessibilityGranted ? "已开启" : "需要授权")",
            "输入监控：\(status.inputMonitoringGranted ? "已开启" : "需要授权")",
            "键盘监听：\(status.listenerRunning ? "开启" : "关闭")",
            "启动尝试：\(status.startAttemptCount)",
            "已看到按键：\(status.observedKeyDownCount)",
            "已改写回车：\(status.rewriteCount)",
        ]

        if let lastFrontmostBundleIdentifier = status.lastFrontmostBundleIdentifier {
            lines.append("最近前台应用：\(lastFrontmostBundleIdentifier)")
        } else {
            lines.append("最近前台应用：暂无")
        }

        if let lastObservedKeyCode = status.lastObservedKeyCode {
            lines.append("最近按键码：\(lastObservedKeyCode)")
        } else {
            lines.append("最近按键码：暂无")
        }

        if let lastFailure = status.lastFailure {
            lines.append("原因：\(lastFailure.displayMessage)")
        }

        return lines.joined(separator: "\n")
    }
}
