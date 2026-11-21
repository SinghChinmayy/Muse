// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Muse",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic (settings, scroll gate, cursor math, login agent, status). Unit tested.
        .target(name: "MuseCore"),
        // The app: multitouch + event tap glue, menu bar and Settings window.
        .executableTarget(name: "Muse", dependencies: ["MuseCore"]),
        .testTarget(name: "MuseCoreTests", dependencies: ["MuseCore"]),
    ],
    swiftLanguageModes: [.v5]
)
