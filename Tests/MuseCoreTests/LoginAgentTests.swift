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

extension LoginAgentTests {
    func agent() -> LoginAgent {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MuseTests-\(UUID().uuidString)")
        return LoginAgent(plistURL: dir.appendingPathComponent("LaunchAgents/muse.plist"),
                          template: "<string>__APP__</string><string>__LOG__</string>",
                          appPath: "/A/Muse.app", logPath: "/L/Muse.log")
    }

    @Test func enableWritesRenderedPlistAndDisableRemovesIt() throws {
        let a = agent()
        #expect(!a.isEnabled)
        try a.setEnabled(true)
        #expect(a.isEnabled)
        #expect(try String(contentsOf: a.plistURL, encoding: .utf8) == "<string>/A/Muse.app</string><string>/L/Muse.log</string>")
        try a.setEnabled(false)
        #expect(!a.isEnabled)
        try a.setEnabled(false)   // already off: no error
    }
}

extension LoginAgentTests {
    /// Quit from the menu exits 0; launchd must not bring Muse straight back. Crashes still restart.
    @Test func shippedTemplateRestartsOnlyAfterCrash() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/launchagent.plist")
        let plist = try #require(NSDictionary(contentsOf: url))
        let keepAlive = try #require(plist["KeepAlive"] as? [String: Any])
        #expect(keepAlive["SuccessfulExit"] as? Bool == false)
    }
}
