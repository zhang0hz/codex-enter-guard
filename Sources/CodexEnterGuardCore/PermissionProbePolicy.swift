public enum PermissionProbePolicy {
    public static func shouldProbeListener(
        remainingProbeAttempts: Int,
        protectionEnabled: Bool,
        listenerRunning: Bool
    ) -> Bool {
        remainingProbeAttempts > 0 && protectionEnabled && !listenerRunning
    }
}
