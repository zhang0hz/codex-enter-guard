public enum SingleInstancePolicy {
    public static func shouldContinueLaunching(runningInstanceCountForBundleIdentifier count: Int) -> Bool {
        count <= 1
    }
}
