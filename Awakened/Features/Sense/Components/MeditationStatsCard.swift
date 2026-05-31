import SwiftUI

/// Compact stats card showing weekly meditation minutes, sessions, and streak
struct MeditationStatsCard: View {
    let weeklyMinutes: Double
    let weeklySessions: Int
    let streak: Int
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            statItem(
                value: String(format: "%.0f", weeklyMinutes),
                label: "Minutes",
                icon: "clock.fill"
            )
            
            statItem(
                value: "\(weeklySessions)",
                label: "Sessions",
                icon: "brain.head.profile"
            )
            
            statItem(
                value: "\(streak)",
                label: "Day Streak",
                icon: "flame.fill"
            )
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.senseColor)
            
            Text(value)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
