import Foundation
import Testing
@testable import MuseCore

@Suite struct SettingsModelTests {
    final class Engine { var applied: [Settings] = [] }

    @Test func editSavesAndAppliesToEngine() {
        let d = freshDefaults(), engine = Engine()
        let m = SettingsModel(defaults: d) { engine.applied.append($0) }
        m.settings.cursorSpeed = 2.0
        #expect(d.object(forKey: "cursorSpeed") as? Double == 2.0)
        #expect(engine.applied.last?.cursorSpeed == 2.0)
    }
}

extension SettingsModelTests {
    /// A `defaults write` from the terminal shows up on reload, and reload never rewrites it.
    @Test func reloadAppliesExternalChangesWithoutWriting() {
        let d = freshDefaults(), engine = Engine()
        let m = SettingsModel(defaults: d) { engine.applied.append($0) }
        d.set("1.5", forKey: "cursorSpeed")
        m.reload()
        #expect(m.settings.cursorSpeed == 1.5)
        #expect(engine.applied.last?.cursorSpeed == 1.5)
        #expect(d.object(forKey: "cursorSpeed") as? String == "1.5")
    }
}
