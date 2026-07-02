public struct PermissionResetCommandSpec: Equatable, Sendable {
    public let executablePath: String
    public let arguments: [String]

    public init(executablePath: String, arguments: [String]) {
        self.executablePath = executablePath
        self.arguments = arguments
    }
}

public enum PermissionResetCommand {
    public static func commands(bundleIdentifier: String) -> [PermissionResetCommandSpec] {
        [
            PermissionResetCommandSpec(
                executablePath: "/usr/bin/tccutil",
                arguments: ["reset", "Accessibility", bundleIdentifier]
            ),
            PermissionResetCommandSpec(
                executablePath: "/usr/bin/tccutil",
                arguments: ["reset", "ListenEvent", bundleIdentifier]
            ),
        ]
    }
}
