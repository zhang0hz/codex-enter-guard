public enum KeyboardListenerPermissionPolicy {
    public static func canAttemptListener(
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool
    ) -> Bool {
        accessibilityGranted && inputMonitoringGranted
    }
}
