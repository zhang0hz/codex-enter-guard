public enum ListenerRuntimeAction: Equatable, Sendable {
    case none
    case start
    case stop
}

public enum ProtectionRuntimePolicy {
    public static func listenerAction(
        protectionEnabled: Bool,
        listenerRunning: Bool,
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool
    ) -> ListenerRuntimeAction {
        if !protectionEnabled {
            return listenerRunning ? .stop : .none
        }

        if KeyboardListenerPermissionPolicy.shouldAutoStartListener(
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            listenerRunning: listenerRunning,
            protectionEnabled: protectionEnabled
        ) {
            return .start
        }

        return .none
    }
}

