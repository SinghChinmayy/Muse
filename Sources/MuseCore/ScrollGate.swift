/// Decides whether a continuous scroll event that came from the Magic Mouse may pass.
/// One finger: blocked. Two or more: allowed. Momentum after lift-off: allowed if the
/// gesture that started it used two fingers. Everything passes while Muse is paused.
public enum ScrollGate {
    public static func allow(fingers: Int, sessionMax: Int, lastTwoFinger: Double, now: Double, momentum: Bool, enabled: Bool = true) -> Bool {
        if !enabled { return true }
        if fingers > 0 && !momentum {
            return fingers >= 2 || now - lastTwoFinger < 0.25   // tolerate a finger briefly lifting
        }
        return sessionMax >= 2                                   // momentum after lift-off
    }
}
