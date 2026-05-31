import Foundation
import SwiftData

/// Represents the player/user in the Awakened system
@Model
final class Player {
    
    // MARK: - Identity
    
    /// Unique identifier
    var id: UUID
    
    /// Player's display name
    var name: String
    
    /// When the player was created
    var createdAt: Date
    
    // MARK: - Progression
    
    /// Current overall level
    var level: Int
    
    /// Total XP accumulated across all activities
    var totalXP: Int
    
    /// Stat points available to allocate.
    /// **Deprecated**: stats now auto-level via XP earned in their respective activity area.
    /// Kept for SwiftData migration safety; always 0 going forward.
    var availableStatPoints: Int
    
    // MARK: - Relationships
    
    /// Player's stats (Strength, Agility, Vitality, Sense, Intelligence)
    @Relationship(deleteRule: .cascade, inverse: \Stat.player)
    var stats: [Stat]
    
    /// Player's quests
    @Relationship(deleteRule: .cascade, inverse: \Quest.player)
    var quests: [Quest]
    
    /// Player's workout sessions
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.player)
    var workoutSessions: [WorkoutSession]
    
    /// Player's personal records
    @Relationship(deleteRule: .cascade, inverse: \PersonalRecord.player)
    var personalRecords: [PersonalRecord]
    
    /// Player's workout templates
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.player)
    var workoutTemplates: [WorkoutTemplate]
    
    /// Player's reading entries
    @Relationship(deleteRule: .cascade, inverse: \ReadingEntry.player)
    var readingEntries: [ReadingEntry]
    
    /// Player's learning sessions
    @Relationship(deleteRule: .cascade, inverse: \LearningSession.player)
    var learningSessions: [LearningSession]
    
    /// Player's achievements
    @Relationship(deleteRule: .cascade, inverse: \Achievement.player)
    var achievements: [Achievement]
    
    /// Player's meal entries
    @Relationship(deleteRule: .cascade, inverse: \MealEntry.player)
    var mealEntries: [MealEntry]
    
    /// Player's body measurements
    @Relationship(deleteRule: .cascade, inverse: \BodyMeasurement.player)
    var bodyMeasurements: [BodyMeasurement]
    
    // MARK: - Streak & Penalties
    
    /// Current consecutive day streak
    var currentStreak: Int
    
    /// Longest streak ever achieved
    var longestStreak: Int
    
    /// Last date the player was active
    var lastActiveDate: Date?
    
    /// Whether player is currently in penalty zone
    var isInPenaltyZone: Bool
    
    /// When player entered penalty zone
    var penaltyZoneEntryDate: Date?
    
    /// Number of consecutive quest failures
    var consecutiveFailures: Int
    
    // MARK: - Body Profile (for muscle leveling thresholds & anatomy view)
    
    /// Biological sex used purely for muscle-anatomy silhouette ("male" / "female"). Optional.
    var sexRaw: String?
    
    /// Body weight in kilograms. Optional.
    var weightKg: Double?
    
    /// Height in centimeters. Optional.
    var heightCm: Double?
    
    // MARK: - Computed Properties
    
    /// Current rank based on level
    var rank: PlayerRank {
        PlayerRank.from(level: level)
    }
    
    /// XP required to reach current level
    var xpForCurrentLevel: Int {
        XPCalculator.xpRequired(forLevel: level)
    }
    
    /// XP required to reach next level
    var xpForNextLevel: Int {
        XPCalculator.xpRequired(forLevel: level + 1)
    }
    
    /// XP progress within current level
    var xpProgressInCurrentLevel: Int {
        totalXP - xpForCurrentLevel
    }
    
    /// XP needed to reach next level
    var xpNeededForNextLevel: Int {
        xpForNextLevel - xpForCurrentLevel
    }
    
    /// Progress toward next level (0.0 to 1.0)
    var levelProgress: Double {
        guard xpNeededForNextLevel > 0 else { return 0 }
        return min(max(Double(xpProgressInCurrentLevel) / Double(xpNeededForNextLevel), 0), 1)
    }
    
    /// Hunter class determined by stat distribution. Nil until D-Rank (level 10).
    var hunterClass: HunterClass? {
        guard level >= PlayerRank.d.minLevel else { return nil }
        return HunterClass.classify(from: stats)
    }
    
    /// Current title earned through milestones
    var currentTitle: HunterTitle? {
        HunterTitle.currentTitle(for: self)
    }
    
    /// All earned titles
    var earnedTitles: [HunterTitle] {
        HunterTitle.earnedTitles(for: self)
    }
    
    /// Sorted stats in display order
    var sortedStats: [Stat] {
        stats.sorted()
    }
    
    /// Active (incomplete) quests
    var activeQuests: [Quest] {
        quests.filter { $0.isActive }
    }
    
    /// Today's daily quests
    var todayQuests: [Quest] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return quests.filter { quest in
            quest.type == .daily &&
            calendar.isDate(quest.createdAt, inSameDayAs: today)
        }
    }
    
    /// Completed quests
    var completedQuests: [Quest] {
        quests.filter { $0.isCompleted }
    }
    
    /// Streak bonus multiplier (1.0 to 1.7)
    var streakMultiplier: Double {
        XPCalculator.streakMultiplier(streakDays: currentStreak)
    }
    
    /// Streak bonus as percentage (0 to 70)
    var streakBonusPercent: Int {
        min(currentStreak, 7) * 10
    }
    
    // MARK: - Initialization
    
    /// Create a new player
    /// - Parameter name: Player's display name
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.level = 1
        self.totalXP = 0
        self.availableStatPoints = 0
        self.stats = []
        self.quests = []
        self.workoutSessions = []
        self.personalRecords = []
        self.workoutTemplates = []
        self.readingEntries = []
        self.learningSessions = []
        self.achievements = []
        self.mealEntries = []
        self.bodyMeasurements = []
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.isInPenaltyZone = false
        self.penaltyZoneEntryDate = nil
        self.consecutiveFailures = 0
    }
    
    // MARK: - Stat Management
    
    /// Initialize all five stats for a new player
    func initializeStats() {
        guard stats.isEmpty else { return }
        
        for statType in StatType.allCases {
            let stat = Stat(type: statType)
            stats.append(stat)
        }
    }
    
    /// Get a specific stat by type
    /// - Parameter type: The stat type to retrieve
    /// - Returns: The stat if found
    func stat(for type: StatType) -> Stat? {
        stats.first { $0.type == type }
    }
    
    /// Add XP to a specific stat
    /// - Parameters:
    ///   - amount: Base XP amount (before bonuses)
    ///   - statType: Which stat to add XP to
    /// - Returns: Tuple of (adjusted XP added, levels gained)
    @discardableResult
    func addXP(_ amount: Int, to statType: StatType) -> (xpAdded: Int, levelsGained: Int) {
        guard let stat = stat(for: statType), amount > 0 else {
            return (0, 0)
        }
        
        let adjustedAmount = calculateAdjustedXP(amount)
        let levelsGained = stat.addXP(adjustedAmount)
        totalXP += adjustedAmount
        
        SoundManager.shared.playXPGain()
        
        checkForLevelUp()
        
        return (adjustedAmount, levelsGained)
    }
    
    /// Calculate XP with streak bonus and penalty zone modifier
    private func calculateAdjustedXP(_ baseAmount: Int) -> Int {
        XPCalculator.adjustedXP(
            baseXP: baseAmount,
            streakDays: currentStreak,
            isInPenaltyZone: isInPenaltyZone
        )
    }
    
    /// Check if player should level up and apply level ups
    private func checkForLevelUp() {
        let previousLevel = level
        while totalXP >= xpForNextLevel {
            level += 1
        }
        // Stat points are no longer awarded on level up — stats auto-level
        // via XP earned in their respective activity areas (see XPRouter / addXP).
        availableStatPoints = 0
        
        if level > previousLevel {
            SoundManager.shared.playLevelUp()
        }
        
        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
    
    
    // MARK: - Streak Management
    
    /// Update streak based on daily quest completion
    /// - Parameter completedDailyQuests: Whether all daily quests were completed
    func updateStreak(completedDailyQuests: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastActive = lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let daysDifference = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day
                if completedDailyQuests {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                    consecutiveFailures = 0
                    exitPenaltyZoneIfEligible()
                } else {
                    handleQuestFailure()
                }
            } else if daysDifference == 0 {
                // Same day - update based on completion
                if completedDailyQuests {
                    consecutiveFailures = 0
                }
            } else {
                // Missed day(s)
                currentStreak = 0
                if !completedDailyQuests {
                    handleQuestFailure()
                } else {
                    currentStreak = 1
                    consecutiveFailures = 0
                }
            }
        } else {
            // First day
            currentStreak = completedDailyQuests ? 1 : 0
            if !completedDailyQuests {
                consecutiveFailures = 1
            }
        }
        
        lastActiveDate = Date()
    }
    
    /// Handle a quest failure
    private func handleQuestFailure() {
        currentStreak = 0
        consecutiveFailures += 1
        
        if consecutiveFailures >= 3 {
            enterPenaltyZone()
        }
        
        // Apply XP penalty to relevant stats
        applyFailurePenalty()
    }
    
    /// Apply -5% XP penalty to stats
    private func applyFailurePenalty() {
        for stat in stats {
            let penalty = Int(Double(stat.currentXP) * 0.05)
            stat.removeXP(penalty)
        }
    }
    
    // MARK: - Penalty Zone
    
    /// Enter the penalty zone
    func enterPenaltyZone() {
        guard !isInPenaltyZone else { return }
        isInPenaltyZone = true
        penaltyZoneEntryDate = Date()
        SoundManager.shared.playPenaltyEnter()
    }
    
    /// Check if player can exit penalty zone
    private func exitPenaltyZoneIfEligible() {
        // Can exit after 3 consecutive successful days
        if consecutiveFailures == 0 && currentStreak >= 3 && isInPenaltyZone {
            exitPenaltyZone()
        }
    }
    
    /// Exit the penalty zone (after completing challenge or streak)
    func exitPenaltyZone() {
        isInPenaltyZone = false
        penaltyZoneEntryDate = nil
        consecutiveFailures = 0
    }
    
    /// Complete the penalty zone challenge
    func completePenaltyChallenge() {
        exitPenaltyZone()
    }
    
    // MARK: - Quest Management
    
    /// Generate daily quests for today.
    /// Default: 6 quests — one per stat area (STR/AGI/VIT/SEN/INT) + Recovery (sleep).
    /// - Parameter categories: Categories to generate quests for
    func generateDailyQuests(for categories: [QuestCategory] = QuestCategory.defaultDailyCategories) {
        // Filter out user-disabled categories
        let disabledRaw = UserDefaults.standard.stringArray(forKey: "questDisabledCategories") ?? []
        let disabledSet = Set(disabledRaw)
        let enabledCategories = categories.filter { !disabledSet.contains($0.rawValue) }
        
        // Migration: remove today's quests with deprecated categories not in the
        // new default set (e.g. .protein, .water, .steps, .workout, .reading, .learning)
        // so they get replaced with the new 6.
        let allowed = Set(categories.map { $0.rawValue })
        let toRemove = todayQuests.filter { quest in
            quest.type == .daily && !allowed.contains(quest.categoryRaw)
        }
        for quest in toRemove {
            quests.removeAll { $0.id == quest.id }
        }
        
        // Check if quests already exist for today
        let existingCategories = Set(todayQuests.map { $0.category })
        
        // Read custom targets from user settings
        let customTargets = UserDefaults.standard.dictionary(forKey: "questCustomTargets") as? [String: Double] ?? [:]
        
        for category in enabledCategories {
            if !existingCategories.contains(category) {
                let target = customTargets[category.rawValue]
                let quest = Quest.dailyQuest(category: category, target: target)
                quests.append(quest)
            }
        }
        
        // Add penalty quest if in penalty zone
        if isInPenaltyZone {
            let hasPenaltyQuest = quests.contains { $0.type == .penalty && $0.isActive }
            if !hasPenaltyQuest {
                let penaltyQuest = Quest.penaltyQuest()
                quests.append(penaltyQuest)
            }
        }
    }
    
    /// Check and update all quest expirations
    func checkQuestExpirations() {
        for quest in quests where quest.isActive {
            quest.checkExpiration()
        }
    }
    
    /// Complete a quest and award XP
    /// - Parameter quest: The quest to complete
    /// - Returns: XP awarded
    @discardableResult
    func completeQuest(_ quest: Quest) -> Int {
        guard quest.isActive, quest.progress >= 1.0 else { return 0 }
        
        quest.complete()
        SoundManager.shared.playQuestComplete()
        
        // Award XP
        if quest.xpReward > 0 {
            let (xpAdded, _) = addXP(quest.xpReward, to: quest.statType)
            return xpAdded
        }
        
        // Handle penalty quest completion
        if quest.type == .penalty {
            completePenaltyChallenge()
        }
        
        return 0
    }
}
