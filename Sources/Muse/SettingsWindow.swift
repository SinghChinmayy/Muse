// Settings window: detailed tuning. Floats above other windows so it stays visible
// while you try the mouse; every change applies immediately.
import Cocoa
import SwiftUI
import MuseCore

final class SettingsWindow {
    private let window: NSWindow

    init(model: SettingsModel) {
        let host = NSHostingController(rootView: SettingsView(model: model))
        host.sizingOptions = .preferredContentSize
        window = NSWindow(contentViewController: host)
        window.title = "Muse Settings"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Muse enabled", isOn: $model.settings.enabled)
            }
            Section("Cursor") {
                Toggle("Move cursor with one finger", isOn: $model.settings.cursorEnabled)
                Group {
                    SliderRow(title: "Speed", value: $model.settings.cursorSpeed, range: 0.25...3, step: 0.05, format: "%.2f×")
                    SliderRow(title: "Acceleration", value: $model.settings.cursorAccel, range: 0...3, step: 0.1, format: "%.1f")
                    SliderRow(title: "Deadzone", value: $model.settings.deadzone, range: 0...0.1, step: 0.005, format: "%.3f")
                    Toggle("Invert horizontal", isOn: $model.settings.invertX)
                    Toggle("Invert vertical", isOn: $model.settings.invertY)
                }
                .disabled(!model.settings.cursorEnabled)
            }
            .disabled(!model.settings.enabled)
            Section {
                HStack {
                    Spacer()
                    Button("Reset to Defaults") { model.reset() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        // Round so slider steps land on clean values (1.0 stays 1.0 and is saved as "default").
        let rounded = Binding(get: { value }, set: { value = ($0 * 1000).rounded() / 1000 })
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value)).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: rounded, in: range, step: step)
        }
    }
}
