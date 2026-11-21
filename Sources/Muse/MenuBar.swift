// Menu bar icon and menu. Quick actions live here; detailed tuning is in the Settings window.
import Cocoa
import Combine
import MuseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBar: MenuBar?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBar(model: SettingsModel(defaults: .standard, apply: applySettings))
    }

    // Opening Muse.app while it already runs: bring back a hidden icon and show Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBar?.setIconVisible(true)
        menuBar?.openSettings()
        return false
    }
}

final class MenuBar: NSObject, NSMenuDelegate {
    static let showIconKey = "showMenuBarIcon"

    let model: SettingsModel
    let loginAgent: LoginAgent?
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var settingsWindow: SettingsWindow?
    private var observer: AnyCancellable?

    init(model: SettingsModel) {
        self.model = model
        let home = FileManager.default.homeDirectoryForCurrentUser
        let bundleID = Bundle.main.bundleIdentifier ?? "io.github.singhchinmayy.Muse"
        if let url = Bundle.main.url(forResource: "launchagent", withExtension: "plist"),
           let template = try? String(contentsOf: url, encoding: .utf8) {
            loginAgent = LoginAgent(
                plistURL: home.appendingPathComponent("Library/LaunchAgents/\(bundleID).plist"),
                template: template, appPath: Bundle.main.bundlePath,
                logPath: home.appendingPathComponent("Library/Logs/Muse.log").path)
        } else {
            loginAgent = nil   // running outside the app bundle (e.g. swift run)
        }
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        let d = UserDefaults.standard
        setIconVisible(d.object(forKey: Self.showIconKey) == nil || d.bool(forKey: Self.showIconKey))
        // Keep the icon in step with the Enabled switch, wherever it was flipped.
        observer = model.$settings.receive(on: RunLoop.main).sink { [weak self] _ in self?.updateIcon() }
    }

    var status: Status {
        Status(trusted: AXIsProcessTrusted(), mouseConnected: magicMouseConnected(), enabled: model.settings.enabled)
    }

    func setIconVisible(_ visible: Bool) {
        UserDefaults.standard.set(visible, forKey: Self.showIconKey)
        if visible, statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem?.menu = menu
            updateIcon()
        } else if !visible, let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        let s = Status(trusted: true, mouseConnected: true, enabled: model.settings.enabled)
        let image = NSImage(systemSymbolName: s.symbolName, accessibilityDescription: "Muse")
            ?? NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Muse")
        image?.isTemplate = true
        button.image = image
        button.appearsDisabled = s.dimmed
    }

    // Rebuilt on every open so the status line and checkmarks are current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        model.reload()   // pick up `defaults write` changes
        let s = status
        menu.removeAllItems()

        let line = item(s.title, s.opensAccessibilitySettings ? #selector(openAccessibility) : nil)
        line.isEnabled = s.opensAccessibilitySettings
        menu.addItem(line)
        menu.addItem(.separator())
        menu.addItem(item("Enabled", #selector(toggleEnabled), on: model.settings.enabled))
        menu.addItem(item("Settings…", #selector(openSettings), key: ","))
        menu.addItem(.separator())
        let login = item("Launch at Login", #selector(toggleLogin), on: loginAgent?.isEnabled ?? false)
        login.isEnabled = loginAgent != nil
        menu.addItem(login)
        menu.addItem(item("Hide Menu Bar Icon", #selector(hideIcon)))
        menu.addItem(.separator())
        menu.addItem(item("Quit Muse", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector?, on: Bool? = nil, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        if let on { i.state = on ? .on : .off }
        return i
    }

    @objc func toggleEnabled() { model.settings.enabled.toggle() }

    @objc func openSettings() {
        model.reload()
        if settingsWindow == nil { settingsWindow = SettingsWindow(model: model) }
        settingsWindow?.show()
    }

    @objc func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc func toggleLogin() {
        guard let agent = loginAgent else { return }
        do { try agent.setEnabled(!agent.isEnabled) } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    @objc func hideIcon() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Hide the Muse icon?"
        alert.informativeText = "Muse keeps running. To bring the icon back, open Muse again from Spotlight or Finder."
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { setIconVisible(false) }
    }

    @objc func quit() { NSApp.terminate(nil) }
}
