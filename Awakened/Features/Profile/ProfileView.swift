import SwiftUI
import SwiftData

/// Profile tab view - shows player stats and settings
struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State private var showingRank = false
    
    private var player: Player? {
        players.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if let player = player {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Profile header — tap to open the rank/level screen
                            Button {
                                showingRank = true
                            } label: {
                                ProfileHeader(player: player)
                            }
                            .buttonStyle(.plain)
                            
                            // Stats detail
                            StatsDetailSection(player: player)
                            
                            // Achievements preview
                            AchievementsPreview()
                            
                            Spacer(minLength: AppSpacing.xxl)
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.md)
                    }
                } else {
                    Text("No player found")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingRank) {
                NavigationStack {
                    RankLevelUpView()
                }
            }
        }
    }
    
}

// MARK: - Profile Header

struct ProfileHeader: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Rank badge with progress
            RankBadgeWithProgress(
                rank: player.rank,
                level: player.level,
                progress: player.levelProgress,
                size: .large
            )
            
            // Name and level
            VStack(spacing: AppSpacing.xxs) {
                Text(player.name)
                    .font(AppFonts.title1)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Level \(player.level) • \(player.rank.displayName)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // XP Progress
            VStack(spacing: AppSpacing.xs) {
                XPProgressBar(progress: player.levelProgress, height: 10)
                
                HStack {
                    Text("\(player.xpProgressInCurrentLevel) XP")
                        .font(AppFonts.xpNumber)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(player.xpNeededForNextLevel) XP to level \(player.level + 1)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Quick stats
            HStack(spacing: AppSpacing.xl) {
                QuickStat(title: "Workouts", value: "\(player.workoutSessions.count)")
                QuickStat(title: "Day Streak", value: "\(player.currentStreak)")
                QuickStat(title: "Total XP", value: formatNumber(player.totalXP))
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

// MARK: - Stats Detail Section

struct StatsDetailSection: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Stats")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(player.sortedStats) { stat in
                StatCard(stat: stat, showDetails: true)
            }
        }
    }
}

// MARK: - Achievements Preview

struct AchievementsPreview: View {
    @Query private var achievements: [Achievement]
    
    private var recentUnlocked: [Achievement] {
        achievements
            .filter(\.isUnlocked)
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            .prefix(4)
            .map { $0 }
    }
    
    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Achievements")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                NavigationLink {
                    AchievementsView()
                } label: {
                    Text("\(unlockedCount)/\(achievements.count)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.accentPurple)
                }
            }
            
            if recentUnlocked.isEmpty {
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<4) { _ in
                        Circle()
                            .fill(AppColors.surface.opacity(0.5))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppColors.textTertiary)
                            )
                    }
                    Spacer()
                }
            } else {
                HStack(spacing: AppSpacing.md) {
                    ForEach(recentUnlocked) { achievement in
                        ZStack {
                            Circle()
                                .fill(achievement.category.color.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Circle()
                                .stroke(achievement.tierColor, lineWidth: 2)
                                .frame(width: 50, height: 50)
                            Image(systemName: achievement.icon)
                                .font(.system(size: 20))
                                .foregroundColor(achievement.category.color)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

#Preview("Profile") {
    ProfileView()
        .environmentObject(AppState())
        .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}
