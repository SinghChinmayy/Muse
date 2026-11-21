/// Finger bookkeeping shared by the multitouch callback and the scroll event tap.
/// Not thread-safe: the app guards it with a lock.
public final class TouchSession {
    public private(set) var mouseFingers = 0
    public private(set) var sessionMax = 0        // max fingers since the mouse surface was last empty
    public private(set) var lastTwoFinger = 0.0   // last time >= 2 fingers on the mouse
    public private(set) var lastMouseTouch = 0.0
    public private(set) var lastOtherTouch = 0.0  // trackpad etc.

    public init() {}

    /// Records a Magic Mouse frame. Returns whether the single finger may drive the cursor:
    /// exactly one finger, and not right after a two-finger gesture.
    public func mouseFrame(fingers: Int, now: Double) -> Bool {
        let cursor = fingers == 1 && now - lastTwoFinger > 0.25
        if fingers > 0 {
            if mouseFingers == 0 { sessionMax = 0 }
            sessionMax = max(sessionMax, fingers)
            lastMouseTouch = now
            if fingers >= 2 { lastTwoFinger = now }
        }
        mouseFingers = fingers
        return cursor
    }

    /// Records a frame from another touch device (trackpad).
    public func otherFrame(fingers: Int, now: Double) {
        if fingers > 0 { lastOtherTouch = now }
    }

    /// Whether a scroll event may pass. Real wheels and scrolls from other devices always do;
    /// Magic Mouse scrolls go through ScrollGate.
    public func allowScroll(continuous: Bool, momentum: Bool, now: Double, enabled: Bool) -> Bool {
        guard continuous else { return true }
        let mouseIsSource = lastMouseTouch >= lastOtherTouch
            && (mouseFingers > 0 || momentum || now - lastMouseTouch < 1.0)
        guard mouseIsSource else { return true }
        return ScrollGate.allow(fingers: mouseFingers, sessionMax: sessionMax, lastTwoFinger: lastTwoFinger,
                                now: now, momentum: momentum, enabled: enabled)
    }

    /// Whether a pointer move/drag event may pass. `synthetic` marks events Muse posted itself.
    public func allowPointerMotion(synthetic: Bool, now: Double, settings: Settings) -> Bool {
        !settings.enabled || synthetic || settings.opticalEnabled || now - lastOtherTouch < 0.1
    }
}
