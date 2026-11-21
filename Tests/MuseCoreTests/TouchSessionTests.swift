import Testing
@testable import MuseCore

@Suite struct TouchSessionTests {
    func scroll(_ s: TouchSession, at now: Double, continuous: Bool = true, momentum: Bool = false, enabled: Bool = true) -> Bool {
        s.allowScroll(continuous: continuous, momentum: momentum, now: now, enabled: enabled)
    }

    // Cursor
    @Test func oneFingerDrivesTheCursor() {
        #expect(TouchSession().mouseFrame(fingers: 1, now: 10))
    }
    @Test func twoOrNoFingersDoNotDriveTheCursor() {
        let s = TouchSession()
        #expect(!s.mouseFrame(fingers: 2, now: 10))
        #expect(!s.mouseFrame(fingers: 0, now: 11))
    }
    @Test func cursorWaitsBrieflyAfterATwoFingerGesture() {
        let s = TouchSession()
        _ = s.mouseFrame(fingers: 2, now: 10)
        #expect(!s.mouseFrame(fingers: 1, now: 10.1))
        #expect(s.mouseFrame(fingers: 1, now: 10.3))
    }

    // Bookkeeping
    @Test func sessionMaxKeepsThePeakWhileTouching() {
        let s = TouchSession()
        _ = s.mouseFrame(fingers: 1, now: 10); _ = s.mouseFrame(fingers: 2, now: 10.1); _ = s.mouseFrame(fingers: 1, now: 10.2)
        #expect(s.sessionMax == 2)
        #expect(s.mouseFingers == 1)
    }
    @Test func sessionMaxStartsOverAfterTheSurfaceEmpties() {
        let s = TouchSession()
        _ = s.mouseFrame(fingers: 2, now: 10); _ = s.mouseFrame(fingers: 0, now: 10.1); _ = s.mouseFrame(fingers: 1, now: 11)
        #expect(s.sessionMax == 1)
    }
    @Test func otherDeviceFramesOnlyCountWithFingers() {
        let s = TouchSession()
        s.otherFrame(fingers: 0, now: 10)
        #expect(s.lastOtherTouch == 0)
        s.otherFrame(fingers: 2, now: 11)
        #expect(s.lastOtherTouch == 11)
    }

    // Scroll
    @Test func realScrollWheelAlwaysPasses() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10)
        #expect(scroll(s, at: 10, continuous: false))
    }
    @Test func oneFingerMouseScrollIsBlocked() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10)
        #expect(!scroll(s, at: 10))
    }
    @Test func twoFingerMouseScrollPasses() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 2, now: 10)
        #expect(scroll(s, at: 10))
    }
    @Test func trackpadScrollPassesWhenTrackpadWasTouchedLast() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10)
        s.otherFrame(fingers: 2, now: 11)
        #expect(scroll(s, at: 11))
    }
    @Test func shortlyAfterOneFingerLiftScrollIsStillBlocked() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10); _ = s.mouseFrame(fingers: 0, now: 10.1)
        #expect(!scroll(s, at: 10.5))
    }
    @Test func mouseStopsOwningScrollOneSecondAfterLift() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10); _ = s.mouseFrame(fingers: 0, now: 10.1)
        #expect(scroll(s, at: 11.2))
    }
    @Test func momentumAfterTwoFingerFlickPassesLongAfterLift() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 2, now: 10); _ = s.mouseFrame(fingers: 0, now: 10.1)
        #expect(scroll(s, at: 13, momentum: true))
    }
    @Test func momentumAfterOneFingerSwipeIsBlocked() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10); _ = s.mouseFrame(fingers: 0, now: 10.1)
        #expect(!scroll(s, at: 13, momentum: true))
    }
    @Test func pausedMuseLetsMouseScrollThrough() {
        let s = TouchSession(); _ = s.mouseFrame(fingers: 1, now: 10)
        #expect(scroll(s, at: 10, enabled: false))
    }
}

extension TouchSessionTests {
    static var opticalOff: Settings { var s = Settings(); s.opticalEnabled = false; return s }

    @Test func opticalOffBlocksHardwarePointerMotion() {
        #expect(!TouchSession().allowPointerMotion(synthetic: false, now: 10, settings: Self.opticalOff))
    }
}

extension TouchSessionTests {
    @Test func musesOwnCursorMovesPassWithOpticalOff() {
        #expect(TouchSession().allowPointerMotion(synthetic: true, now: 10, settings: Self.opticalOff))
    }
}

extension TouchSessionTests {
    // CGEvents do not say which device moved; a finger on the trackpad means the trackpad did.
    @Test func trackpadMotionPassesWithOpticalOff() {
        let s = TouchSession()
        s.otherFrame(fingers: 1, now: 10)
        #expect(s.allowPointerMotion(synthetic: false, now: 10.05, settings: Self.opticalOff))
        #expect(!s.allowPointerMotion(synthetic: false, now: 10.5, settings: Self.opticalOff))
    }
}

extension TouchSessionTests {
    @Test func pausedMuseLetsOpticalMotionThrough() {
        var s = Self.opticalOff; s.enabled = false
        #expect(TouchSession().allowPointerMotion(synthetic: false, now: 10, settings: s))
    }
}
