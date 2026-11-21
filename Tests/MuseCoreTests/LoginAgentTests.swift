import Foundation
import Testing
@testable import MuseCore

@Suite struct LoginAgentTests {
    @Test func renderFillsAppAndLogPaths() {
        let t = "<string>__APP__/Contents/MacOS/Muse</string><string>__LOG__</string>"
        #expect(LoginAgent.render(template: t, appPath: "/Users/x/Applications/Muse.app", logPath: "/Users/x/Library/Logs/Muse.log")
                == "<string>/Users/x/Applications/Muse.app/Contents/MacOS/Muse</string><string>/Users/x/Library/Logs/Muse.log</string>")
    }
}
