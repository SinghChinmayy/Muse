import Foundation
/// Turns one finger's movement on the Magic Mouse surface into cursor deltas, like a trackpad.
public final class CursorTracker {
    private var trackID: Int32 = -1        // touch path being followed
    private var lastPos = (x: 0.0, y: 0.0)
    private var startPos = (x: 0.0, y: 0.0)
    private var tracking = false           // passed the deadzone
    private var remainder = (x: 0.0, y: 0.0)

    public init() {}

    /// Feed the single touching finger (or nil when not exactly one). Positions are normalized
    /// surface units. Returns whole-pixel deltas to move the cursor by, or nil for no move.
    public func update(id: Int32?, x: Double, y: Double, settings s: Settings) -> (dx: Double, dy: Double)? {
        guard s.enabled, s.cursorEnabled, let id else { trackID = -1; tracking = false; return nil }
        if id != trackID {                 // new finger (or 2 -> 1 transition): re-anchor, no jump
            trackID = id; lastPos = (x, y); startPos = (x, y); tracking = false; remainder = (0, 0)
            return nil
        }
        if !tracking {
            if hypot(x - startPos.x, y - startPos.y) < s.deadzone { lastPos = (x, y); return nil }
            tracking = true
        }
        var dx = x - lastPos.x, dy = y - lastPos.y
        lastPos = (x, y)
        // Surface is ~10x15 sensor cells; scale y so both axes feel equal.
        let speed = hypot(dx, dy * 1.5)
        let gain = 900.0 * s.cursorSpeed * (1 + s.cursorAccel * min(speed * 60, 3))
        dx *= gain * (s.invertX ? -1 : 1)
        dy *= gain * 1.5 * (s.invertY ? 1 : -1)   // surface y grows upward, screen y grows downward
        dx += remainder.x; dy += remainder.y
        let ix = dx.rounded(.towardZero), iy = dy.rounded(.towardZero)
        remainder = (dx - ix, dy - iy)
        return ix != 0 || iy != 0 ? (ix, iy) : nil
    }
}
