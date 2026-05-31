import SwiftUI

/// A theme defines the colorway of the entire app.
/// Stat colors, rank colors, and zone colors stay constant across themes
/// (they encode identity); the theme controls neutrals + primary accent.
struct AppTheme: Equatable, Codable, Identifiable {
    var id: String
    var displayName: String
    var isDark: Bool
    
    // Backgrounds & surfaces
    var backgroundHex: String
    var backgroundGradientTopHex: String
    var backgroundGradientBottomHex: String
    var surfaceHex: String
    var surfaceElevatedHex: String
    var borderHex: String
    
    // Primary palette
    var primaryHex: String
    var primaryDarkHex: String
    var primaryLightHex: String
    var accentHex: String
    
    // Text
    var textPrimaryHex: String
    var textSecondaryHex: String
    var textTertiaryHex: String
    var textDisabledHex: String
    
    // Semantic
    var successHex: String
    var warningHex: String
    var errorHex: String
    
    // MARK: - Color accessors
    
    var background: Color { Color(hex: backgroundHex) }
    var backgroundGradientTop: Color { Color(hex: backgroundGradientTopHex) }
    var backgroundGradientBottom: Color { Color(hex: backgroundGradientBottomHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var surfaceElevated: Color { Color(hex: surfaceElevatedHex) }
    var border: Color { Color(hex: borderHex) }
    
    var primary: Color { Color(hex: primaryHex) }
    var primaryDark: Color { Color(hex: primaryDarkHex) }
    var primaryLight: Color { Color(hex: primaryLightHex) }
    var accent: Color { Color(hex: accentHex) }
    
    var textPrimary: Color { Color(hex: textPrimaryHex) }
    var textSecondary: Color { Color(hex: textSecondaryHex) }
    var textTertiary: Color { Color(hex: textTertiaryHex) }
    var textDisabled: Color { Color(hex: textDisabledHex) }
    
    var success: Color { Color(hex: successHex) }
    var warning: Color { Color(hex: warningHex) }
    var error: Color { Color(hex: errorHex) }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientTop, backgroundGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Presets
    
    /// Default Solo-Leveling-inspired dark holographic theme (the original look)
    static let awakened = AppTheme(
        id: "awakened",
        displayName: "Awakened (Default)",
        isDark: true,
        backgroundHex: "0A1628",
        backgroundGradientTopHex: "0D1B2A",
        backgroundGradientBottomHex: "051014",
        surfaceHex: "132238",
        surfaceElevatedHex: "1B3A5C",
        borderHex: "1E3A5F",
        primaryHex: "007AFF",
        primaryDarkHex: "0055B3",
        primaryLightHex: "4DA3FF",
        accentHex: "9C27B0",
        textPrimaryHex: "FFFFFF",
        textSecondaryHex: "B0BEC5",
        textTertiaryHex: "607D8B",
        textDisabledHex: "455A64",
        successHex: "4CAF50",
        warningHex: "FFC107",
        errorHex: "F44336"
    )
    
    /// Anime — purple/cyan dark (gamified)
    static let anime = AppTheme(
        id: "anime",
        displayName: "Gamified Anime",
        isDark: true,
        backgroundHex: "070812",
        backgroundGradientTopHex: "0E1024",
        backgroundGradientBottomHex: "050614",
        surfaceHex: "111326",
        surfaceElevatedHex: "1B1E3D",
        borderHex: "37305F",
        primaryHex: "8B5CF6",
        primaryDarkHex: "6D28D9",
        primaryLightHex: "C4B5FD",
        accentHex: "22D3EE",
        textPrimaryHex: "F4F0FF",
        textSecondaryHex: "C5BFE3",
        textTertiaryHex: "A5A3C7",
        textDisabledHex: "6E6A91",
        successHex: "22D3EE",
        warningHex: "F59E0B",
        errorHex: "EF4444"
    )
    
    /// Professional — clean blue/white light theme
    static let professional = AppTheme(
        id: "professional",
        displayName: "Professional",
        isDark: false,
        backgroundHex: "F8FAFC",
        backgroundGradientTopHex: "FFFFFF",
        backgroundGradientBottomHex: "EEF2F7",
        surfaceHex: "FFFFFF",
        surfaceElevatedHex: "F1F5F9",
        borderHex: "CBD5E1",
        primaryHex: "2563EB",
        primaryDarkHex: "1D4ED8",
        primaryLightHex: "60A5FA",
        accentHex: "10B981",
        textPrimaryHex: "111827",
        textSecondaryHex: "475569",
        textTertiaryHex: "64748B",
        textDisabledHex: "94A3B8",
        successHex: "10B981",
        warningHex: "F59E0B",
        errorHex: "EF4444"
    )
    
    /// Pastel — soft pink/lavender light theme
    static let pastel = AppTheme(
        id: "pastel",
        displayName: "Pastel",
        isDark: false,
        backgroundHex: "FFF7FC",
        backgroundGradientTopHex: "FFFFFF",
        backgroundGradientBottomHex: "FCE7F3",
        surfaceHex: "FFFFFF",
        surfaceElevatedHex: "FDF2F8",
        borderHex: "F5CBE2",
        primaryHex: "EC4899",
        primaryDarkHex: "BE185D",
        primaryLightHex: "F9A8D4",
        accentHex: "A855F7",
        textPrimaryHex: "3B2342",
        textSecondaryHex: "6B4D71",
        textTertiaryHex: "9A759F",
        textDisabledHex: "C4A6CB",
        successHex: "86EFAC",
        warningHex: "FDBA74",
        errorHex: "EF4444"
    )
    
    /// Built-in presets
    static let presets: [AppTheme] = [.awakened, .anime, .professional, .pastel]
}
