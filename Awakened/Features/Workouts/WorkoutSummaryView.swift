import SwiftUI
import SwiftData

/// Post-workout summary showing XP earned, volume, PRs, and duration
struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: WorkoutSession
    
    @State private var animateXP = false
    @State private var animatePR = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Completion header
                    completionHeader
                    
                    // Stats grid
                    statsGrid
                    
                    // XP earned
                    xpCard
                    
                    // PRs achieved
                    if session.prCount > 0 {
                        prCard
                    }
                    
                    // Exercise breakdown
                    exerciseBreakdown
                    
                    // Done button
                    doneButton
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Workout Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateXP = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                animatePR = true
            }
        }
    }
    
    // MARK: - Completion Header
    
    private var completionHeader: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.primaryBlue)
            }
            
            Text(session.name)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Great workout! Here's your summary.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.md) {
            SummaryStat(label: "Duration", value: session.durationFormatted, icon: "timer")
            SummaryStat(label: "Volume", value: session.volumeFormatted, icon: "scalemass.fill")
            SummaryStat(label: "Sets", value: "\(session.totalSetCount)", icon: "list.number")
            SummaryStat(label: "Exercises", value: "\(session.exerciseCount)", icon: "dumbbell.fill")
            SummaryStat(label: "Working Sets", value: "\(session.workingSetCount)", icon: "flame.fill")
            SummaryStat(label: "PRs", value: "\(session.prCount)", icon: "trophy.fill")
        }
    }
    
    // MARK: - XP Card
    
    private var xpCard: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AppColors.strengthColor)
                Text("Strength XP Earned")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            Text("+\(session.xpEarned)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.strengthColor)
                .scaleEffect(animateXP ? 1 : 0.3)
                .opacity(animateXP ? 1 : 0)
            
            if session.xpEarned >= WorkoutXPService.sessionXPCap {
                Text("Session XP cap reached!")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.strengthColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - PR Card
    
    private var prCard: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Personal Records!")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(session.prCount) new")
                    .font(AppFonts.caption1)
                    .foregroundColor(.yellow)
            }
            
            Text("You set \(session.prCount) new personal \(session.prCount == 1 ? "record" : "records") this workout!")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.cardPadding)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(animatePR ? 1 : 0.8)
        .opacity(animatePR ? 1 : 0)
    }
    
    // MARK: - Exercise Breakdown
    
    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("EXERCISE BREAKDOWN")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(session.exerciseGroups, id: \.name) { group in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Text("\(group.sets.count) sets")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Best set
                    if let best = group.sets.max(by: { $0.volume < $1.volume }) {
                        Text("\(best.weightFormatted) kg × \(best.reps)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.vertical, 4)
                
                if group.name != session.exerciseGroups.last?.name {
                    Divider().overlay(AppColors.border)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.primaryBlue)
                .cornerRadius(14)
        }
    }
}

// MARK: - Summary Stat

private struct SummaryStat: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryBlue)
            
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

#Preview("Workout Summary") {
    NavigationStack {
        WorkoutSummaryView(session: {
            let s = WorkoutSession(name: "Push Day", durationSeconds: 4500, isCompleted: true, xpEarned: 345, prCount: 2)
            return s
        }())
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSet.self])
}
