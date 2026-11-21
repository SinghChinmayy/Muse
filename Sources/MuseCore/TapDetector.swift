/// Turns a quick one-finger tap on the Magic Mouse surface into a left click, like a trackpad.
public final class TapDetector {
    public static let maxDuration = 0.25   // seconds a finger may stay down and still count as a tap

    private var down = false
    private var start = 0.0

    public init() {}

    /// Feed every Magic Mouse frame. Returns the click count (1 = single, 2 = double, ...)
    /// on the frame that ends a tap, otherwise nil.
    public func frame(touches: [Touch], now: Double, settings: Settings) -> Int? {
        if !touches.isEmpty {
            if !down { down = true; start = now }
            return nil
        }
        guard down else { return nil }
        down = false
        return now - start <= Self.maxDuration ? 1 : nil
    }
}
