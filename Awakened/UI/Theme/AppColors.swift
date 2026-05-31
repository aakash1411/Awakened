import SwiftUI

/// Centralized color palette for the Awakened app.
///
/// **Themable colors** (background, surface, text, primary accent, semantic) are
/// pulled from `ThemeManager.shared.current` so they update when the user
/// switches themes. The root view tree is keyed on `themeManager.current.id`
/// to force a full re-render on theme change.
///
/// **Identity colors** (stat colors, rank colors, glow) stay constant — they
/// encode meaning, not styling, and shouldn't shift across themes.
struct AppColors {
    
    // MARK: - Themed (driven by ThemeManager)
    
    private static var theme: AppTheme { ThemeManager.shared.current }
    
    static var background: Color { theme.background }
    static var backgroundGradient: LinearGradient { theme.backgroundGradient }
    static var surface: Color { theme.surface }
    static var surfaceElevated: Color { theme.surfaceElevated }
    static var border: Color { theme.border }
    
    static var primaryBlue: Color { theme.primary }
    static var accentPurple: Color { theme.accent }
    static var accentCyan: Color { theme.primaryLight }
    static var glowBlue: Color { theme.primary.opacity(0.6) }
    
    static var textPrimary: Color { theme.textPrimary }
    static var textSecondary: Color { theme.textSecondary }
    static var textTertiary: Color { theme.textTertiary }
    static var textDisabled: Color { theme.textDisabled }
    
    static var success: Color { theme.success }
    static var warning: Color { theme.warning }
    static var error: Color { theme.error }
    static var info: Color { theme.primaryLight }
    
    static var xpBarGradient: LinearGradient {
        LinearGradient(
            colors: [theme.primary, theme.primaryLight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Stat Colors (identity, theme-independent)
    
    /// Strength — red
    static let strengthColor    = Color(hex: "FF3B30")
    /// Agility — green
    static let agilityColor     = Color(hex: "34C759")
    /// Vitality — orange
    static let vitalityColor    = Color(hex: "FF9500")
    /// Sense — purple
    static let senseColor       = Color(hex: "AF52DE")
    /// Intelligence — blue
    static let intelligenceColor = Color(hex: "5AC8FA")
    
    // MARK: - Rank Colors (identity)
    
    static let rankE   = Color(hex: "8E8E93")
    static let rankD   = Color(hex: "5AC8FA")
    static let rankC   = Color(hex: "34C759")
    static let rankB   = Color(hex: "FFCC00")
    static let rankA   = Color(hex: "FF9500")
    static let rankS   = Color(hex: "FF3B30")
    static let rankSS  = Color(hex: "AF52DE")
    static let rankSSS = Color(hex: "FFD700")
}

