/// Turns a quick one-finger tap on the Magic Mouse surface into a left click, like a trackpad.
public final class TapDetector {
    public init() {}

    /// Feed every Magic Mouse frame. Returns the click count (1 = single, 2 = double, ...)
    /// on the frame that ends a tap, otherwise nil.
    public func frame(touches: [Touch], now: Double, settings: Settings) -> Int? {
        nil
    }
}
