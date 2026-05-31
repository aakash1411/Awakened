import SwiftUI

/// Dashboard card showing today's HealthKit data at a glance
struct HealthSummaryCard: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var syncEngine: HealthSyncEngine
    
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("Today's Activity")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                // Sync button
                Button {
                    Task {
                        await syncEngine.syncAll()
                    }
                } label: {
                    if syncEngine.isSyncing {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
                .disabled(syncEngine.isSyncing)
            }
            
            // Metrics grid
            VStack(spacing: AppSpacing.sm) {
                // Steps
                HealthMetricRow(
                    icon: "figure.walk",
                    label: "Steps",
                    value: formatNumber(syncEngine.todaySteps),
                    target: "10,000",
                    progress: Double(syncEngine.todaySteps) / 10000.0,
                    color: AppColors.agilityColor,
                    isComplete: syncEngine.todaySteps >= 10000
                )
                
                // Sleep
                HealthMetricRow(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: String(format: "%.1fh", syncEngine.todaySleepHours),
                    target: "7.0h",
                    progress: syncEngine.todaySleepHours / 7.0,
                    color: AppColors.accentPurple,
                    isComplete: syncEngine.todaySleepHours >= 7.0
                )
                
                // Workouts
                HealthMetricRow(
                    icon: "flame.fill",
                    label: "Workout",
                    value: "\(Int(syncEngine.todayWorkoutMinutes)) min",
                    target: "30 min",
                    progress: syncEngine.todayWorkoutMinutes / 30.0,
                    color: AppColors.strengthColor,
                    isComplete: syncEngine.todayWorkoutMinutes >= 30
                )
                
                // Mindful minutes
                HealthMetricRow(
                    icon: "brain.head.profile",
                    label: "Mindful",
                    value: "\(Int(syncEngine.todayMindfulMinutes)) min",
                    target: "10 min",
                    progress: syncEngine.todayMindfulMinutes / 10.0,
                    color: AppColors.senseColor,
                    isComplete: syncEngine.todayMindfulMinutes >= 10
                )
            }
            
            // Bottom row: HR + Energy + Last sync
            HStack(spacing: AppSpacing.lg) {
                if let avgHR = syncEngine.averageHeartRate {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.strengthColor)
                        Text("\(Int(avgHR)) bpm")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                if syncEngine.todayActiveEnergy > 0 {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.warning)
                        Text("\(Int(syncEngine.todayActiveEnergy)) kcal")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let lastSync = syncEngine.lastSyncDate {
                    Text(lastSyncText(from: lastSync))
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Error banner
            if let error = syncEngine.syncError {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.warning)
                        .font(.system(size: 12))
                    
                    Text(error)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.warning)
                        .lineLimit(1)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            HealthDetailView(syncEngine: syncEngine)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func lastSyncText(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else {
            return "\(Int(seconds / 3600))h ago"
        }
    }
}

// MARK: - Health Metric Row

struct HealthMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let target: String
    let progress: Double
    let color: Color
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            // Label + value
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(value) / \(target)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.success)
                    }
                }
                
                // Progress bar
                XPProgressBar(
                    progress: min(progress, 1.0),
                    color: isComplete ? AppColors.success : color,
                    height: 4,
                    showShine: false
                )
            }
        }
    }
}

// MARK: - No Health Connection Card

/// Shown when HealthKit is not authorized
struct HealthNotConnectedCard: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Apple Health")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Auto-track steps, workouts, sleep & more")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Button(action: onConnect) {
                Text("Connect")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.primaryBlue)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Health Summary") {
    VStack {
        HealthNotConnectedCard {
            print("Connect")
        }
    }
    .padding()
    .background(AppColors.background)
}
