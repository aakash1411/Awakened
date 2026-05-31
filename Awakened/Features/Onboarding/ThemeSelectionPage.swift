import SwiftUI

/// Onboarding step: pick a starting theme. Tapping a card applies it instantly
/// so the user sees the rest of onboarding in the chosen palette.
struct ThemeSelectionPage: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primaryBlue)
                
                Text("Pick Your Vibe")
                    .font(AppFonts.title1)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Choose a theme to start with — you can change it anytime in Settings.")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            
            // 2x2 grid of presets
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: AppSpacing.md),
                          GridItem(.flexible(), spacing: AppSpacing.md)],
                spacing: AppSpacing.md
            ) {
                ForEach(AppTheme.presets) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: themeManager.current.id == theme.id
                    ) {
                        themeManager.setPreset(theme)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            
            Text("Theme: \(themeManager.current.displayName)")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
            
            Spacer()
            Spacer()
        }
    }
}
