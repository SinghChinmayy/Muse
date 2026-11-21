import CoreGraphics
import Testing
@testable import MuseCore

@Suite struct CursorPlacementTests {
    let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let left = CGRect(x: -1920, y: -180, width: 1920, height: 1080)

    @Test func boundsCoverAllDisplays() {
        #expect(CursorPlacement.union([main, left]) == CGRect(x: -1920, y: -180, width: 3360, height: 1080))
        #expect(CursorPlacement.union([]).isNull)
    }
    @Test func pointInsideIsUnchanged() {
        #expect(CursorPlacement.clamp(CGPoint(x: 100, y: 200), to: main) == CGPoint(x: 100, y: 200))
    }
    @Test func pointPastAnEdgeStopsOnTheLastPixel() {
        #expect(CursorPlacement.clamp(CGPoint(x: 5000, y: 5000), to: main) == CGPoint(x: 1439, y: 899))
        #expect(CursorPlacement.clamp(CGPoint(x: -50, y: -50), to: main) == CGPoint(x: 0, y: 0))
    }
    @Test func noButtonIsAPlainMove() {
        let e = CursorPlacement.event(leftDown: false, rightDown: false)
        #expect(e.type == .mouseMoved)
        #expect(e.button == .left)
    }
    @Test func leftButtonHeldIsALeftDrag() {
        let e = CursorPlacement.event(leftDown: true, rightDown: false)
        #expect(e.type == .leftMouseDragged)
        #expect(e.button == .left)
    }
    @Test func rightButtonHeldIsARightDrag() {
        let e = CursorPlacement.event(leftDown: false, rightDown: true)
        #expect(e.type == .rightMouseDragged)
        #expect(e.button == .right)
    }
    @Test func bothButtonsHeldIsALeftDrag() {
        let e = CursorPlacement.event(leftDown: true, rightDown: true)
        #expect(e.type == .leftMouseDragged)
        #expect(e.button == .left)
    }
}

@Suite struct LaunchOptionsTests {
    @Test func noFlagsRunsNormally() {
        #expect(LaunchOptions(arguments: ["Muse"]) == LaunchOptions(arguments: []))
        #expect(!LaunchOptions(arguments: ["Muse"]).probe)
        #expect(!LaunchOptions(arguments: ["Muse"]).debug)
    }
    @Test func flagsAreRecognized() {
        let o = LaunchOptions(arguments: ["Muse", "--debug", "--probe"])
        #expect(o.probe)
        #expect(o.debug)
    }
}
