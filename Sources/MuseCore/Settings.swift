import Foundation

public struct Settings: Equatable {
    public var enabled: Bool
    public var cursorEnabled: Bool
    public var cursorSpeed: Double
    public var cursorAccel: Double
    public var deadzone: Double
    public var invertX: Bool
    public var invertY: Bool

    public static func load(from d: UserDefaults) -> Settings {
        Settings(enabled: false, cursorEnabled: false, cursorSpeed: 0, cursorAccel: 0, deadzone: 0, invertX: false, invertY: false)
    }
}
