# Muse

macOS background app that makes the Magic Mouse surface work like a trackpad:
one finger moves the cursor, two fingers scroll, one-finger scrolling is blocked.

- Swift package. `Sources/MuseCore`: pure, unit-tested logic (`Settings`, `ScrollGate`,
  `CursorTracker`, `LoginAgent`, `Status`, `SettingsModel`). `Sources/Muse`: the app.
  `main.swift` is the engine (private `MultitouchSupport` framework + a `CGEventTap` on scroll
  events), `MenuBar.swift` the menu bar, `SettingsWindow.swift` the SwiftUI Settings window.
- Tests: `make test` (Swift Testing, `Tests/MuseCoreTests`). Build new logic test-first in
  MuseCore; keep AppKit glue in `Sources/Muse` thin.
- Build and install with the `Makefile` (`make install`). Bundle ID, defaults domain and
  LaunchAgent label are all `io.github.singhchinmayy.Muse`.
- Every rebuild changes the ad-hoc signature, so Accessibility must be granted again.
  Prefer tunables in `defaults` over code changes for feel tweaks.
- Keep the settings table in `README.md` in sync with `Settings.keys` in
  `Sources/MuseCore/Settings.swift` (plus `showMenuBarIcon` in `MenuBar.swift`).
- `Resources/launchagent.plist` is one template used twice: `make install` fills it with sed,
  and the Launch at Login toggle fills it from the copy inside the app bundle.
