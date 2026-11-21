import Foundation

/// A throwaway defaults domain so tests never touch the real Muse prefs.
func freshDefaults() -> UserDefaults {
    let name = "MuseTests-\(UUID().uuidString)"
    let d = UserDefaults(suiteName: name)!
    d.removePersistentDomain(forName: name)
    return d
}
