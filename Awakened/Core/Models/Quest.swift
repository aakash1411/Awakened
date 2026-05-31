import Foundation
import SwiftData

/// Type of quest (daily, weekly, special, penalty)
enum QuestType: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case special
    case penalty
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .special: return "star.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        }
    }
}

/// Represents a quest/goal for the player to complete
@Model
final class Quest {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Quest title
    var title: String
    
    /// Quest description
    var questDescription: String
    
    /// Quest type stored as string
    var typeRaw: String
    
    /// Quest category stored as string
    var categoryRaw: String
    
    /// Target value to complete the quest
    var targetValue: Double
    
    /// Current progress value
    var currentValue: Double
    
    /// XP reward for completing the quest
    var xpReward: Int
    
    /// Related stat type stored as string
    var statTypeRaw: String
    
    /// Whether the quest has been completed
    var isCompleted: Bool
    
    /// Whether the quest has failed
    var isFailed: Bool
    
    /// When the quest was created
    var createdAt: Date
    
    /// When the quest is due
    var dueDate: Date
    
    /// When the quest was completed (if completed)
    var completedAt: Date?
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Quest type enum
    var type: QuestType {
        get { QuestType(rawValue: typeRaw) ?? .daily }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Quest category enum
    var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
    
    /// Related stat type enum
    var statType: StatType {
        get { StatType(rawValue: statTypeRaw) ?? .strength }
        set { statTypeRaw = newValue.rawValue }
    }
    
    /// Progress toward completion (0.0 to 1.0)
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    /// Progress as percentage (0 to 100)
    var progressPercent: Int {
        Int(progress * 100)
    }
    
    /// Whether the quest has expired
    var isExpired: Bool {
        Date() > dueDate && !isCompleted
    }
    
    /// Whether the quest is still active (not completed, failed, or expired)
    var isActive: Bool {
        !isCompleted && !isFailed && !isExpired
    }
    
    /// Status text for display
    var statusText: String {
        if isCompleted { return "Completed" }
        if isFailed { return "Failed" }
        if isExpired { return "Expired" }
        return "In Progress"
    }
    
    /// Formatted progress text (e.g., "5,000 / 10,000 steps")
    var progressText: String {
        let current = formatValue(currentValue)
        let target = formatValue(targetValue)
        return "\(current) / \(target) \(category.unit)"
    }
    
    /// Time remaining until due date
    var timeRemaining: TimeInterval {
        max(0, dueDate.timeIntervalSince(Date()))
    }
    
    /// Formatted time remaining
    var timeRemainingText: String {
        let remaining = timeRemaining
        if remaining <= 0 { return "Expired" }
        
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    // MARK: - Initialization
    
    /// Create a new quest
    init(
        title: String,
        description: String = "",
        type: QuestType,
        category: QuestCategory,
        targetValue: Double,
        xpReward: Int,
        statType: StatType,
        dueDate: Date
    ) {
        self.id = UUID()
        self.title = title
        self.questDescription = description
        self.typeRaw = type.rawValue
        self.categoryRaw = category.rawValue
        self.targetValue = targetValue
        self.currentValue = 0
        self.xpReward = xpReward
        self.statTypeRaw = statType.rawValue
        self.isCompleted = false
        self.isFailed = false
        self.createdAt = Date()
        self.dueDate = dueDate
        self.completedAt = nil
    }
    
    // MARK: - Factory Methods
    
    /// Create a daily quest for a specific category
    /// - Parameters:
    ///   - category: Quest category
    ///   - target: Optional custom target (uses default if nil)
    /// - Returns: Configured daily quest
    static func dailyQuest(category: QuestCategory, target: Double? = nil) -> Quest {
        let targetValue = target ?? category.defaultTarget
        let xpReward = XPCalculator.questXPReward(category: category, targetValue: targetValue)
        
        // Due at end of today
        let endOfDay = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400 - 1)
        
        return Quest(
            title: "\(category.displayName) Goal",
            description: "Complete your daily \(category.displayName.lowercased()) goal",
            type: .daily,
            category: category,
            targetValue: targetValue,
            xpReward: xpReward,
            statType: category.relatedStat,
            dueDate: endOfDay
        )
    }
    
    /// Create a weekly quest for a specific category
    /// - Parameters:
    ///   - category: Quest category
    ///   - target: Optional custom target (uses 7x daily default if nil)
    /// - Returns: Configured weekly quest
    static func weeklyQuest(category: QuestCategory, target: Double? = nil) -> Quest {
        let targetValue = target ?? (category.defaultTarget * 7)
        let xpReward = XPCalculator.questXPReward(category: category, targetValue: targetValue) * 2
        
        // Due at end of week
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = (8 - weekday) % 7
        let endOfWeek = calendar.date(byAdding: .day, value: daysUntilSunday, to: today)!
            .addingTimeInterval(86400 - 1)
        
        return Quest(
            title: "Weekly \(category.displayName)",
            description: "Complete your weekly \(category.displayName.lowercased()) goal",
            type: .weekly,
            category: category,
            targetValue: targetValue,
            xpReward: xpReward,
            statType: category.relatedStat,
            dueDate: endOfWeek
        )
    }
    
    /// Create a penalty zone challenge quest
    /// - Returns: Penalty quest that must be completed to exit penalty zone
    static func penaltyQuest() -> Quest {
        let endOfDay = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400 - 1)
        
        return Quest(
            title: "Penalty Zone Challenge",
            description: "Complete this extra challenge to exit the Penalty Zone and restore your XP gains",
            type: .penalty,
            category: .workout,
            targetValue: 50,  // 50 minutes of workout
            xpReward: 0,  // No XP reward, just escape penalty
            statType: .vitality,
            dueDate: endOfDay
        )
    }
    
    // MARK: - Methods
    
    /// Update progress with a new value (does NOT auto-complete; caller must check progress and call player.completeQuest)
    /// - Parameter value: New current value
    func updateProgress(_ value: Double) {
        guard !isCompleted && !isFailed else { return }
        currentValue = max(0, value)
    }
    
    /// Add to current progress (does NOT auto-complete; caller must check progress and call player.completeQuest)
    /// - Parameter value: Value to add
    func addProgress(_ value: Double) {
        guard !isCompleted && !isFailed else { return }
        currentValue = max(0, currentValue + value)
    }
    
    /// Mark quest as completed
    func complete() {
        guard !isCompleted else { return }
        isCompleted = true
        completedAt = Date()
    }
    
    /// Mark quest as failed
    func fail() {
        guard !isCompleted && !isFailed else { return }
        isFailed = true
    }
    
    /// Check if quest should be marked as failed (called on app open/timer)
    func checkExpiration() {
        if isExpired && !isCompleted && !isFailed {
            fail()
        }
    }
    
    // MARK: - Helpers
    
    /// Format a value for display
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Comparable

extension Quest: Comparable {
    static func < (lhs: Quest, rhs: Quest) -> Bool {
        // Sort by: active first, then by due date
        if lhs.isActive != rhs.isActive {
            return lhs.isActive
        }
        return lhs.dueDate < rhs.dueDate
    }
    
    static func == (lhs: Quest, rhs: Quest) -> Bool {
        lhs.id == rhs.id
    }
}
