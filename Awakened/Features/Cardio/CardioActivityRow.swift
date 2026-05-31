import SwiftUI

/// Compact row displaying a single cardio activity in a list
struct CardioActivityRow: View {
    let activity: CardioActivity
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(AppColors.vitalityColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: activity.icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.vitalityColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(activity.distanceFormatted)
                    Text("\u{2022}")
                    Text(activity.durationFormatted)
                    if activity.paceSecondsPerKm != nil {
                        Text("\u{2022}")
                        Text(activity.paceFormatted)
                    }
                }
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Right side: XP + date
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("+\(activity.xpEarned)")
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.vitalityColor)
                
                Text(activity.timeFormatted)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
