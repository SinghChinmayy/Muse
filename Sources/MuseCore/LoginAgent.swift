import Foundation

/// The LaunchAgent plist that starts Muse at login. Same template the Makefile fills with sed.
public struct LoginAgent {
    public let plistURL: URL
    public let template: String
    public let appPath: String
    public let logPath: String

    public init(plistURL: URL, template: String, appPath: String, logPath: String) {
        self.plistURL = plistURL; self.template = template; self.appPath = appPath; self.logPath = logPath
    }

    /// On when the plist exists. Toggling only affects the next login: Muse keeps running either way.
    public var isEnabled: Bool { FileManager.default.fileExists(atPath: plistURL.path) }

    public func setEnabled(_ on: Bool) throws {
        let fm = FileManager.default
        if on {
            try fm.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.render(template: template, appPath: appPath, logPath: logPath)
                .write(to: plistURL, atomically: true, encoding: .utf8)
        } else if isEnabled {
            try fm.removeItem(at: plistURL)
        }
    }

    public static func render(template: String, appPath: String, logPath: String) -> String {
        template.replacingOccurrences(of: "__APP__", with: appPath)
                .replacingOccurrences(of: "__LOG__", with: logPath)
    }
}
