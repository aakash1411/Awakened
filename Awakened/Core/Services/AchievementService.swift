import Foundation
import SwiftData

/// Manages achievement definitions, progress tracking, and unlocking
@MainActor
class AchievementService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Seed Achievements
    
    /// Seed all achievement definitions for a new player
    /// - Parameter player: The player to associate with
    func generateInitialAchievements(for player: Player) {
        let definitions = Self.allDefinitions
        
        // Check if already seeded
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.player != nil }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let existingKeys = Set(existing.map(\.key))
        
        for def in definitions {
            guard !existingKeys.contains(def.key) else { continue }
            let achievement = Achievement(
                key: def.key,
                title: def.title,
                description: def.description,
                icon: def.icon,
                category: def.category,
                tier: def.tier,
                targetValue: def.targetValue
            )
            achievement.player = player
            modelContext.insert(achievement)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Check & Unlock
    
    /// Scan all achievements and update progress based on player data
    /// - Parameter player: The player to check against
    /// - Returns: Array of newly unlocked achievement titles
    func checkAndUnlock(player: Player) -> [String] {
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { !$0.isUnlocked }
        )
        let locked = (try? modelContext.fetch(descriptor)) ?? []
        var newlyUnlocked: [String] = []
        
        for achievement in locked {
            guard achievement.player?.id == player.id else { continue }
            
            let currentValue = progressValue(for: achievement.key, player: player)
            if achievement.updateProgress(currentValue) {
                newlyUnlocked.append(achievement.title)
            }
        }
        
        if !newlyUnlocked.isEmpty {
            try? modelContext.save()
        }
        
        return newlyUnlocked
    }
    
    // MARK: - Progress Calculation
    
    /// Calculate current progress value for a given achievement key
    private func progressValue(for key: String, player: Player) -> Double {
        switch key {
        // Strength
        case "first_pr":
            return Double(player.personalRecords.count > 0 ? 1 : 0)
        case "ten_prs":
            return Double(player.personalRecords.count)
        case "fifty_workouts":
            return Double(player.workoutSessions.count)
        case "hundred_workouts":
            return Double(player.workoutSessions.count)
            
        // Cardio — query via relationships is limited, use counts
        case "first_run":
            return Double(player.workoutSessions.count > 0 ? 1 : 0)
            
        // Flexibility
        case "first_yoga":
            // Approximate via agility stat XP
            let agilityStat = player.stats.first { $0.type == .agility }
            return Double((agilityStat?.currentXP ?? 0) > 0 ? 1 : 0)
        case "ten_flexibility":
            let agilityStat = player.stats.first { $0.type == .agility }
            return Double((agilityStat?.currentXP ?? 0) / 50) // ~1 session per 50 XP
            
        // Meditation
        case "first_meditation":
            let senseStat = player.stats.first { $0.type == .sense }
            return Double((senseStat?.currentXP ?? 0) > 0 ? 1 : 0)
        case "seven_day_meditation":
            let senseStat = player.stats.first { $0.type == .sense }
            return Double(min((senseStat?.currentXP ?? 0) / 30, 7))
        case "thirty_day_meditation":
            let senseStat = player.stats.first { $0.type == .sense }
            return Double(min((senseStat?.currentXP ?? 0) / 30, 30))
            
        // Intelligence
        case "first_book":
            return Double(player.readingEntries.isEmpty ? 0 : 1)
        case "ten_books":
            let uniqueTitles = Set(player.readingEntries.map(\.bookTitle))
            return Double(uniqueTitles.count)
        case "fifty_learning":
            return Double(player.learningSessions.count)
            
        // Streak
        case "seven_day_streak":
            return Double(player.longestStreak)
        case "fourteen_day_streak":
            return Double(player.longestStreak)
        case "thirty_day_streak":
            return Double(player.longestStreak)
        case "sixty_day_streak":
            return Double(player.longestStreak)
        case "hundred_day_streak":
            return Double(player.longestStreak)
            
        // Milestone
        case "level_10":
            return Double(player.level)
        case "level_25":
            return Double(player.level)
        case "level_50":
            return Double(player.level)
        case "rank_c":
            return player.rank >= .c ? 1 : 0
        case "rank_b":
            return player.rank >= .b ? 1 : 0
        case "rank_a":
            return player.rank >= .a ? 1 : 0
        case "all_stats_10":
            let minLevel = player.stats.map(\.level).min() ?? 0
            return Double(minLevel)
            
        default:
            return 0
        }
    }
    
    // MARK: - Achievement Definitions
    
    /// All built-in achievement definitions
    static let allDefinitions: [AchievementDef] = [
        // Strength (6)
        AchievementDef(key: "first_pr", title: "First PR", description: "Set your first personal record", icon: "trophy.fill", category: .strength, tier: 1, targetValue: 1),
        AchievementDef(key: "ten_prs", title: "PR Machine", description: "Set 10 personal records", icon: "trophy.fill", category: .strength, tier: 2, targetValue: 10),
        AchievementDef(key: "fifty_workouts", title: "Gym Rat", description: "Complete 50 workouts", icon: "dumbbell.fill", category: .strength, tier: 2, targetValue: 50),
        AchievementDef(key: "hundred_workouts", title: "Iron Will", description: "Complete 100 workouts", icon: "dumbbell.fill", category: .strength, tier: 3, targetValue: 100),
        
        // Cardio (4)
        AchievementDef(key: "first_run", title: "First Steps", description: "Complete your first cardio session", icon: "figure.run", category: .cardio, tier: 1, targetValue: 1),
        
        // Flexibility (3)
        AchievementDef(key: "first_yoga", title: "Namaste", description: "Complete your first yoga/flexibility session", icon: "figure.yoga", category: .flexibility, tier: 1, targetValue: 1),
        AchievementDef(key: "ten_flexibility", title: "Limber Up", description: "Complete 10 flexibility sessions", icon: "figure.flexibility", category: .flexibility, tier: 2, targetValue: 10),
        
        // Meditation (4)
        AchievementDef(key: "first_meditation", title: "Inner Peace", description: "Complete your first meditation", icon: "brain.head.profile", category: .meditation, tier: 1, targetValue: 1),
        AchievementDef(key: "seven_day_meditation", title: "Mindful Week", description: "Meditate 7 days in a row", icon: "brain.head.profile", category: .meditation, tier: 2, targetValue: 7),
        AchievementDef(key: "thirty_day_meditation", title: "Zen Master", description: "Meditate 30 days in a row", icon: "brain.head.profile", category: .meditation, tier: 3, targetValue: 30),
        
        // Intelligence (4)
        AchievementDef(key: "first_book", title: "Bookworm", description: "Log your first reading entry", icon: "book.fill", category: .intelligence, tier: 1, targetValue: 1),
        AchievementDef(key: "ten_books", title: "Scholar", description: "Read 10 different books", icon: "books.vertical.fill", category: .intelligence, tier: 2, targetValue: 10),
        AchievementDef(key: "fifty_learning", title: "Lifelong Learner", description: "Complete 50 learning sessions", icon: "lightbulb.fill", category: .intelligence, tier: 3, targetValue: 50),
        
        // Streak (5)
        AchievementDef(key: "seven_day_streak", title: "On Fire", description: "Maintain a 7-day streak", icon: "flame.fill", category: .streak, tier: 1, targetValue: 7),
        AchievementDef(key: "fourteen_day_streak", title: "Fortnight", description: "Maintain a 14-day streak", icon: "flame.fill", category: .streak, tier: 2, targetValue: 14),
        AchievementDef(key: "thirty_day_streak", title: "Monthly Warrior", description: "Maintain a 30-day streak", icon: "flame.fill", category: .streak, tier: 2, targetValue: 30),
        AchievementDef(key: "sixty_day_streak", title: "Unstoppable", description: "Maintain a 60-day streak", icon: "flame.fill", category: .streak, tier: 3, targetValue: 60),
        AchievementDef(key: "hundred_day_streak", title: "Legendary Streak", description: "Maintain a 100-day streak", icon: "flame.fill", category: .streak, tier: 4, targetValue: 100),
        
        // Milestone (7)
        AchievementDef(key: "level_10", title: "Rising Hunter", description: "Reach level 10", icon: "star.fill", category: .milestone, tier: 1, targetValue: 10),
        AchievementDef(key: "level_25", title: "Seasoned Hunter", description: "Reach level 25", icon: "star.fill", category: .milestone, tier: 2, targetValue: 25),
        AchievementDef(key: "level_50", title: "Elite Hunter", description: "Reach level 50", icon: "star.fill", category: .milestone, tier: 3, targetValue: 50),
        AchievementDef(key: "rank_c", title: "C-Rank", description: "Achieve C-Rank", icon: "shield.fill", category: .milestone, tier: 1, targetValue: 1),
        AchievementDef(key: "rank_b", title: "B-Rank", description: "Achieve B-Rank", icon: "shield.fill", category: .milestone, tier: 2, targetValue: 1),
        AchievementDef(key: "rank_a", title: "A-Rank", description: "Achieve A-Rank", icon: "shield.fill", category: .milestone, tier: 3, targetValue: 1),
        AchievementDef(key: "all_stats_10", title: "Well-Rounded", description: "Get all stats to level 10", icon: "pentagon.fill", category: .milestone, tier: 3, targetValue: 10),
    ]
}

// MARK: - Achievement Definition

/// Lightweight definition struct for seeding
struct AchievementDef {
    let key: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let tier: Int
    let targetValue: Double
}
