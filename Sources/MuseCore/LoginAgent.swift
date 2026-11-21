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

    public var isEnabled: Bool { false }
    public func setEnabled(_ on: Bool) throws {}

    public static func render(template: String, appPath: String, logPath: String) -> String {
        template.replacingOccurrences(of: "__APP__", with: appPath)
                .replacingOccurrences(of: "__LOG__", with: logPath)
    }
}
