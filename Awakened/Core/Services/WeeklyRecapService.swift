import Foundation
import SwiftData

/// Generates weekly recap summaries from player data
@MainActor
class WeeklyRecapService {
    
    private let modelContext: ModelContext
    private let lastRecapKey = "lastWeeklyRecapDate"
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Generate Recap
    
    /// Generate a weekly recap for the given player
    /// - Parameters:
    ///   - player: The player
    ///   - syncEngine: HealthSyncEngine for cardio/meditation stats
    /// - Returns: A WeeklyRecap summary
    func generateRecap(
        for player: Player,
        syncEngine: HealthSyncEngine
    ) -> WeeklyRecap {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2
        let weekStart = calendar.date(from: components) ?? now
        
        // Quests this week
        let weekQuests = player.quests.filter { $0.createdAt >= weekStart }
        let completed = weekQuests.filter { $0.isCompleted }.count
        let failed = weekQuests.filter { $0.isFailed }.count
        
        // Workouts this week
        let weekWorkouts = player.workoutSessions.filter { $0.date >= weekStart }
        
        // Reading this week
        let weekReading = player.readingEntries.filter { $0.date >= weekStart }
        let readingMinutes = weekReading.reduce(0.0) { $0 + $1.minutesRead }
        
        // Learning this week
        let weekLearning = player.learningSessions.filter { $0.date >= weekStart }
        
        // XP by stat — approximate weekly delta from workouts + reading + learning
        var xpByStat: [String: Int] = [:]
        for stat in player.stats {
            xpByStat[stat.typeRaw] = 0
        }
        // Gym workouts → strength
        xpByStat[StatType.strength.rawValue, default: 0] += weekWorkouts.reduce(0) { $0 + $1.xpEarned }
        // Reading + learning → intelligence
        xpByStat[StatType.intelligence.rawValue, default: 0] += weekReading.reduce(0) { $0 + $1.xpEarned }
        xpByStat[StatType.intelligence.rawValue, default: 0] += weekLearning.reduce(0) { $0 + $1.xpEarned }
        
        // Achievements unlocked this week
        let achievementDescriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.isUnlocked && $0.unlockedAt != nil }
        )
        let achievements = (try? modelContext.fetch(achievementDescriptor)) ?? []
        let weekAchievements = achievements
            .filter { ($0.unlockedAt ?? .distantPast) >= weekStart }
            .map(\.title)
        
        // Total XP (approximate)
        let workoutXP: Int = weekWorkouts.reduce(0) { $0 + $1.xpEarned }
        let readXP: Int = weekReading.reduce(0) { $0 + $1.xpEarned }
        let learnXP: Int = weekLearning.reduce(0) { $0 + $1.xpEarned }
        let totalXP = workoutXP + readXP + learnXP
        
        let cardioKm = syncEngine.weeklyCardioDistance
        let medMins = syncEngine.weeklyMeditationMinutes
        let streak = player.currentStreak
        let lvlFrom = max(player.level - 1, 1)
        let lvlTo = player.level
        
        return WeeklyRecap(
            weekStart: weekStart,
            totalXP: totalXP,
            xpByStatRaw: xpByStat,
            questsCompleted: completed,
            questsFailed: failed,
            workoutsLogged: weekWorkouts.count,
            cardioDistanceKm: cardioKm,
            meditationMinutes: medMins,
            readingMinutes: readingMinutes,
            streakDays: streak,
            achievementsUnlocked: weekAchievements,
            levelFrom: lvlFrom,
            levelTo: lvlTo
        )
    }
    
    // MARK: - Should Show Recap
    
    /// Whether a weekly recap should be shown (on Monday, once per week)
    var shouldShowRecap: Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Only on Monday
        guard calendar.component(.weekday, from: now) == 2 else { return false }
        
        // Check if already shown this week
        if let lastDate = UserDefaults.standard.object(forKey: lastRecapKey) as? Date {
            return !calendar.isDate(lastDate, equalTo: now, toGranularity: .weekOfYear)
        }
        
        return true
    }
    
    /// Mark the recap as shown
    func markRecapShown() {
        UserDefaults.standard.set(Date(), forKey: lastRecapKey)
    }
}
