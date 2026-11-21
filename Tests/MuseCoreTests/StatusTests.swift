import Testing
@testable import MuseCore

@Suite struct StatusTests {
    @Test func statusLineReportsPermissionFirstThenMouse() {
        let noAX = Status(trusted: false, mouseConnected: true, enabled: true)
        #expect(noAX.title == "Needs Accessibility Permission")
        #expect(noAX.opensAccessibilitySettings)
        let noMouse = Status(trusted: true, mouseConnected: false, enabled: true)
        #expect(noMouse.title == "No Magic Mouse Found")
        #expect(!noMouse.opensAccessibilitySettings)
        #expect(Status(trusted: true, mouseConnected: true, enabled: true).title == "Magic Mouse Connected")
    }
}
