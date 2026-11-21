/// What the menu bar shows about Muse's state.
public struct Status: Equatable {
    public var trusted: Bool
    public var mouseConnected: Bool
    public var enabled: Bool

    public init(trusted: Bool, mouseConnected: Bool, enabled: Bool) {
        self.trusted = trusted; self.mouseConnected = mouseConnected; self.enabled = enabled
    }

    /// Status line at the top of the menu. A missing permission matters most, so it wins.
    public var title: String {
        if !trusted { return "Needs Accessibility Permission" }
        return mouseConnected ? "Magic Mouse Connected" : "No Magic Mouse Found"
    }

    /// Clicking the status line opens Privacy & Security > Accessibility.
    public var opensAccessibilitySettings: Bool { !trusted }
}
