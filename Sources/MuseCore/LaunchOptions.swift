/// Command-line flags: `Muse [--probe] [--debug]`.
public struct LaunchOptions: Equatable {
    /// List touch devices and exit.
    public var probe: Bool
    /// Log finger counts, cursor moves and blocked scrolls.
    public var debug: Bool

    public init(arguments: [String]) {
        probe = arguments.contains("--probe")
        debug = arguments.contains("--debug")
    }
}
