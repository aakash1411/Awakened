import SwiftUI

/// Reusable achievement badge card for the gallery grid
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Icon with tier ring
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.15) : AppColors.surface)
                    .frame(width: 56, height: 56)
                
                if achievement.isUnlocked {
                    Circle()
                        .stroke(achievement.tierColor, lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 22))
                    .foregroundColor(achievement.isUnlocked ? achievement.category.color : AppColors.textTertiary.opacity(0.4))
            }
            
            // Title
            Text(achievement.title)
                .font(AppFonts.caption1)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? AppColors.textPrimary : AppColors.textTertiary)
                .lineLimit(1)
            
            // Progress bar (if not unlocked)
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progress)
                    .tint(achievement.category.color.opacity(0.5))
                    .scaleEffect(y: 1.5)
                    .padding(.horizontal, AppSpacing.sm)
            } else {
                // Tier label
                Text(achievement.tierName)
                    .font(AppFonts.caption2)
                    .foregroundColor(achievement.tierColor)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}
