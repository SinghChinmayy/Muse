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
