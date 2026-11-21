import Foundation

/// Turns a quick one-finger tap on the Magic Mouse surface into a left click, like a trackpad.
public final class TapDetector {
    public static let maxDuration = 0.25   // seconds a finger may stay down and still count as a tap
    public static let slop = 0.03          // normalized surface units a tapping finger may drift

    private let doubleClickInterval: Double
    private var down = false
    private var start = 0.0
    private var startPos = (x: 0.0, y: 0.0)
    private var spoiled = false            // this touch can no longer be a tap
    private var lastTap = -Double.infinity
    private var clicks = 0

    public init(doubleClickInterval: Double = 0.5) { self.doubleClickInterval = doubleClickInterval }

    /// Feed every Magic Mouse frame. Returns the click count (1 = single, 2 = double, ...)
    /// on the frame that ends a tap, otherwise nil.
    public func frame(touches: [Touch], now: Double, settings: Settings) -> Int? {
        if let t = touches.first {
            if !down { down = true; start = now; startPos = (t.x, t.y); spoiled = false }
            if touches.count > 1 || hypot(t.x - startPos.x, t.y - startPos.y) > Self.slop { spoiled = true }
            return nil
        }
        guard down else { return nil }
        down = false
        guard settings.enabled, settings.tapToClick, !spoiled, now - start <= Self.maxDuration else { return nil }
        clicks = now - lastTap <= doubleClickInterval ? clicks + 1 : 1
        lastTap = now
        return clicks
    }

    /// A real mouse button went down.
    public func buttonPressed() { spoiled = true }
}
