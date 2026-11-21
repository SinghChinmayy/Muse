/// Tracks which multitouch devices Muse has hooked, and which of them are Magic Mice.
/// Not thread-safe: the app guards it with a lock.
public struct DeviceRegistry {
    /// Magic Mouse family IDs (Magic Mouse 1/2/USB-C). Trackpads are 98+ / 128+.
    public static let magicMouseFamilies: Set<Int32> = [112, 113, 114]
    public static func isMagicMouse(family: Int32) -> Bool { magicMouseFamilies.contains(family) }

    private var knownIDs = Set<UInt64>()
    private var mice = Set<UInt>()

    public init() {}

    /// Records a device seen in a scan. Returns true the first time a device ID is seen,
    /// meaning the caller should hook its frame callback.
    public mutating func register(id: UInt64, family: Int32, handle: UInt) -> Bool {
        guard knownIDs.insert(id).inserted else { return false }
        if Self.isMagicMouse(family: family) { mice.insert(handle) }
        return true
    }

    /// Whether frames from this device handle come from a Magic Mouse.
    public func isMouse(handle: UInt) -> Bool { mice.contains(handle) }

    /// Forget everything (after wake), so the next scan hooks devices again.
    public mutating func reset() { knownIDs.removeAll(); mice.removeAll() }
}
