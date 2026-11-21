import Foundation

/// Muse's tunables, stored in the app's defaults domain (io.github.singhchinmayy.Muse).
public struct Settings: Equatable {
    public var enabled = true          // master switch: cursor movement and scroll blocking
    public var cursorEnabled = true
    public var cursorSpeed = 1.0
    public var cursorAccel = 1.0
    public var deadzone = 0.03         // normalized surface units before the cursor starts moving
    public var invertX = false
    public var invertY = false

    public init() {}

    public init(enabled: Bool, cursorEnabled: Bool, cursorSpeed: Double, cursorAccel: Double,
                deadzone: Double, invertX: Bool, invertY: Bool) {
        self.enabled = enabled; self.cursorEnabled = cursorEnabled
        self.cursorSpeed = cursorSpeed; self.cursorAccel = cursorAccel
        self.deadzone = deadzone; self.invertX = invertX; self.invertY = invertY
    }

    public static func load(from d: UserDefaults) -> Settings {
        Settings()
    }
}
