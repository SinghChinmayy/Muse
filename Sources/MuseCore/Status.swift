public struct Status: Equatable {
    public var trusted: Bool
    public var mouseConnected: Bool
    public var enabled: Bool

    public init(trusted: Bool, mouseConnected: Bool, enabled: Bool) {
        self.trusted = trusted; self.mouseConnected = mouseConnected; self.enabled = enabled
    }

    public var title: String { "" }
    public var opensAccessibilitySettings: Bool { false }
}
