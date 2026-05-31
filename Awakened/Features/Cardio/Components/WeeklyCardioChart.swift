import SwiftUI

/// Bar chart showing daily cardio minutes for the current week
struct WeeklyCardioChart: View {
    let stats: WeeklyCardioStats
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    private var maxMinutes: Double {
        max(stats.dailyMinutes.max() ?? 1, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("THIS WEEK")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            HStack(alignment: .bottom, spacing: AppSpacing.xs) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: index))
                            .frame(height: barHeight(for: index))
                            .frame(maxWidth: .infinity)
                        
                        // Day label
                        Text(dayLabels[index])
                            .font(AppFonts.caption2)
                            .foregroundColor(isToday(index) ? AppColors.vitalityColor : AppColors.textTertiary)
                    }
                }
            }
            .frame(height: 80)
            
            // Summary row
            HStack(spacing: AppSpacing.lg) {
                WeeklyStat(
                    label: "Distance",
                    value: stats.totalDistanceFormatted,
                    icon: "location.fill"
                )
                WeeklyStat(
                    label: "Time",
                    value: stats.totalDurationFormatted,
                    icon: "clock.fill"
                )
                WeeklyStat(
                    label: "Sessions",
                    value: "\(stats.sessionCount)",
                    icon: "flame.fill"
                )
                if let pace = stats.averagePace, pace > 0 {
                    WeeklyStat(
                        label: "Avg Pace",
                        value: stats.averagePaceFormatted,
                        icon: "speedometer"
                    )
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Helpers
    
    private func barHeight(for index: Int) -> CGFloat {
        let minutes = stats.dailyMinutes[index]
        guard minutes > 0 else { return 4 }
        return max(4, CGFloat(minutes / maxMinutes) * 60)
    }
    
    private func barColor(for index: Int) -> Color {
        let minutes = stats.dailyMinutes[index]
        if minutes <= 0 {
            return AppColors.surface.opacity(0.5)
        }
        return isToday(index) ? AppColors.vitalityColor : AppColors.vitalityColor.opacity(0.6)
    }
    
    private func isToday(_ dayIndex: Int) -> Bool {
        let weekday = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        return dayIndex == weekday
    }
}

/// Small stat display for weekly summary
private struct WeeklyStat: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppColors.vitalityColor)
            Text(value)
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
