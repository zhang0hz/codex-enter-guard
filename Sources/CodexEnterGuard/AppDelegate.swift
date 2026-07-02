import AppKit
import ApplicationServices
import CodexEnterGuardCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let eventTapController = EventTapController()
    private var enabled = true
    private var startupWindowController: StartupWindowController?
    private var statusRefreshTimer: Timer?
    private var permissionProbeAttemptsRemaining = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        DiagnosticLogger.shared.write("应用已启动")

        guard shouldContinueLaunching() else {
            DiagnosticLogger.shared.write("检测到已有实例，当前实例退出")
            NSApp.terminate(nil)
            return
        }

        configureStatusItem()
        refreshMenu()
        let didStart = eventTapController.start()
        startStatusRefreshTimer()

        if !didStart {
            showStartupWindow()
            if !AXIsProcessTrusted() || !CGPreflightListenEventAccess() {
                requestPermissions()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusRefreshTimer?.invalidate()
        eventTapController.stop()
        DiagnosticLogger.shared.write("应用已退出")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showStatusWindow()
        return true
    }

    private func configureStatusItem() {
        statusItem.button?.title = AppCopy.statusTitle(isEnabled: enabled)
        statusItem.button?.toolTip = AppCopy.displayName
    }

    private func refreshMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: AppCopy.displayName, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let toggleTitle = enabled ? "暂停保护" : "启用保护"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let showWindowItem = NSMenuItem(title: "显示状态窗口", action: #selector(showStatusWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        let listenerItem = NSMenuItem(title: listenerSummary(), action: nil, keyEquivalent: "")
        listenerItem.isEnabled = false
        menu.addItem(listenerItem)

        menu.addItem(NSMenuItem.separator())

        let permissionsItem = NSMenuItem(title: permissionSummary(), action: nil, keyEquivalent: "")
        permissionsItem.isEnabled = false
        menu.addItem(permissionsItem)

        let requestItem = NSMenuItem(title: "请求权限", action: #selector(requestPermissions), keyEquivalent: "")
        requestItem.target = self
        menu.addItem(requestItem)

        let accessibilityItem = NSMenuItem(title: "打开辅助功能设置", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        let inputMonitoringItem = NSMenuItem(title: "打开输入监控设置", action: #selector(openInputMonitoringSettings), keyEquivalent: "")
        inputMonitoringItem.target = self
        menu.addItem(inputMonitoringItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: loginItemTitle(), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.title = AppCopy.statusTitle(isEnabled: enabled)
        updateStatusWindow()
    }

    private func shouldContinueLaunching() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

        let count = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).count
        return SingleInstancePolicy.shouldContinueLaunching(runningInstanceCountForBundleIdentifier: count)
    }

    private func permissionSummary() -> String {
        let accessibility = AXIsProcessTrusted() ? "辅助功能：已开启" : "辅助功能：需要授权"
        let inputMonitoring = CGPreflightListenEventAccess() ? "输入监控：已开启" : "输入监控：需要授权"
        return "\(accessibility), \(inputMonitoring)"
    }

    private func listenerSummary() -> String {
        eventTapController.isListening ? "键盘监听：开启" : "键盘监听：关闭"
    }

    private func updateStatusWindow() {
        synchronizeListenerWithCurrentState()
        startupWindowController?.update(status: eventTapController.runtimeStatus())
    }

    private func synchronizeListenerWithCurrentState() {
        let status = eventTapController.runtimeStatus()

        if PermissionProbePolicy.shouldProbeListener(
            remainingProbeAttempts: permissionProbeAttemptsRemaining,
            protectionEnabled: enabled,
            listenerRunning: status.listenerRunning
        ) {
            permissionProbeAttemptsRemaining -= 1
            _ = eventTapController.start()
            return
        }

        switch ProtectionRuntimePolicy.listenerAction(
            protectionEnabled: enabled,
            listenerRunning: status.listenerRunning,
            accessibilityGranted: status.accessibilityGranted,
            inputMonitoringGranted: status.inputMonitoringGranted
        ) {
        case .start:
            _ = eventTapController.start()
        case .stop:
            eventTapController.stop()
        case .none:
            break
        }
    }

    private func startStatusRefreshTimer() {
        statusRefreshTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusWindow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        statusRefreshTimer = timer
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        synchronizeListenerWithCurrentState()
        refreshMenu()
    }

    @objc private func requestPermissions() {
        let promptKey = "AXTrustedCheckOptionPrompt"
        AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        CGRequestListenEventAccess()
        startPermissionProbeWindow()
        eventTapController.start()
        refreshMenu()
    }

    @objc private func openAccessibilitySettings() {
        startPermissionProbeWindow()
        openPrivacySettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    @objc private func openInputMonitoringSettings() {
        startPermissionProbeWindow()
        openPrivacySettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private func startPermissionProbeWindow() {
        permissionProbeAttemptsRemaining = 30
    }

    private func openPrivacySettings(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func showStartupWindow() {
        let controller = StartupWindowController()
        controller.onRequestPermissions = { [weak self] in
            self?.requestPermissions()
        }
        controller.onOpenAccessibilitySettings = { [weak self] in
            self?.openAccessibilitySettings()
        }
        controller.onOpenInputMonitoringSettings = { [weak self] in
            self?.openInputMonitoringSettings()
        }
        controller.onResetPermissions = { [weak self] in
            self?.resetPermissions()
        }
        controller.onRefresh = { [weak self] in
            self?.eventTapController.start()
            self?.refreshMenu()
        }
        controller.onQuit = {
            NSApp.terminate(nil)
        }
        startupWindowController = controller
        refreshMenu()
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showStatusWindow() {
        if startupWindowController == nil {
            showStartupWindow()
            return
        }

        refreshMenu()
        startupWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func loginItemTitle() -> String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "开机启动：已开启"
        default:
            return "开机启动：关闭"
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showError("无法更新开机启动设置。\n\n\(error.localizedDescription)")
        }

        refreshMenu()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = AppCopy.displayName
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func showInfo(_ message: String) {
        let alert = NSAlert()
        alert.messageText = AppCopy.displayName
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func resetPermissions() {
        let alert = NSAlert()
        alert.messageText = "重置授权记录？"
        alert.informativeText = "这会清除本工具在 macOS 里的“辅助功能”和“输入监控”授权记录。适合系统设置里已经打开，但本工具仍显示需要授权的情况。\n\n重置后需要退出并重新打开 App，再重新授予这两个权限。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try runPermissionResetCommands()
            showInfo("授权记录已重置。\n\n请退出并重新打开 Codex 防误发，然后重新打开“辅助功能”和“输入监控”权限。")
            refreshMenu()
        } catch {
            showError("无法重置授权记录。\n\n\(error.localizedDescription)")
        }
    }

    private func runPermissionResetCommands() throws {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "local.codex-send-guard"

        for command in PermissionResetCommand.commands(bundleIdentifier: bundleIdentifier) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command.executablePath)
            process.arguments = command.arguments
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw PermissionResetError.commandFailed(command.arguments.joined(separator: " "))
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private enum PermissionResetError: LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command):
            return "tccutil 执行失败：\(command)"
        }
    }
}
