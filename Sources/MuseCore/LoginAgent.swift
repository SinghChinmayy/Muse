import Foundation

/// The LaunchAgent plist that starts Muse at login. Same template the Makefile fills with sed.
public struct LoginAgent {
    public static func render(template: String, appPath: String, logPath: String) -> String {
        template.replacingOccurrences(of: "__APP__", with: appPath)
                .replacingOccurrences(of: "__LOG__", with: logPath)
    }
}
