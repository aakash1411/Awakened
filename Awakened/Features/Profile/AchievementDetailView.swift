import SwiftUI

/// Detail view for a single achievement
struct AchievementDetailView: View {
    let achievement: Achievement
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Large icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.2) : AppColors.surface)
                        .frame(width: 120, height: 120)
                    
                    if achievement.isUnlocked {
                        Circle()
                            .stroke(achievement.tierColor, lineWidth: 3)
                            .frame(width: 120, height: 120)
                    }
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 44))
                        .foregroundColor(achievement.isUnlocked ? achievement.category.color : AppColors.textTertiary)
                }
                
                // Title & Tier
                VStack(spacing: AppSpacing.xs) {
                    Text(achievement.title)
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(achievement.tierName)
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(achievement.tierColor)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, 2)
                        .background(achievement.tierColor.opacity(0.15))
                        .cornerRadius(4)
                }
                
                // Description
                Text(achievement.achievementDescription)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                
                // Progress
                VStack(spacing: AppSpacing.sm) {
                    ProgressView(value: achievement.progress)
                        .tint(achievement.isUnlocked ? achievement.category.color : AppColors.textTertiary)
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Text(String(format: "%.0f / %.0f", achievement.progressValue, achievement.targetValue))
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.0f%%", achievement.progress * 100))
                            .font(AppFonts.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(achievement.isUnlocked ? achievement.category.color : AppColors.textTertiary)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                
                // Unlock date
                if let date = achievement.unlockDateFormatted {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Unlocked \(date)")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(AppSpacing.cardCornerRadius)
                }
                
                Spacer()
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
