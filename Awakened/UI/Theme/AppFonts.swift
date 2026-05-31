import SwiftUI

/// Centralized typography for the Awakened app
/// Uses system fonts with rounded design for a friendly, game-like feel
struct AppFonts {
    
    // MARK: - Headers
    
    /// Large title - 34pt bold rounded (Screen titles)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    
    /// Title 1 - 28pt bold rounded (Section headers)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// Title 2 - 22pt bold rounded (Card titles)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    
    /// Title 3 - 20pt semibold rounded (Subsection headers)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // MARK: - Body Text
    
    /// Headline - 17pt semibold rounded (Emphasis)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    
    /// Body - 17pt regular default (Body text)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Callout - 16pt regular default (Secondary body)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Subheadline - 15pt regular default (Tertiary text)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    // MARK: - Small Text
    
    /// Footnote - 13pt regular default (Small labels)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Caption 1 - 12pt regular default (Captions)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Caption 2 - 11pt regular default (Smallest text)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Special (Stats, Numbers)
    
    /// Stat value - 48pt bold monospaced (Large stat numbers)
    static let statValue = Font.system(size: 48, weight: .bold, design: .monospaced)
    
    /// Stat value medium - 32pt bold monospaced (Medium stat numbers)
    static let statValueMedium = Font.system(size: 32, weight: .bold, design: .monospaced)
    
    /// Stat value small - 24pt bold monospaced (Small stat numbers)
    static let statValueSmall = Font.system(size: 24, weight: .bold, design: .monospaced)
    
    /// Stat label - 14pt medium rounded uppercase (Stat names)
    static let statLabel = Font.system(size: 14, weight: .medium, design: .rounded)
    
    /// Level number - 64pt heavy rounded (Level display)
    static let levelNumber = Font.system(size: 64, weight: .heavy, design: .rounded)
    
    /// Level number medium - 48pt heavy rounded (Medium level display)
    static let levelNumberMedium = Font.system(size: 48, weight: .heavy, design: .rounded)
    
    /// Rank letter - 24pt black rounded (Rank badge)
    static let rankLetter = Font.system(size: 24, weight: .black, design: .rounded)
    
    /// XP number - 16pt bold monospaced (XP values)
    static let xpNumber = Font.system(size: 16, weight: .bold, design: .monospaced)
    
    /// XP number small - 12pt bold monospaced (Small XP values)
    static let xpNumberSmall = Font.system(size: 12, weight: .bold, design: .monospaced)
}

// MARK: - Text Style View Modifiers

extension View {
    /// Apply stat value styling (large monospaced number)
    func statValueStyle() -> some View {
        self
            .font(AppFonts.statValue)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply stat label styling (uppercase, tracked)
    func statLabelStyle() -> some View {
        self
            .font(AppFonts.statLabel)
            .foregroundColor(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.5)
    }
    
    /// Apply title styling
    func titleStyle() -> some View {
        self
            .font(AppFonts.title1)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply headline styling
    func headlineStyle() -> some View {
        self
            .font(AppFonts.headline)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply body text styling
    func bodyStyle() -> some View {
        self
            .font(AppFonts.body)
            .foregroundColor(AppColors.textPrimary)
    }
    
    /// Apply secondary text styling
    func secondaryStyle() -> some View {
        self
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.textSecondary)
    }
    
    /// Apply caption styling
    func captionStyle() -> some View {
        self
            .font(AppFonts.caption1)
            .foregroundColor(AppColors.textTertiary)
    }
}
