import SwiftUI

/// Weekly recap sheet showing summary stats with animated counters
struct WeeklyRecapView: View {
    let recap: WeeklyRecap
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Text("Weekly Recap")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(recap.weekRangeFormatted)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.xxl)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    // XP earned
                    VStack(spacing: 4) {
                        Text("+\(recap.totalXP)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlue)
                        Text("Total XP Earned")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    
                    // Level
                    if recap.didLevelUp {
                        HStack(spacing: AppSpacing.md) {
                            Text("Lv.\(recap.levelFrom)")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Image(systemName: "arrow.right")
                                .foregroundColor(AppColors.accentPurple)
                            Text("Lv.\(recap.levelTo)")
                                .font(AppFonts.title2)
                                .foregroundColor(AppColors.accentPurple)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.accentPurple.opacity(0.15))
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                        recapStat(value: "\(recap.questsCompleted)", label: "Quests Done", icon: "checkmark.circle.fill", color: AppColors.success)
                        recapStat(value: "\(recap.workoutsLogged)", label: "Workouts", icon: "dumbbell.fill", color: AppColors.strengthColor)
                        recapStat(value: String(format: "%.1f km", recap.cardioDistanceKm), label: "Distance", icon: "figure.run", color: AppColors.vitalityColor)
                        recapStat(value: String(format: "%.0f min", recap.meditationMinutes), label: "Meditation", icon: "brain.head.profile", color: AppColors.senseColor)
                        recapStat(value: String(format: "%.0f min", recap.readingMinutes), label: "Reading", icon: "book.fill", color: AppColors.intelligenceColor)
                        recapStat(value: "\(recap.streakDays) days", label: "Streak", icon: "flame.fill", color: .orange)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    
                    // Failed quests
                    if recap.questsFailed > 0 {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.error)
                            Text("\(recap.questsFailed) quests failed")
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.error)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Achievements
                    if !recap.achievementsUnlocked.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Achievements Unlocked")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            ForEach(recap.achievementsUnlocked, id: \.self) { title in
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(.yellow)
                                    Text(title)
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Dismiss
                    Button {
                        dismiss()
                    } label: {
                        Text("Let's Go")
                            .font(AppFonts.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.primaryBlue)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .padding(.top, AppSpacing.md)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
    
    private func recapStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.title3)
                .foregroundColor(.white)
            
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
