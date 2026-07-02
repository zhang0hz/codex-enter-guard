public struct StartupStatusPresentation: Equatable, Sendable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

public enum StartupStatusPresenter {
    public static func presentation(for status: GuardRuntimeStatus) -> StartupStatusPresentation {
        let detail = GuardStatusFormatter.detailText(for: status)

        if status.listenerRunning {
            return StartupStatusPresentation(
                title: "状态：已就绪",
                message: "\(AppCopy.readyMessage)\n\n\(detail)"
            )
        }

        if status.accessibilityGranted && status.inputMonitoringGranted {
            let reason = status.lastFailure?.displayMessage ?? "键盘监听未开启"
            return StartupStatusPresentation(
                title: "状态：监听失败",
                message: "权限已开启，但键盘监听没有运行。\n\n原因：\(reason)\n\n\(detail)"
            )
        }

        return StartupStatusPresentation(
            title: "状态：需要授权",
            message: "\(AppCopy.permissionNoticeMessage)\n\n如果系统设置里已经打开，但这里仍显示需要授权，请点击“重置授权记录”，再退出并重新打开 App 后重新授权。\n\n\(detail)"
        )
    }
}
