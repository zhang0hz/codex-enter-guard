public enum AppCopy {
    public static let displayName = "Codex 防误发"

    public static let permissionNoticeMessage =
        "Codex 防误发正在运行。\n\n要把 Codex 里的普通回车键改成换行，macOS 需要授予“输入监控”和“辅助功能”权限。"

    public static let readyMessage =
        "已就绪。在 Codex 中，回车键会换行，Command + 回车键会发送。"

    public static func statusTitle(isEnabled: Bool) -> String {
        isEnabled ? "⌘↵" : "⌘↵ 暂停"
    }
}
