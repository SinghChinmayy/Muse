import Testing
@testable import MuseCore

@Suite struct TouchFrameTests {
    /// Builds a raw MTTouch buffer: one (id, state, x, y) per touch at the real byte offsets.
    func frame(_ touches: [(Int32, Int32, Float, Float)]) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: touches.count * TouchFrame.stride)
        bytes.withUnsafeMutableBytes { buf in
            for (i, t) in touches.enumerated() {
                let base = i * TouchFrame.stride
                buf.storeBytes(of: t.0, toByteOffset: base + 16, as: Int32.self)
                buf.storeBytes(of: t.1, toByteOffset: base + 20, as: Int32.self)
                buf.storeBytes(of: t.2, toByteOffset: base + 32, as: Float.self)
                buf.storeBytes(of: t.3, toByteOffset: base + 36, as: Float.self)
            }
        }
        return bytes
    }
    func parse(_ bytes: [UInt8], count: Int) -> [Touch] {
        bytes.withUnsafeBytes { TouchFrame.activeTouches($0.baseAddress, count: count) }
    }

    @Test func readsIdAndPositionAtTheRealOffsets() {
        #expect(parse(frame([(7, 4, 0.25, 0.75)]), count: 1) == [Touch(id: 7, x: 0.25, y: 0.75)])
    }
    @Test func countsMakeTouchingAndBreakButNotHoverOrGone() {
        let f = frame([(1, 1, 0, 0), (2, 2, 0, 0), (3, 3, 0, 0), (4, 4, 0, 0), (5, 5, 0, 0), (6, 6, 0, 0), (7, 7, 0, 0)])
        #expect(parse(f, count: 7).map(\.id) == [3, 4, 5])
    }
    @Test func emptyOrMissingFrameHasNoTouches() {
        #expect(TouchFrame.activeTouches(nil, count: 3).isEmpty)
        #expect(parse([], count: 0).isEmpty)
    }
}
