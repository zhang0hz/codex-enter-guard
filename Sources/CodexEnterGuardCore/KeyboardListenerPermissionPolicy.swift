public enum KeyboardListenerPermissionPolicy {
    public static func canAttemptListener(
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool
    ) -> Bool {
        accessibilityGranted && inputMonitoringGranted
    }

    public static func shouldAutoStartListener(
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool,
        listenerRunning: Bool,
        protectionEnabled: Bool
    ) -> Bool {
        protectionEnabled &&
            !listenerRunning &&
            canAttemptListener(
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            )
    }
}
