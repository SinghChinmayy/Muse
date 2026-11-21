import Combine
import Foundation

/// Shared by the menu and the Settings window. Every edit is saved to defaults and pushed to the engine.
public final class SettingsModel: ObservableObject {
    @Published public var settings: Settings {
        didSet { settings.save(to: defaults); apply(settings) }
    }
    private let defaults: UserDefaults
    private let apply: (Settings) -> Void

    public init(defaults: UserDefaults, apply: @escaping (Settings) -> Void) {
        self.defaults = defaults; self.apply = apply
        settings = Settings.load(from: defaults)
    }
}
