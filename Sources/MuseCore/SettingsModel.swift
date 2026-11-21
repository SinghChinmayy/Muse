import Combine
import Foundation

public final class SettingsModel: ObservableObject {
    @Published public var settings: Settings
    private let defaults: UserDefaults
    private let apply: (Settings) -> Void

    public init(defaults: UserDefaults, apply: @escaping (Settings) -> Void) {
        self.defaults = defaults; self.apply = apply
        settings = Settings.load(from: defaults)
    }
}
