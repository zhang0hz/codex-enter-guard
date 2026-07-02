import AppKit
import ApplicationServices
import CodexEnterGuardCore

final class EventTapController: @unchecked Sendable {
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
    private var cachedFrontmostBundleIdentifier: String?
    private var frontmostApplicationObserver: NSObjectProtocol?

    init() {
        cachedFrontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        frontmostApplicationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.cachedFrontmostBundleIdentifier = application?.bundleIdentifier
        }
    }

    deinit {
        if let frontmostApplicationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(frontmostApplicationObserver)
        }
        stop()
    }

    @discardableResult
    func start() -> Bool {
        if eventTap != nil {
            refreshEffectiveListeningState()
            if isListening {
                return true
            }

            stop()
        }

        startAttemptCount += 1

        let accessibilityGranted = AXIsProcessTrusted()
        let inputMonitoringGranted = CGPreflightListenEventAccess()

        let mask = 1 << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            if KeyboardListenerPermissionPolicy.canAttemptListener(
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            ) {
                lastFailure = .eventTapCreationFailed(
                    accessibilityGranted: accessibilityGranted,
                    inputMonitoringGranted: inputMonitoringGranted
                )
            } else {
                lastFailure = .permissionsMissing(
                    accessibilityGranted: accessibilityGranted,
                    inputMonitoringGranted: inputMonitoringGranted
                )
            }

            isListening = false
            logger.write("键盘监听未启动：\(lastFailure?.displayMessage ?? "未知原因") 辅助功能=\(accessibilityGranted) 输入监控=\(inputMonitoringGranted)")
            return false
        }

        eventTap = tap
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            lastFailure = .eventTapCreationFailed(
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            )
            isListening = false
            CFMachPortInvalidate(tap)
            eventTap = nil
            logger.write("键盘监听未启动：无法创建 RunLoop Source")
            return false
        }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)

        CGEvent.tapEnable(tap: tap, enable: true)
        isListening = CGEvent.tapIsEnabled(tap: tap)
        lastFailure = nil
        logger.write("键盘监听已启动")
        return isListening
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
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
        refreshEffectiveListeningState()

        return GuardRuntimeStatus(
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
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                isListening = CGEvent.tapIsEnabled(tap: eventTap)
            }
            logger.write("键盘监听因超时被关闭，已尝试重新启用")
            return Unmanaged.passUnretained(event)
        }

        if type == .tapDisabledByUserInput {
            lastFailure = .eventTapDisabledByUserInput
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                isListening = CGEvent.tapIsEnabled(tap: eventTap)
            }
            logger.write("键盘监听在用户输入期间被关闭，已尝试重新启用")
            return Unmanaged.passUnretained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifierFlags = KeyModifierFlags(cgFlags: event.flags)

        guard KeyEventPreflight.shouldReadFrontmostApplication(
            keyCode: keyCode,
            modifierFlags: modifierFlags
        ) else {
            return Unmanaged.passUnretained(event)
        }

        observedKeyDownCount += 1

        let snapshot = KeyEventSnapshot(
            frontmostBundleIdentifier: cachedFrontmostBundleIdentifier,
            keyCode: keyCode,
            modifierFlags: modifierFlags,
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

    private func refreshEffectiveListeningState() {
        guard let eventTap else {
            isListening = false
            return
        }

        isListening = CGEvent.tapIsEnabled(tap: eventTap)
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

        if cgFlags.contains(.maskSecondaryFn) {
            flags.insert(.function)
        }

        if cgFlags.contains(.maskNumericPad) {
            flags.insert(.numericPad)
        }

        self = flags
    }
}
