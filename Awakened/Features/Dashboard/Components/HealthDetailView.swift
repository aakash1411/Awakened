import SwiftUI
import HealthKit

/// Expanded view showing detailed HealthKit data
struct HealthDetailView: View {
    @ObservedObject var syncEngine: HealthSyncEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Steps section
                        HealthDetailSection(
                            title: "Steps",
                            icon: "figure.walk",
                            color: AppColors.agilityColor
                        ) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(formatNumber(syncEngine.todaySteps))
                                    .font(AppFonts.statValueMedium)
                                    .foregroundColor(AppColors.agilityColor)
                                
                                XPProgressBar(
                                    progress: Double(syncEngine.todaySteps) / 10000.0,
                                    color: AppColors.agilityColor,
                                    height: 10
                                )
                                
                                HStack {
                                    Text("Goal: 10,000 steps")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("XP: +\(XPCalculator.stepsXP(steps: syncEngine.todaySteps))")
                                        .font(AppFonts.xpNumberSmall)
                                        .foregroundColor(AppColors.success)
                                }
                                
                                if syncEngine.todayDistance > 0 {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textTertiary)
                                        Text(String(format: "%.1f km distance", syncEngine.todayDistance))
                                            .font(AppFonts.caption1)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Sleep section
                        HealthDetailSection(
                            title: "Sleep",
                            icon: "bed.double.fill",
                            color: AppColors.accentPurple
                        ) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(alignment: .bottom, spacing: AppSpacing.xxs) {
                                    Text(String(format: "%.1f", syncEngine.todaySleepHours))
                                        .font(AppFonts.statValueMedium)
                                        .foregroundColor(AppColors.accentPurple)
                                    
                                    Text("hours")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                        .padding(.bottom, 6)
                                }
                                
                                XPProgressBar(
                                    progress: syncEngine.todaySleepHours / 7.0,
                                    color: AppColors.accentPurple,
                                    height: 10
                                )
                                
                                HStack {
                                    Text("Goal: 7-9 hours")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    let sleepXP = XPCalculator.sleepXP(hours: syncEngine.todaySleepHours)
                                    Text("XP: +\(sleepXP)")
                                        .font(AppFonts.xpNumberSmall)
                                        .foregroundColor(sleepXP > 0 ? AppColors.success : AppColors.textTertiary)
                                }
                                
                                // Sleep quality indicator
                                if syncEngine.todaySleepHours > 0 {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: sleepQualityIcon)
                                            .foregroundColor(sleepQualityColor)
                                        Text(sleepQualityText)
                                            .font(AppFonts.caption1)
                                            .foregroundColor(sleepQualityColor)
                                    }
                                }
                            }
                        }
                        
                        // Workouts section
                        HealthDetailSection(
                            title: "Workouts",
                            icon: "flame.fill",
                            color: AppColors.strengthColor
                        ) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(syncEngine.todayWorkoutCount)")
                                            .font(AppFonts.statValueSmall)
                                            .foregroundColor(AppColors.strengthColor)
                                        Text("workouts")
                                            .font(AppFonts.caption1)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(syncEngine.todayWorkoutMinutes))")
                                            .font(AppFonts.statValueSmall)
                                            .foregroundColor(AppColors.vitalityColor)
                                        Text("minutes")
                                            .font(AppFonts.caption1)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                
                                XPProgressBar(
                                    progress: syncEngine.todayWorkoutMinutes / 30.0,
                                    color: AppColors.strengthColor,
                                    height: 10
                                )
                                
                                Text("Goal: 30 minutes")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        // Mindfulness section
                        HealthDetailSection(
                            title: "Mindfulness",
                            icon: "brain.head.profile",
                            color: AppColors.senseColor
                        ) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(alignment: .bottom, spacing: AppSpacing.xxs) {
                                    Text("\(Int(syncEngine.todayMindfulMinutes))")
                                        .font(AppFonts.statValueMedium)
                                        .foregroundColor(AppColors.senseColor)
                                    
                                    Text("min")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                        .padding(.bottom, 6)
                                }
                                
                                XPProgressBar(
                                    progress: syncEngine.todayMindfulMinutes / 10.0,
                                    color: AppColors.senseColor,
                                    height: 10
                                )
                                
                                Text("Goal: 10 minutes")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        // Active Energy section
                        HealthDetailSection(
                            title: "Active Energy",
                            icon: "bolt.fill",
                            color: AppColors.warning
                        ) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(Int(syncEngine.todayActiveEnergy))")
                                        .font(AppFonts.statValueSmall)
                                        .foregroundColor(AppColors.warning)
                                    Text("kcal burned")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("XP: +\(XPCalculator.activeEnergyXP(kcal: syncEngine.todayActiveEnergy))")
                                    .font(AppFonts.xpNumberSmall)
                                    .foregroundColor(AppColors.success)
                            }
                        }
                        
                        // Body metrics section (if available)
                        if syncEngine.currentWeight != nil || syncEngine.currentBodyFat != nil {
                            HealthDetailSection(
                                title: "Body Metrics",
                                icon: "scalemass.fill",
                                color: AppColors.primaryBlue
                            ) {
                                HStack(spacing: AppSpacing.xl) {
                                    if let weight = syncEngine.currentWeight {
                                        VStack {
                                            Text(String(format: "%.1f", weight))
                                                .font(AppFonts.statValueSmall)
                                                .foregroundColor(AppColors.primaryBlue)
                                            Text("kg")
                                                .font(AppFonts.caption1)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    
                                    if let bodyFat = syncEngine.currentBodyFat {
                                        VStack {
                                            Text(String(format: "%.1f%%", bodyFat * 100))
                                                .font(AppFonts.statValueSmall)
                                                .foregroundColor(AppColors.primaryBlue)
                                            Text("body fat")
                                                .font(AppFonts.caption1)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Health Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
    }
    
    // MARK: - Sleep Quality Helpers
    
    private var sleepQualityIcon: String {
        if syncEngine.todaySleepHours >= 7 && syncEngine.todaySleepHours <= 9 {
            return "checkmark.circle.fill"
        } else if syncEngine.todaySleepHours >= 6 {
            return "minus.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var sleepQualityColor: Color {
        if syncEngine.todaySleepHours >= 7 && syncEngine.todaySleepHours <= 9 {
            return AppColors.success
        } else if syncEngine.todaySleepHours >= 6 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
    
    private var sleepQualityText: String {
        if syncEngine.todaySleepHours >= 7 && syncEngine.todaySleepHours <= 9 {
            return "Optimal sleep"
        } else if syncEngine.todaySleepHours >= 6 {
            return "Could use more rest"
        } else {
            return "Insufficient sleep"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Health Detail Section

struct HealthDetailSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            content()
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
