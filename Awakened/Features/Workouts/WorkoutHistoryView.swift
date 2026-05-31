import SwiftUI
import SwiftData

/// Chronological list of past workout sessions
struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]
    
    @State private var selectedSession: WorkoutSession?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSession) { session in
            NavigationStack {
                WorkoutDetailSheet(session: session)
            }
        }
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(sessions) { session in
                    SessionRow(session: session) {
                        selectedSession = session
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.sm)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text("No workouts yet")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Complete your first workout to see it here")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: WorkoutSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(session.name)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text(session.date, style: .date)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                HStack(spacing: AppSpacing.md) {
                    Label(session.durationFormatted, systemImage: "timer")
                    Label("\(session.exerciseCount) exercises", systemImage: "dumbbell.fill")
                    Label(session.volumeFormatted, systemImage: "scalemass.fill")
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.strengthColor)
                        Text("+\(session.xpEarned) STR XP")
                            .font(AppFonts.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.strengthColor)
                    }
                    
                    if session.prCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(session.prCount) PRs")
                                .font(AppFonts.caption1)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Detail Sheet

private struct WorkoutDetailSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.sm) {
                        DetailStat(label: "Duration", value: session.durationFormatted)
                        DetailStat(label: "Volume", value: session.volumeFormatted)
                        DetailStat(label: "XP", value: "+\(session.xpEarned)")
                    }
                    
                    // Exercise groups
                    ForEach(session.exerciseGroups, id: \.name) { group in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(group.name)
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.primaryBlue)
                            
                            // Column headers
                            HStack {
                                Text("SET")
                                    .frame(width: 36, alignment: .leading)
                                Text("KG")
                                    .frame(width: 60, alignment: .center)
                                Text("REPS")
                                    .frame(width: 50, alignment: .center)
                                Spacer()
                                Text("VOL")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.textTertiary)
                            
                            ForEach(group.sets) { set in
                                HStack {
                                    HStack(spacing: 2) {
                                        Text("\(set.setNumber)")
                                            .frame(width: 20, alignment: .leading)
                                        if let badge = set.typeBadge {
                                            Text(badge)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(set.isWarmup ? .orange : .red)
                                        }
                                    }
                                    .frame(width: 36, alignment: .leading)
                                    
                                    Text(set.weightFormatted)
                                        .frame(width: 60, alignment: .center)
                                    
                                    Text("\(set.reps)")
                                        .frame(width: 50, alignment: .center)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f", set.volume))
                                        .frame(width: 60, alignment: .trailing)
                                }
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(set.isWarmup ? AppColors.textTertiary : AppColors.textPrimary)
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Notes
                    if !session.notes.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Notes")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(session.notes)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct DetailStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

#Preview("Workout History") {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutSet.self])
}
