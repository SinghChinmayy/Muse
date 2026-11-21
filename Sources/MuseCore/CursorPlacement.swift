import CoreGraphics

/// Where a synthesized cursor move lands and which mouse event it is posted as.
public enum CursorPlacement {
    /// The area covered by all displays.
    public static func union(_ displays: [CGRect]) -> CGRect {
        displays.reduce(CGRect.null) { $0.union($1) }
    }

    /// Keeps the cursor inside the displays' bounding box.
    public static func clamp(_ p: CGPoint, to b: CGRect) -> CGPoint {
        CGPoint(x: min(max(p.x, b.minX), b.maxX - 1), y: min(max(p.y, b.minY), b.maxY - 1))
    }

    /// Moving with a button held must be a drag, or text selection and window drags break.
    public static func event(leftDown: Bool, rightDown: Bool) -> (type: CGEventType, button: CGMouseButton) {
        if leftDown { return (.leftMouseDragged, .left) }
        if rightDown { return (.rightMouseDragged, .right) }
        return (.mouseMoved, .left)
    }
}
