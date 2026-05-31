import Foundation
import SwiftData

/// Handles all XP calculations for the Awakened app
struct XPCalculator {
    
    // MARK: - Level XP Requirements
    
    /// Calculate total XP required to reach a specific level
    /// Formula: 100 × level^1.5
    /// - Parameter level: Target level
    /// - Returns: Total XP required to reach that level
    static func xpRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(100.0 * pow(Double(level), 1.5))
    }
    
    /// Calculate XP needed to go from current level to next level
    /// - Parameter level: Current level
    /// - Returns: XP needed to level up
    static func xpToNextLevel(from level: Int) -> Int {
        xpRequired(forLevel: level + 1) - xpRequired(forLevel: level)
    }
    
    /// Calculate level from total XP
    /// - Parameter xp: Total accumulated XP
    /// - Returns: Current level based on XP
    static func level(fromTotalXP xp: Int) -> Int {
        var level = 1
        while xpRequired(forLevel: level + 1) <= xp {
            level += 1
        }
        return level
    }
    
    /// Calculate progress within current level (0.0 to 1.0)
    /// - Parameters:
    ///   - currentXP: Current total XP
    ///   - level: Current level
    /// - Returns: Progress percentage toward next level
    static func levelProgress(currentXP: Int, level: Int) -> Double {
        let currentLevelXP = xpRequired(forLevel: level)
        let nextLevelXP = xpRequired(forLevel: level + 1)
        let xpInLevel = nextLevelXP - currentLevelXP
        let progressXP = currentXP - currentLevelXP
        
        guard xpInLevel > 0 else { return 0 }
        return min(max(Double(progressXP) / Double(xpInLevel), 0), 1)
    }
    
    // MARK: - Activity XP Calculations
    
    /// Calculate Strength XP from weight training
    /// Formula: sets × reps × (weight / 10) × progressiveOverloadBonus
    /// - Parameters:
    ///   - sets: Number of sets performed
    ///   - reps: Reps per set
    ///   - weight: Weight used (in user's preferred unit)
    ///   - previousWeight: Previous weight for this exercise (for progressive overload)
    /// - Returns: XP earned
    static func strengthXP(
        sets: Int,
        reps: Int,
        weight: Double,
        previousWeight: Double? = nil
    ) -> Int {
        guard sets > 0, reps > 0, weight > 0 else { return 0 }
        
        let baseXP = Double(sets * reps) * (weight / 10.0)
        
        // Progressive overload bonus: +25% if weight increased
        var multiplier = 1.0
        if let prevWeight = previousWeight, weight > prevWeight {
            multiplier = 1.25
        }
        
        return max(1, Int(baseXP * multiplier))
    }
    
    /// Calculate Vitality XP from cardio activities
    /// Formula: (duration × 2) + (distance × 10) × heartRateZoneBonus
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - distanceKm: Distance in kilometers (optional)
    ///   - averageHeartRate: Average heart rate during activity (optional)
    /// - Returns: XP earned
    static func vitalityXP(
        durationMinutes: Double,
        distanceKm: Double? = nil,
        averageHeartRate: Int? = nil
    ) -> Int {
        guard durationMinutes > 0 else { return 0 }
        
        var xp = durationMinutes * 2.0
        
        // Distance bonus
        if let distance = distanceKm, distance > 0 {
            xp += distance * 10.0
        }
        
        // Heart rate zone bonus
        if let hr = averageHeartRate {
            let zoneMultiplier: Double
            switch hr {
            case 0..<100:
                zoneMultiplier = 0.8  // Too low
            case 100..<120:
                zoneMultiplier = 1.0  // Warm up zone
            case 120..<140:
                zoneMultiplier = 1.1  // Fat burn zone
            case 140..<160:
                zoneMultiplier = 1.2  // Cardio zone
            case 160..<180:
                zoneMultiplier = 1.3  // Hard zone
            default:
                zoneMultiplier = 1.4  // Peak zone
            }
            xp *= zoneMultiplier
        }
        
        return max(1, Int(xp))
    }
    
    /// Calculate Agility XP from flexibility/calisthenics
    /// Formula: duration × intensityMultiplier
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - intensity: Activity intensity level
    /// - Returns: XP earned
    static func agilityXP(
        durationMinutes: Double,
        intensity: ActivityIntensity
    ) -> Int {
        guard durationMinutes > 0 else { return 0 }
        
        let multiplier: Double
        switch intensity {
        case .low: multiplier = 1.0
        case .medium: multiplier = 1.5
        case .high: multiplier = 2.0
        }
        
        return max(1, Int(durationMinutes * multiplier))
    }
    
    /// Calculate Sense XP from meditation/mindfulness
    /// Formula: duration × 2 × consistencyBonus
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - consecutiveDays: Number of consecutive days of practice
    /// - Returns: XP earned
    static func senseXP(
        durationMinutes: Double,
        consecutiveDays: Int = 0
    ) -> Int {
        guard durationMinutes > 0 else { return 0 }
        
        // Consistency bonus: +5% per consecutive day, max +50%
        let consistencyBonus = min(consecutiveDays, 10) * 5
        let multiplier = 1.0 + (Double(consistencyBonus) / 100.0)
        
        return max(1, Int(durationMinutes * 2.0 * multiplier))
    }
    
    /// Calculate Intelligence XP from learning activities
    /// - Parameters:
    ///   - readingMinutes: Time spent reading
    ///   - pagesRead: Number of pages read
    ///   - notionPagesCreated: Notion pages created/edited
    ///   - githubCommits: GitHub commits made
    ///   - coursesCompleted: Online courses/lessons completed
    /// - Returns: XP earned
    static func intelligenceXP(
        readingMinutes: Double? = nil,
        pagesRead: Int? = nil,
        notionPagesCreated: Int? = nil,
        githubCommits: Int? = nil,
        coursesCompleted: Int? = nil
    ) -> Int {
        var xp = 0.0
        
        if let minutes = readingMinutes, minutes > 0 {
            xp += minutes * 1.5
        }
        
        if let pages = pagesRead, pages > 0 {
            xp += Double(pages) * 3.0
        }
        
        if let notionPages = notionPagesCreated, notionPages > 0 {
            xp += Double(notionPages) * 10.0
        }
        
        if let commits = githubCommits, commits > 0 {
            xp += Double(commits) * 5.0
        }
        
        if let courses = coursesCompleted, courses > 0 {
            xp += Double(courses) * 25.0
        }
        
        return max(xp > 0 ? 1 : 0, Int(xp))
    }
    
    // MARK: - Bonus Calculations
    
    /// Calculate streak bonus multiplier
    /// +10% per day, max +70% at 7 days
    /// - Parameter streakDays: Current streak in days
    /// - Returns: Multiplier (1.0 to 1.7)
    static func streakMultiplier(streakDays: Int) -> Double {
        let bonus = min(streakDays, 7) * 10
        return 1.0 + (Double(bonus) / 100.0)
    }
    
    /// Calculate penalty zone multiplier
    /// -50% XP while in penalty zone
    /// - Parameter isInPenaltyZone: Whether player is in penalty zone
    /// - Returns: Multiplier (0.5 or 1.0)
    static func penaltyMultiplier(isInPenaltyZone: Bool) -> Double {
        isInPenaltyZone ? 0.5 : 1.0
    }
    
    /// Apply all bonuses/penalties to base XP
    /// - Parameters:
    ///   - baseXP: Base XP before modifiers
    ///   - streakDays: Current streak
    ///   - isInPenaltyZone: Penalty zone status
    /// - Returns: Final adjusted XP
    static func adjustedXP(
        baseXP: Int,
        streakDays: Int,
        isInPenaltyZone: Bool
    ) -> Int {
        let streak = streakMultiplier(streakDays: streakDays)
        let penalty = penaltyMultiplier(isInPenaltyZone: isInPenaltyZone)
        return max(1, Int(Double(baseXP) * streak * penalty))
    }
    
    // MARK: - HealthKit Convenience
    
    /// Calculate XP from daily step count
    /// Formula: steps / 100, capped at 150 XP/day
    /// - Parameter steps: Total steps
    /// - Returns: XP earned
    static func stepsXP(steps: Int) -> Int {
        guard steps > 0 else { return 0 }
        return min(steps / 100, 150)
    }
    
    /// Calculate XP from sleep hours
    /// Formula: hours × 5 (if >= 6h), +10 bonus for 7-9h optimal
    /// - Parameter hours: Sleep hours
    /// - Returns: XP earned
    static func sleepXP(hours: Double) -> Int {
        guard hours >= 6 else { return 0 }
        var xp = Int(hours * 5)
        if hours >= 7 && hours <= 9 {
            xp += 10
        }
        return xp
    }
    
    /// Calculate XP from active energy burned
    /// Formula: kcal / 50, capped at 50 XP/day
    /// - Parameter kcal: Active kilocalories burned
    /// - Returns: XP earned
    static func activeEnergyXP(kcal: Double) -> Int {
        guard kcal > 0 else { return 0 }
        return min(Int(kcal / 50), 50)
    }
    
    // MARK: - Workout Session XP (Phase 3)
    
    /// Convenience wrapper for WorkoutXPService session XP calculation
    /// - Parameters:
    ///   - session: Completed workout session
    ///   - context: SwiftData model context
    /// - Returns: Strength XP earned (capped at 500)
    static func strengthSessionXP(session: WorkoutSession, context: ModelContext) -> Int {
        WorkoutXPService.calculateSessionXP(session: session, context: context)
    }
    
    // MARK: - Quest XP
    
    /// Calculate XP reward for completing a quest
    /// - Parameters:
    ///   - category: Quest category
    ///   - targetValue: Target value for the quest
    /// - Returns: XP reward
    static func questXPReward(category: QuestCategory, targetValue: Double) -> Int {
        let baseXP: Int
        switch category {
        case .steps: baseXP = 50
        case .water: baseXP = 30
        case .protein: baseXP = 40
        case .workout: baseXP = 100
        case .sleep: baseXP = 60
        case .meditation: baseXP = 50
        case .reading: baseXP = 50
        case .cardioDistance: baseXP = 80
        case .flexibility: baseXP = 50
        case .learning: baseXP = 50
        case .strength: baseXP = 80
        case .knowledge: baseXP = 60
        case .custom: baseXP = 25
        }
        
        // Scale by target (higher targets = more XP)
        let targetMultiplier = targetValue / category.defaultTarget
        return max(1, Int(Double(baseXP) * targetMultiplier))
    }
}

