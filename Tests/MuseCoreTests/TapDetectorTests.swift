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
