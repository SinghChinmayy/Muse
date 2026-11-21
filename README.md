<p align="center"><img src="assets/logo.png" width="160" alt="Muse logo"></p>

<h1 align="center">Muse</h1>

<p align="center">Use your Magic Mouse like a tiny trackpad on macOS.</p>

- **One finger slides the cursor**, like on a trackpad, so you don't have to move the mouse.
- **Two fingers scroll.** Scrolling with one finger is turned off.
- Moving the mouse still moves the cursor as usual. Trackpads and normal scroll-wheel mice aren't affected.

Muse runs in the background with no window or menu bar icon, and it doesn't use the network.

## Install

Needs macOS 13 or later and the Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/SinghChinmayy/Muse.git
cd Muse
make install
```

This builds `Muse.app`, copies it to `~/Applications` and adds a login item so it starts on login.
Then turn on **Muse** in **System Settings → Privacy & Security → Accessibility**. It starts working
within a couple of seconds.

Each build gets a new ad-hoc signature, so after you reinstall you may need to turn Muse off and
on again in Accessibility.

## Settings

Change settings with `defaults`, then run `make restart`:

| Key | Default | What it does |
|---|---|---|
| `cursorEnabled` | `true` | One-finger cursor movement on or off |
| `cursorSpeed` | `1.0` | Cursor speed |
| `cursorAccel` | `1.0` | Extra speed for fast swipes (`0` = none) |
| `deadzone` | `0.03` | How far a finger has to slide before the cursor moves (stops jitter when clicking) |
| `invertX` / `invertY` | `false` | Flip a direction |

```sh
defaults write io.github.singhchinmayy.Muse cursorSpeed 1.5
defaults write io.github.singhchinmayy.Muse invertY -bool true
make restart
```

## Commands

| Command | What it does |
|---|---|
| `make` | Build `build/Muse.app` |
| `make install` | Build, install to `~/Applications` and start at login |
| `make uninstall` | Remove the app, the login item and the Accessibility entry |
| `make restart` | Restart Muse (after changing a setting) |
| `make logs` | Follow `~/Library/Logs/Muse.log` |
| `make probe` | List touch devices and show which one is the Magic Mouse |

To debug, stop the login item with `launchctl bootout gui/$(id -u)/io.github.singhchinmayy.Muse`, then run
`~/Applications/Muse.app/Contents/MacOS/Muse --debug`. It prints finger counts, cursor moves and blocked scrolls.

## How it works

Muse reads raw touches from the Magic Mouse through Apple's private `MultitouchSupport` framework.

- With **one finger** on the surface, it turns the finger's movement into cursor movement and drops
  the scroll events macOS would normally send.
- With **two or more fingers**, it lets scrolling (and momentum) through.

Because it uses a private framework, a future macOS update could break it.

## Works with

Gesture apps such as [MagicMousePad](https://github.com/rzrizaldy/MagicMousePad) can add tap-to-click
and swipes alongside Muse. If a two-finger sideways swipe triggers back/forward while you scroll,
turn that swipe off in the other app.

## License

MIT. Not affiliated with Apple. Magic Mouse is a trademark of Apple Inc.
