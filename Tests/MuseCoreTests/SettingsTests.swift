import Testing
@testable import MuseCore

@Suite struct SettingsTests {
    @Test func loadFromEmptyDefaultsGivesFactoryValues() {
        let s = Settings.load(from: freshDefaults())
        #expect(s == Settings(enabled: true, cursorEnabled: true, cursorSpeed: 1.0, cursorAccel: 1.0,
                              deadzone: 0.03, invertX: false, invertY: false))
    }
}
