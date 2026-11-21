import Testing
@testable import MuseCore

@Suite struct SettingsTests {
    @Test func loadFromEmptyDefaultsGivesFactoryValues() {
        let s = Settings.load(from: freshDefaults())
        #expect(s == Settings(enabled: true, cursorEnabled: true, cursorSpeed: 1.0, cursorAccel: 1.0,
                              deadzone: 0.03, invertX: false, invertY: false))
    }
}

extension SettingsTests {
    @Test func loadReadsStoredValues() {
        let d = freshDefaults()
        d.set(false, forKey: "enabled"); d.set(false, forKey: "cursorEnabled")
        d.set(2.5, forKey: "cursorSpeed"); d.set(0.0, forKey: "cursorAccel")
        d.set(0.05, forKey: "deadzone"); d.set(true, forKey: "invertX"); d.set(true, forKey: "invertY")
        #expect(Settings.load(from: d) == Settings(enabled: false, cursorEnabled: false, cursorSpeed: 2.5,
                                                   cursorAccel: 0.0, deadzone: 0.05, invertX: true, invertY: true))
    }
}

extension SettingsTests {
    // `defaults write <domain> cursorSpeed 1.5` (no -float) stores a string.
    @Test func loadAcceptsValuesWrittenAsStrings() {
        let d = freshDefaults()
        d.set("1.5", forKey: "cursorSpeed"); d.set("0.05", forKey: "deadzone"); d.set("YES", forKey: "invertY")
        let s = Settings.load(from: d)
        #expect(s.cursorSpeed == 1.5)
        #expect(s.deadzone == 0.05)
        #expect(s.invertY == true)
    }
}