// MARK: - Supporting Types

/// Activity intensity levels
enum ActivityIntensity: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .low: return "Light effort, can easily hold a conversation"
        case .medium: return "Moderate effort, slightly breathless"
        case .high: return "High effort, difficult to speak"
        }
    }
}

/// Quest categories for XP calculation
enum QuestCategory: String, Codable, CaseIterable, Identifiable {
    case steps
    case water
    case protein
    case workout
    case sleep
    case meditation
    case reading
    case cardioDistance
    case flexibility
    case learning
    case strength    // composite "Strength Points" from bodyweight reps + walking
    case knowledge   // combines reading + learning minutes (INT)
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .water: return "Water Intake"
        case .protein: return "Protein"
        case .workout: return "Workout"
        case .sleep: return "Recovery"
        case .meditation: return "Sense"
        case .reading: return "Reading"
        case .cardioDistance: return "Vitality"
        case .flexibility: return "Agility"
        case .learning: return "Learning"
        case .strength: return "Strength"
        case .knowledge: return "Intelligence"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .water: return "drop.fill"
        case .protein: return "fork.knife"
        case .workout: return "dumbbell.fill"
        case .sleep: return "bed.double.fill"
        case .meditation: return "brain.head.profile"
        case .reading: return "book.fill"
        case .cardioDistance: return "figure.run"
        case .flexibility: return "figure.yoga"
        case .learning: return "lightbulb.fill"
        case .strength: return "figure.strengthtraining.traditional"
        case .knowledge: return "brain.fill"
        case .custom: return "star.fill"
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "steps"
        case .water: return "glasses"
        case .protein: return "g"
        case .workout: return "min"
        case .sleep: return "hours"
        case .meditation: return "min"
        case .reading: return "min"
        case .cardioDistance: return "km"
        case .flexibility: return "min"
        case .learning: return "min"
        case .strength: return "SP"
        case .knowledge: return "min"
        case .custom: return ""
        }
    }
    
    var relatedStat: StatType {
        switch self {
        case .steps, .workout, .water, .protein, .sleep, .cardioDistance: return .vitality
        case .meditation: return .sense
        case .reading, .learning, .knowledge: return .intelligence
        case .flexibility: return .agility
        case .strength: return .strength
        case .custom: return .strength
        }
    }
    
    var defaultTarget: Double {
        switch self {
        case .steps: return 10000
        case .water: return 8
        case .protein: return 150
        case .workout: return 30
        case .sleep: return 7
        case .meditation: return 10
        case .reading: return 30
        case .cardioDistance: return 5
        case .flexibility: return 20
        case .learning: return 30
        case .strength: return 50
        case .knowledge: return 30
        case .custom: return 1
        }
    }
    
    /// The 6 default quest categories shown on the dashboard / quests grid.
    /// One per stat area + Recovery (sleep).
    static var defaultDailyCategories: [QuestCategory] {
        [.strength, .flexibility, .cardioDistance, .meditation, .knowledge, .sleep]
    }
    
    /// Short instruction telling the user what activity completes this quest.
    var instructions: String {
        switch self {
        case .steps:          return "Walk throughout the day"
        case .water:          return "Drink water throughout the day"
        case .protein:        return "Hit your protein target via meals"
        case .workout:        return "Complete a strength workout"
        case .sleep:          return "Get a full night of sleep"
        case .meditation:     return "Meditate or do breathing exercises"
        case .reading:        return "Read a book or article"
        case .cardioDistance: return "Run, cycle, swim, or do HIIT"
        case .flexibility:    return "Yoga, calisthenics, or stretching"
        case .learning:       return "Study, take a course, or code"
        case .strength:       return "Pushups, pullups, situps + walking"
        case .knowledge:      return "Read or study to grow your mind"
        case .custom:         return "Custom goal"
        }
    }
}
