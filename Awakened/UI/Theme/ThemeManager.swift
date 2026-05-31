import SwiftUI
import Combine

/// Manages the active visual theme for the entire app.
/// Persists user choice (preset id or full custom theme JSON) in UserDefaults.
///
/// View hierarchies should observe this via `@EnvironmentObject` and use
/// `.id(themeManager.current.id)` on the root view tree to force a redraw
/// when the theme changes.
@MainActor
final class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @Published private(set) var current: AppTheme {
        didSet { persist() }
    }
    
    private let presetKey   = "selectedThemeID"
    private let customKey   = "customThemeJSON"
    
    private init() {
        // Try custom theme first, then preset id, else default
        if let data = UserDefaults.standard.data(forKey: Self.customThemeKey),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.current = theme
            return
        }
        let presetID = UserDefaults.standard.string(forKey: Self.presetThemeKey) ?? AppTheme.awakened.id
        self.current = AppTheme.presets.first(where: { $0.id == presetID }) ?? .awakened
    }
    
    /// UserDefaults key for the selected preset id (used when the active theme is a preset)
    static let presetThemeKey = "selectedThemeID"
    /// UserDefaults key for the full custom theme JSON (used when the active theme is custom)
    static let customThemeKey = "customThemeJSON"
    
    /// Apply a preset theme by id (matched against `AppTheme.presets`).
    func setPreset(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.removeObject(forKey: Self.customThemeKey)
        UserDefaults.standard.set(theme.id, forKey: Self.presetThemeKey)
    }
    
    /// Apply a fully custom theme (persists the entire AppTheme as JSON).
    func setCustom(_ theme: AppTheme) {
        var t = theme
        t.id = "custom"
        t.displayName = theme.displayName.isEmpty ? "Custom" : theme.displayName
        current = t
    }
    
    /// True when the active theme is a built-in preset (not user-customized).
    var isUsingPreset: Bool {
        current.id != "custom"
    }
    
    /// Persist the current theme. Called via `didSet`.
    private func persist() {
        if current.id == "custom" {
            if let data = try? JSONEncoder().encode(current) {
                UserDefaults.standard.set(data, forKey: Self.customThemeKey)
            }
            UserDefaults.standard.removeObject(forKey: Self.presetThemeKey)
        } else {
            UserDefaults.standard.set(current.id, forKey: Self.presetThemeKey)
            UserDefaults.standard.removeObject(forKey: Self.customThemeKey)
        }
    }
}
