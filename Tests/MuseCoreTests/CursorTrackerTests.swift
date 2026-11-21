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

extension CursorTrackerTests {
    func flat(_ speed: Double = 1) -> Settings {
        var s = Settings(); s.cursorAccel = 0; s.cursorSpeed = speed; s.deadzone = 0; return s
    }

    @Test func newFingerReanchorsWithoutJump() {
        let t = CursorTracker(), s = Settings()
        _ = t.update(id: 1, x: 0.5, y: 0.5, settings: s)
        #expect(t.update(id: 1, x: 0.6, y: 0.5, settings: s) != nil)
        #expect(t.update(id: 2, x: 0.9, y: 0.9, settings: s) == nil)   // different finger: anchor, no jump
    }
    @Test func liftingTheFingerResetsTracking() {
        let t = CursorTracker(), s = Settings()
        _ = t.update(id: 1, x: 0.5, y: 0.5, settings: s)
        _ = t.update(id: 1, x: 0.6, y: 0.5, settings: s)
        #expect(t.update(id: nil, x: 0, y: 0, settings: s) == nil)
        #expect(t.update(id: 1, x: 0.9, y: 0.9, settings: s) == nil)   // same id after lift: re-anchor
    }
    @Test func subPixelMovesAccumulate() {
        let t = CursorTracker(), s = flat()
        _ = t.update(id: 1, x: 0.5, y: 0.5, settings: s)
        #expect(t.update(id: 1, x: 0.5005, y: 0.5, settings: s) == nil)   // ~0.45 px
        #expect(t.update(id: 1, x: 0.5010, y: 0.5, settings: s) == nil)   // ~0.9 px
        #expect(t.update(id: 1, x: 0.5015, y: 0.5, settings: s)?.dx == 1)  // ~1.35 px -> 1
    }
    @Test func accelerationSpeedsUpFastSwipes() {
        var accel = flat(); accel.cursorAccel = 1
        let slow = slide(to: (0.6, 0.5), flat())?.dx ?? 0
        let fast = slide(to: (0.6, 0.5), accel)?.dx ?? 0
        #expect(fast > slow * 3)
    }
    @Test func speedScalesMovement() {
        let one = slide(to: (0.6, 0.5), flat(1))?.dx ?? 0
        let two = slide(to: (0.6, 0.5), flat(2))?.dx ?? 0
        #expect(two > one * 1.9)
    }
    @Test func verticalIsScaledToFeelEqualToHorizontal() {
        let h = abs(slide(to: (0.6, 0.5), flat())?.dx ?? 0)
        let v = abs(slide(to: (0.5, 0.6), flat())?.dy ?? 0)
        #expect(v > h * 1.4)   // surface is ~10x15 cells, y scaled by 1.5
    }
    @Test func invertYFlipsVerticalDirection() {
        var s = Settings(); s.invertY = true
        #expect((slide(to: (0.5, 0.6), s)?.dy ?? 0) > 0)
    }
}
