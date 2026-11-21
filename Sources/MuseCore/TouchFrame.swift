/// One finger on the surface, in normalized surface units.
public struct Touch: Equatable {
    public var id: Int32
    public var x: Double
    public var y: Double
    public init(id: Int32, x: Double, y: Double) { self.id = id; self.x = x; self.y = y }
}

/// Reads the raw contact frames MultitouchSupport hands to the frame callback.
public enum TouchFrame {
    /// MTTouch is 96 bytes: id@16, state@20, normalized pos x@32 y@36 (Float).
    public static let stride = 96

    /// Fingers currently on the surface. State 3 = make, 4 = touching, 5 = break; others are hovering or gone.
    public static func activeTouches(_ raw: UnsafeRawPointer?, count: Int) -> [Touch] {
        guard let raw else { return [] }
        return (0..<count).compactMap { i in
            let base = i * stride
            let state = raw.load(fromByteOffset: base + 20, as: Int32.self)
            guard state >= 3 && state <= 5 else { return nil }
            return Touch(id: raw.load(fromByteOffset: base + 16, as: Int32.self),
                         x: Double(raw.load(fromByteOffset: base + 32, as: Float.self)),
                         y: Double(raw.load(fromByteOffset: base + 36, as: Float.self)))
        }
    }
}
