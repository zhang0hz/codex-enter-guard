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
        eventTapController.start()
        startStatusRefreshTimer()

        if !AXIsProcessTrusted() || !CGPreflightListenEventAccess() {
            showStartupWindow()
            requestPermissions()
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
        eventTapController.isEnabled = enabled

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
        startupWindowController?.update(status: eventTapController.runtimeStatus())
    }

    private func startStatusRefreshTimer() {
        statusRefreshTimer?.invalidate()
        statusRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusWindow()
            }
        }
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        refreshMenu()
    }

    @objc private func requestPermissions() {
        let promptKey = "AXTrustedCheckOptionPrompt"
        AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        CGRequestListenEventAccess()
        eventTapController.start()
        refreshMenu()
    }

    @objc private func openAccessibilitySettings() {
        openPrivacySettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    @objc private func openInputMonitoringSettings() {
        openPrivacySettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
