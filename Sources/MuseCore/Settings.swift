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
        var s = Settings()
        // bool(forKey:)/double(forKey:) also parse strings, which `defaults write` stores without -bool/-float.
        func b(_ k: String, _ v: inout Bool) { if d.object(forKey: k) != nil { v = d.bool(forKey: k) } }
        func n(_ k: String, _ v: inout Double) { if d.object(forKey: k) != nil { v = d.double(forKey: k) } }
        b("enabled", &s.enabled); b("cursorEnabled", &s.cursorEnabled)
        n("cursorSpeed", &s.cursorSpeed); n("cursorAccel", &s.cursorAccel); n("deadzone", &s.deadzone)
        b("invertX", &s.invertX); b("invertY", &s.invertY)
        return s
    }

    /// Writes only values that differ from the factory default, so `defaults read` shows what you changed.
    public func save(to d: UserDefaults) {
        let f = Settings()
        func put<T: Equatable>(_ k: String, _ v: T, _ dv: T) { v == dv ? d.removeObject(forKey: k) : d.set(v, forKey: k) }
        put("enabled", enabled, f.enabled); put("cursorEnabled", cursorEnabled, f.cursorEnabled)
        put("cursorSpeed", cursorSpeed, f.cursorSpeed); put("cursorAccel", cursorAccel, f.cursorAccel)
        put("deadzone", deadzone, f.deadzone); put("invertX", invertX, f.invertX); put("invertY", invertY, f.invertY)
    }

    public static let keys: [String] = []
    public static func reset(_ d: UserDefaults) {}
}
