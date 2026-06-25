import AppKit
import CodexEnterGuardCore

@MainActor
final class StartupWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")

    var onRequestPermissions: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?
    var onOpenInputMonitoringSettings: (() -> Void)?
    var onRefresh: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppCopy.displayName
        window.center()
        super.init(window: window)
        window.contentView = buildContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(status: GuardRuntimeStatus) {
        if status.accessibilityGranted && status.inputMonitoringGranted && status.listenerRunning {
            statusLabel.stringValue = "状态：已就绪"
            detailLabel.stringValue =
                "\(AppCopy.readyMessage)\n\n" +
                GuardStatusFormatter.detailText(for: status)
        } else {
            statusLabel.stringValue = "状态：需要授权"
            detailLabel.stringValue =
                "\(AppCopy.permissionNoticeMessage)\n\n" +
                GuardStatusFormatter.detailText(for: status)
        }
    }

    private func buildContentView() -> NSView {
        let title = NSTextField(labelWithString: AppCopy.displayName)
        title.font = .boldSystemFont(ofSize: 22)

        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor

        let requestButton = NSButton(title: "请求权限", target: self, action: #selector(requestPermissions))
        let accessibilityButton = NSButton(title: "打开辅助功能设置", target: self, action: #selector(openAccessibilitySettings))
        let inputButton = NSButton(title: "打开输入监控设置", target: self, action: #selector(openInputMonitoringSettings))
        let refreshButton = NSButton(title: "刷新状态", target: self, action: #selector(refreshStatus))
        let quitButton = NSButton(title: "退出", target: self, action: #selector(quit))

        let firstButtonRow = NSStackView(views: [requestButton, refreshButton, quitButton])
        firstButtonRow.orientation = .horizontal
        firstButtonRow.alignment = .centerY
        firstButtonRow.spacing = 10

        let secondButtonRow = NSStackView(views: [accessibilityButton, inputButton])
        secondButtonRow.orientation = .horizontal
        secondButtonRow.alignment = .centerY
        secondButtonRow.spacing = 10

        let buttonRow = NSStackView(views: [firstButtonRow, secondButtonRow])
        buttonRow.orientation = .vertical
        buttonRow.alignment = .leading
        buttonRow.spacing = 10

        let stack = NSStackView(views: [title, statusLabel, detailLabel, buttonRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24),
            detailLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])

        return container
    }

    @objc private func requestPermissions() {
        onRequestPermissions?()
    }

    @objc private func openAccessibilitySettings() {
        onOpenAccessibilitySettings?()
    }

    @objc private func openInputMonitoringSettings() {
        onOpenInputMonitoringSettings?()
    }

    @objc private func refreshStatus() {
        onRefresh?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
