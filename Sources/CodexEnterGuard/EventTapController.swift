import AppKit
import ApplicationServices
import CodexEnterGuardCore

final class EventTapController {
    var isEnabled = true
    private(set) var isListening = false
    private(set) var startAttemptCount = 0
    private(set) var observedKeyDownCount = 0
    private(set) var rewriteCount = 0
    private(set) var lastFrontmostBundleIdentifier: String?
    private(set) var lastObservedKeyCode: UInt16?
    private(set) var lastFailure: GuardStartFailure?

    private let policy = EnterGuardPolicy(targetBundleIdentifier: "com.openai.codex")
    private let logger = DiagnosticLogger.shared
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else {
            return isListening
        }

        startAttemptCount += 1

        let accessibilityGranted = AXIsProcessTrusted()
        let inputMonitoringGranted = CGPreflightListenEventAccess()

        guard KeyboardListenerPermissionPolicy.canAttemptListener(
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted
        ) else {
            lastFailure = .permissionsMissing(
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            )
            isListening = false
            logger.write("键盘监听未启动：\(lastFailure?.displayMessage ?? "未知原因") 辅助功能=\(accessibilityGranted) 输入监控=\(inputMonitoringGranted)")
            return false
        }

        let mask = 1 << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            lastFailure = .eventTapCreationFailed(
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            )
            isListening = false
            logger.write("键盘监听未启动：\(lastFailure?.displayMessage ?? "未知原因") 辅助功能=\(accessibilityGranted) 输入监控=\(inputMonitoringGranted)")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        isListening = true
        lastFailure = nil
        logger.write("键盘监听已启动")
        return true
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        isListening = false
        logger.write("键盘监听已停止")
    }

    func runtimeStatus() -> GuardRuntimeStatus {
        GuardRuntimeStatus(
            accessibilityGranted: AXIsProcessTrusted(),
            inputMonitoringGranted: CGPreflightListenEventAccess(),
            listenerRunning: isListening,
            startAttemptCount: startAttemptCount,
            observedKeyDownCount: observedKeyDownCount,
            rewriteCount: rewriteCount,
            lastFrontmostBundleIdentifier: lastFrontmostBundleIdentifier,
            lastObservedKeyCode: lastObservedKeyCode,
            lastFailure: lastFailure
        )
    }

    fileprivate func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout {
            lastFailure = .eventTapDisabledByTimeout
            logger.write("键盘监听因超时被关闭，正在尝试重新启用")
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .tapDisabledByUserInput {
            lastFailure = .eventTapDisabledByUserInput
            logger.write("键盘监听在用户输入期间被关闭，正在尝试重新启用")
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        observedKeyDownCount += 1

        let snapshot = KeyEventSnapshot(
            frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
            modifierFlags: KeyModifierFlags(cgFlags: event.flags),
            phase: .keyDown
        )

        lastFrontmostBundleIdentifier = snapshot.frontmostBundleIdentifier
        lastObservedKeyCode = snapshot.keyCode

        guard policy.shouldRewriteToShiftReturn(snapshot) else {
            return Unmanaged.passUnretained(event)
        }

        rewriteCount += 1
        logger.write("已改写回车 keyCode=\(snapshot.keyCode) 前台应用=\(snapshot.frontmostBundleIdentifier ?? "无")")
        event.flags.insert(.maskShift)
        return Unmanaged.passUnretained(event)
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
    return controller.handle(proxy: proxy, type: type, event: event)
}

private extension KeyModifierFlags {
    init(cgFlags: CGEventFlags) {
        var flags: KeyModifierFlags = []

        if cgFlags.contains(.maskShift) {
            flags.insert(.shift)
        }

        if cgFlags.contains(.maskControl) {
            flags.insert(.control)
        }

        if cgFlags.contains(.maskAlternate) {
            flags.insert(.option)
        }

        if cgFlags.contains(.maskCommand) {
            flags.insert(.command)
        }

        self = flags
    }
}
