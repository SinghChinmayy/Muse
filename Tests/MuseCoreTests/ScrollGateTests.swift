import Testing
@testable import MuseCore

@Suite struct ScrollGateTests {
    @Test func oneFingerScrollIsBlocked() {
        #expect(!ScrollGate.allow(fingers: 1, sessionMax: 1, lastTwoFinger: 0, now: 10, momentum: false))
    }
    @Test func twoFingerScrollPasses() {
        #expect(ScrollGate.allow(fingers: 2, sessionMax: 2, lastTwoFinger: 10, now: 10, momentum: false))
    }
    @Test func briefFingerLiftDuringTwoFingerScrollPasses() {
        #expect(ScrollGate.allow(fingers: 1, sessionMax: 2, lastTwoFinger: 10, now: 10.1, momentum: false))
    }
    @Test func momentumAfterTwoFingerGesturePasses() {
        #expect(ScrollGate.allow(fingers: 0, sessionMax: 2, lastTwoFinger: 9, now: 10, momentum: true))
    }
    @Test func momentumAfterOneFingerGestureIsBlocked() {
        #expect(!ScrollGate.allow(fingers: 0, sessionMax: 1, lastTwoFinger: 0, now: 10, momentum: true))
    }
}
