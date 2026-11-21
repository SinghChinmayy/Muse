import Testing
@testable import MuseCore

@Suite struct TapDetectorTests {
    static var on: Settings { var s = Settings(); s.tapToClick = true; return s }

    /// One finger lands at (0.5, 0.5) at `start`, is at `to` after `duration`, then lifts.
    func tap(_ t: TapDetector, at start: Double, for duration: Double = 0.1, to: (Double, Double) = (0.5, 0.5),
             settings s: Settings = on) -> Int? {
        _ = t.frame(touches: [Touch(id: 1, x: 0.5, y: 0.5)], now: start, settings: s)
        _ = t.frame(touches: [Touch(id: 1, x: to.0, y: to.1)], now: start + duration, settings: s)
        return t.frame(touches: [], now: start + duration, settings: s)
    }

    @Test func quickOneFingerTapClicks() {
        #expect(tap(TapDetector(), at: 10) == 1)
    }
}

extension TapDetectorTests {
    @Test func restingFingerDoesNotClick() {
        #expect(tap(TapDetector(), at: 10, for: 0.5) == nil)
    }
}

extension TapDetectorTests {
    @Test func slidingFingerDoesNotClick() {
        #expect(tap(TapDetector(), at: 10, to: (0.6, 0.5)) == nil)
    }
}

extension TapDetectorTests {
    @Test func twoFingerTouchDoesNotClick() {
        let t = TapDetector(), s = Self.on
        _ = t.frame(touches: [Touch(id: 1, x: 0.5, y: 0.5)], now: 10, settings: s)
        _ = t.frame(touches: [Touch(id: 1, x: 0.5, y: 0.5), Touch(id: 2, x: 0.3, y: 0.5)], now: 10.05, settings: s)
        _ = t.frame(touches: [Touch(id: 1, x: 0.5, y: 0.5)], now: 10.08, settings: s)
        #expect(t.frame(touches: [], now: 10.1, settings: s) == nil)
    }
}

extension TapDetectorTests {
    // A quick physical click also touches the surface; it must not become a second click.
    @Test func physicalClickDuringTouchDoesNotAlsoTapClick() {
        let t = TapDetector(), s = Self.on
        _ = t.frame(touches: [Touch(id: 1, x: 0.5, y: 0.5)], now: 10, settings: s)
        t.buttonPressed()
        #expect(t.frame(touches: [], now: 10.1, settings: s) == nil)
    }
}

extension TapDetectorTests {
    @Test func secondQuickTapIsADoubleClick() {
        let t = TapDetector(doubleClickInterval: 0.5)
        #expect(tap(t, at: 10) == 1)
        #expect(tap(t, at: 10.3) == 2)
        #expect(tap(t, at: 12) == 1)      // too late: a fresh single click
    }
}
