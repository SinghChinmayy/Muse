# Muse

macOS background app that makes the Magic Mouse surface work like a trackpad:
one finger moves the cursor, two fingers scroll, one-finger scrolling is blocked.

- Code: `Sources/main.swift` (one file). Uses the private `MultitouchSupport` framework and a
  `CGEventTap` on scroll events.
- Build and install with the `Makefile` (`make install`). Bundle ID, defaults domain and
  LaunchAgent label are all `io.github.singhchinmayy.Muse`.
- Every rebuild changes the ad-hoc signature, so Accessibility must be granted again.
  Prefer tunables in `defaults` over code changes for feel tweaks.
- Keep the settings table in `README.md` in sync with the `prefs` keys in `main.swift`.
