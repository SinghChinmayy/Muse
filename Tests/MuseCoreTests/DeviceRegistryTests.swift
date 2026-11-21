import Testing
@testable import MuseCore

@Suite struct DeviceRegistryTests {
    @Test(arguments: [Int32(112), 113, 114])
    func magicMouseFamiliesAreMice(family: Int32) {
        #expect(DeviceRegistry.isMagicMouse(family: family))
    }
    @Test(arguments: [Int32(98), 110, 128, 0])
    func trackpadsAndOtherFamiliesAreNotMice(family: Int32) {
        #expect(!DeviceRegistry.isMagicMouse(family: family))
    }
    @Test func newDeviceIsHookedOnce() {
        var r = DeviceRegistry()
        let first = r.register(id: 1, family: 112, handle: 0xA)
        let second = r.register(id: 1, family: 112, handle: 0xA)
        #expect(first)
        #expect(!second)
    }
    @Test func onlyMiceAreTreatedAsMice() {
        var r = DeviceRegistry()
        _ = r.register(id: 1, family: 112, handle: 0xA)
        _ = r.register(id: 2, family: 128, handle: 0xB)
        #expect(r.isMouse(handle: 0xA))
        #expect(!r.isMouse(handle: 0xB))
        #expect(!r.isMouse(handle: 0xC))
    }
    @Test func resetForgetsDevicesSoTheyAreHookedAgain() {
        var r = DeviceRegistry()
        _ = r.register(id: 1, family: 112, handle: 0xA)
        r.reset()
        #expect(!r.isMouse(handle: 0xA))
        let again = r.register(id: 1, family: 112, handle: 0xA)
        #expect(again)
    }
}
