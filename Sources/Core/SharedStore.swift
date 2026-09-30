import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case pt, en
    var id: String { rawValue }
    var label: String { self == .pt ? "PT" : "EN" }
    var flag: String { self == .pt ? "🇵🇹" : "🇬🇧" }
    var nativeName: String { self == .pt ? "Português" : "English" }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

struct Preferences: Codable, Equatable {
    var language: AppLanguage = .pt
    var theme: AppTheme = .system
    var soundEnabled = true
    var musicEnabled = true
    var hapticsEnabled = true
    var notificationsEnabled = true
    var demoMode = false
    var iCloudSync = true

    init() {}

    /// Tolerates saves written before a field existed.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .pt
        theme = try c.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        musicEnabled = try c.decodeIfPresent(Bool.self, forKey: .musicEnabled) ?? true
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        notificationsEnabled = try c.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        demoMode = try c.decodeIfPresent(Bool.self, forKey: .demoMode) ?? false
        iCloudSync = try c.decodeIfPresent(Bool.self, forKey: .iCloudSync) ?? true
    }

    var speed: Double { demoMode ? 60 : 1 }
}

/// Saved game and preferences, kept in the App Group so the widget reads
/// exactly what the app wrote: the pet, and the language to describe it in.
struct SharedStore {

    static let appGroup = "group.dev.ividi.itamagotchi"
    private static let saveKey = "game.save.v1"
    private static let unreadableKey = "game.save.unreadable"
    private static let preferencesKey = "preferences.v1"

    let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.appGroup) ?? .standard
    }

    func loadSave() -> GameSave? {
        guard let data = defaults.data(forKey: Self.saveKey) else { return nil }
        if let save = try? JSONDecoder().decode(GameSave.self, from: data) { return save }
        // Kept aside before a fresh game overwrites it, so it can be rescued.
        if defaults.data(forKey: Self.unreadableKey) == nil {
            defaults.set(data, forKey: Self.unreadableKey)
        }
        return nil
    }

    func save(_ save: GameSave) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        defaults.set(data, forKey: Self.saveKey)
    }

    func loadPreferences() -> Preferences {
        guard let data = defaults.data(forKey: Self.preferencesKey),
              let prefs = try? JSONDecoder().decode(Preferences.self, from: data)
        else { return Preferences() }
        return prefs
    }

    func save(_ preferences: Preferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: Self.preferencesKey)
    }

    func reset() {
        defaults.removeObject(forKey: Self.saveKey)
    }
}
