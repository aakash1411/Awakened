import Foundation
import SwiftUI
import SwiftData

// MARK: - Achievement Category

/// Categories of achievements
enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case strength
    case cardio
    case flexibility
    case meditation
    case intelligence
    case streak
    case milestone
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        case .meditation: return "Meditation"
        case .intelligence: return "Intelligence"
        case .streak: return "Streak"
        case .milestone: return "Milestone"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.yoga"
        case .meditation: return "brain.head.profile"
        case .intelligence: return "book.fill"
        case .streak: return "flame.fill"
        case .milestone: return "star.fill"
        }
    }
    
    /// Associated color
    var color: Color {
        switch self {
        case .strength: return AppColors.strengthColor
        case .cardio: return AppColors.vitalityColor
        case .flexibility: return AppColors.agilityColor
        case .meditation: return AppColors.senseColor
        case .intelligence: return AppColors.intelligenceColor
        case .streak: return .orange
        case .milestone: return AppColors.accentPurple
        }
    }
}

// MARK: - Achievement

/// A trackable achievement/badge
@Model
final class Achievement {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Unique key for dedup (e.g., "first_pr")
    var key: String
    
    /// Display title
    var title: String
    
    /// Description of how to earn
    var achievementDescription: String
    
    /// SF Symbol icon name
    var icon: String
    
    /// Category raw string
    var categoryRaw: String
    
    /// Tier (1=Bronze, 2=Silver, 3=Gold, 4=Diamond)
    var tier: Int
    
    /// When unlocked (nil if locked)
    var unlockedAt: Date?
    
    /// Whether this achievement is unlocked
    var isUnlocked: Bool
    
    /// Current progress toward goal
    var progressValue: Double
    
    /// Target value to unlock
    var targetValue: Double
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Category enum
    var category: AchievementCategory {
        get { AchievementCategory(rawValue: categoryRaw) ?? .milestone }
        set { categoryRaw = newValue.rawValue }
    }
    
    /// Progress fraction (0.0 to 1.0)
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(progressValue / targetValue, 1.0)
    }
    
    /// Tier display name
    var tierName: String {
        switch tier {
        case 1: return "Bronze"
        case 2: return "Silver"
        case 3: return "Gold"
        case 4: return "Diamond"
        default: return "Bronze"
        }
    }
    
    /// Tier color
    var tierColor: Color {
        switch tier {
        case 1: return Color(hex: "CD7F32") // Bronze
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "FFD700") // Gold
        case 4: return Color(hex: "B9F2FF") // Diamond
        default: return Color(hex: "CD7F32")
        }
    }
    
    /// Formatted unlock date
    var unlockDateFormatted: String? {
        guard let date = unlockedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(
        key: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        tier: Int = 1,
        targetValue: Double = 1
    ) {
        self.id = UUID()
        self.key = key
        self.title = title
        self.achievementDescription = description
        self.icon = icon
        self.categoryRaw = category.rawValue
        self.tier = tier
        self.isUnlocked = false
        self.unlockedAt = nil
        self.progressValue = 0
        self.targetValue = targetValue
    }
    
    // MARK: - Methods
    
    /// Update progress and check if achievement should unlock
    /// - Parameter value: New progress value
    /// - Returns: True if newly unlocked
    @discardableResult
    func updateProgress(_ value: Double) -> Bool {
        progressValue = value
        if progressValue >= targetValue && !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
            return true
        }
        return false
    }
}
