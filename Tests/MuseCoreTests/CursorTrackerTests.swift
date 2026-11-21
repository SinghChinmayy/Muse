import Testing
@testable import MuseCore

@Suite struct CursorTrackerTests {
    /// Touch down at (0.5, 0.5), then slide to `to` with the same finger.
    func slide(to: (Double, Double), _ s: Settings = Settings()) -> (dx: Double, dy: Double)? {
        let t = CursorTracker()
        _ = t.update(id: 1, x: 0.5, y: 0.5, settings: s)
        return t.update(id: 1, x: to.0, y: to.1, settings: s)
    }

    @Test func touchDownAnchorsWithoutMoving() {
        #expect(CursorTracker().update(id: 1, x: 0.5, y: 0.5, settings: Settings()) == nil)
    }
    @Test func slideInsideDeadzoneDoesNotMove() {
        #expect(slide(to: (0.51, 0.5)) == nil)
    }
    @Test func slideRightMovesCursorRight() {
        let m = slide(to: (0.6, 0.5))
        #expect((m?.dx ?? 0) > 0)
        #expect(m?.dy == 0)
    }
    @Test func slideUpMovesCursorUpOnScreen() {
        #expect((slide(to: (0.5, 0.6))?.dy ?? 0) < 0)   // screen y grows downward
    }
    @Test func invertXFlipsHorizontalDirection() {
        var s = Settings(); s.invertX = true
        #expect((slide(to: (0.6, 0.5), s)?.dx ?? 0) < 0)
    }
    @Test func cursorDisabledDoesNotMove() {
        var s = Settings(); s.cursorEnabled = false
        #expect(slide(to: (0.6, 0.5), s) == nil)
    }
}

extension CursorTrackerTests {
    @Test func pausedMuseDoesNotMoveCursor() {
        var s = Settings(); s.enabled = false
        #expect(slide(to: (0.6, 0.5), s) == nil)
    }
}
