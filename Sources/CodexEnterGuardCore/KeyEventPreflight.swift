public enum KeyEventPreflight {
    public static func shouldReadFrontmostApplication(
        keyCode: UInt16,
        modifierFlags: KeyModifierFlags
    ) -> Bool {
        KeyCodes.isReturnOrEnter(keyCode) && !modifierFlags.containsBlockingModifier
    }
}

