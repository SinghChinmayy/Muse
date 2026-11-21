import Combine
import Foundation

/// Shared by the menu and the Settings window. Every edit is saved to defaults and pushed to the engine.
public final class SettingsModel: ObservableObject {
    @Published public var settings: Settings {
        didSet {
            if !reloading { settings.save(to: defaults) }
            apply(settings)
        }
    }
    private let defaults: UserDefaults
    private let apply: (Settings) -> Void
    private var reloading = false

    public init(defaults: UserDefaults, apply: @escaping (Settings) -> Void) {
        self.defaults = defaults; self.apply = apply
        settings = Settings.load(from: defaults)
    }

    /// Picks up `defaults write` changes made outside Muse. Called when the menu or window opens.
    public func reload() {
        reloading = true; defer { reloading = false }
        settings = Settings.load(from: defaults)
    }
}
