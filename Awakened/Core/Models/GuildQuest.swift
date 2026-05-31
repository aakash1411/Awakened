import Foundation
import CloudKit
import SwiftUI

/// A cooperative guild quest — all members contribute toward a shared goal
struct GuildQuest: Identifiable {
    
    // MARK: - Identity
    
    let id: String
    let guildID: String
    
    /// Quest title
    var title: String
    
    /// Quest description
    var description: String
    
    /// Quest type
    var questType: GuildQuestType
    
    // MARK: - Progress
    
    /// Target value to complete the quest
    var targetValue: Int
    
    /// Current progress from all members combined
    var currentValue: Int
    
    /// Whether the quest is completed
    var isCompleted: Bool
    
    // MARK: - Rewards
    
    /// Guild XP reward on completion
    var guildXPReward: Int
    
    /// Individual XP bonus for contributors
    var individualXPBonus: Int
    
    // MARK: - Timing
    
    /// When the quest was created
    var createdAt: Date
    
    /// When the quest expires
    var expiresAt: Date
    
    /// When the quest was completed (nil if still active)
    var completedAt: Date?
    
    // MARK: - Computed Properties
    
    /// Progress fraction (0.0 to 1.0)
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    /// Whether the quest has expired
    var isExpired: Bool {
        Date() > expiresAt && !isCompleted
    }
    
    /// Time remaining formatted
    var timeRemaining: String {
        guard !isExpired && !isCompleted else { return isCompleted ? "Complete" : "Expired" }
        let interval = expiresAt.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h left" }
        return "\(hours)h left"
    }
    
    /// Quest type icon
    var icon: String { questType.icon }
    
    /// Quest type color
    var color: Color { questType.color }
    
    // MARK: - CKRecord Keys
    
    enum Keys {
        static let guildID = "guildID"
        static let title = "title"
        static let description = "questDescription"
        static let questType = "questType"
        static let targetValue = "targetValue"
        static let currentValue = "currentValue"
        static let isCompleted = "isCompleted"
        static let guildXPReward = "guildXPReward"
        static let individualXPBonus = "individualXPBonus"
        static let createdAt = "createdAt"
        static let expiresAt = "expiresAt"
        static let completedAt = "completedAt"
    }
    
    // MARK: - CKRecord Conversion
    
    static func from(record: CKRecord) -> GuildQuest {
        GuildQuest(
            id: record.recordID.recordName,
            guildID: record[Keys.guildID] as? String ?? "",
            title: record[Keys.title] as? String ?? "Guild Quest",
            description: record[Keys.description] as? String ?? "",
            questType: GuildQuestType(rawValue: record[Keys.questType] as? String ?? "") ?? .totalXP,
            targetValue: record[Keys.targetValue] as? Int ?? 0,
            currentValue: record[Keys.currentValue] as? Int ?? 0,
            isCompleted: record[Keys.isCompleted] as? Bool ?? false,
            guildXPReward: record[Keys.guildXPReward] as? Int ?? 0,
            individualXPBonus: record[Keys.individualXPBonus] as? Int ?? 0,
            createdAt: record[Keys.createdAt] as? Date ?? Date(),
            expiresAt: record[Keys.expiresAt] as? Date ?? Date(),
            completedAt: record[Keys.completedAt] as? Date
        )
    }
    
    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let record = existingRecord ?? CKRecord(
            recordType: CloudKitService.RecordType.guildQuest,
            recordID: CKRecord.ID(recordName: id)
        )
        record[Keys.guildID] = guildID
        record[Keys.title] = title
        record[Keys.description] = description
        record[Keys.questType] = questType.rawValue
        record[Keys.targetValue] = targetValue
        record[Keys.currentValue] = currentValue
        record[Keys.isCompleted] = isCompleted
        record[Keys.guildXPReward] = guildXPReward
        record[Keys.individualXPBonus] = individualXPBonus
        record[Keys.createdAt] = createdAt
        record[Keys.expiresAt] = expiresAt
        record[Keys.completedAt] = completedAt
        return record
    }
    
    // MARK: - Templates
    
    /// Generate a weekly guild quest based on type
    static func weeklyTemplate(guildID: String, type: GuildQuestType, memberCount: Int) -> GuildQuest {
        let calendar = Calendar.current
        let now = Date()
        let expiry = calendar.date(byAdding: .day, value: 7, to: now)!
        let scaledTarget = type.baseTarget * max(1, memberCount)
        
        return GuildQuest(
            id: UUID().uuidString,
            guildID: guildID,
            title: type.questTitle,
            description: type.questDescription,
            questType: type,
            targetValue: scaledTarget,
            currentValue: 0,
            isCompleted: false,
            guildXPReward: type.baseGuildXP,
            individualXPBonus: type.baseIndividualXP,
            createdAt: now,
            expiresAt: expiry,
            completedAt: nil
        )
    }
}

// MARK: - Guild Quest Type

/// Types of cooperative guild quests
enum GuildQuestType: String, CaseIterable, Codable, Identifiable {
    case totalXP
    case totalWorkouts
    case totalQuests
    case totalSteps
    case streakKeepers
    case statGrind
    
    var id: String { rawValue }
    
    var questTitle: String {
        switch self {
        case .totalXP: return "XP Harvest"
        case .totalWorkouts: return "Iron Brigade"
        case .totalQuests: return "Quest Blitz"
        case .totalSteps: return "March of Progress"
        case .streakKeepers: return "Flame Guardians"
        case .statGrind: return "Power Surge"
        }
    }
    
    var questDescription: String {
        switch self {
        case .totalXP: return "Earn combined XP across all guild members"
        case .totalWorkouts: return "Complete workouts as a guild"
        case .totalQuests: return "Complete individual quests together"
        case .totalSteps: return "Walk a combined step total"
        case .streakKeepers: return "Every member must maintain their streak"
        case .statGrind: return "Earn stat-specific XP as a guild"
        }
    }
    
    var icon: String {
        switch self {
        case .totalXP: return "bolt.fill"
        case .totalWorkouts: return "dumbbell.fill"
        case .totalQuests: return "checkmark.circle.fill"
        case .totalSteps: return "figure.walk"
        case .streakKeepers: return "flame.fill"
        case .statGrind: return "chart.bar.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .totalXP: return AppColors.primaryBlue
        case .totalWorkouts: return AppColors.strengthColor
        case .totalQuests: return AppColors.success
        case .totalSteps: return AppColors.vitalityColor
        case .streakKeepers: return .orange
        case .statGrind: return AppColors.accentPurple
        }
    }
    
    /// Base target per member (scaled by member count)
    var baseTarget: Int {
        switch self {
        case .totalXP: return 2000
        case .totalWorkouts: return 5
        case .totalQuests: return 10
        case .totalSteps: return 50000
        case .streakKeepers: return 1
        case .statGrind: return 1000
        }
    }
    
    /// Base guild XP reward
    var baseGuildXP: Int {
        switch self {
        case .totalXP: return 500
        case .totalWorkouts: return 400
        case .totalQuests: return 350
        case .totalSteps: return 300
        case .streakKeepers: return 600
        case .statGrind: return 450
        }
    }
    
    /// Base individual XP bonus
    var baseIndividualXP: Int {
        switch self {
        case .totalXP: return 100
        case .totalWorkouts: return 80
        case .totalQuests: return 75
        case .totalSteps: return 60
        case .streakKeepers: return 120
        case .statGrind: return 90
        }
    }
}

// MARK: - Guild Quest Contribution

/// Tracks individual member contributions to guild quests
struct GuildQuestContribution: Identifiable {
    let id: String
    let questID: String
    let playerID: String
    var contributionValue: Int
    let updatedAt: Date
    
    /// Contributor's profile (loaded separately)
    var profile: CloudProfile?
    
    enum Keys {
        static let questID = "questID"
        static let playerID = "playerID"
        static let contributionValue = "contributionValue"
        static let updatedAt = "updatedAt"
    }
    
    static func from(record: CKRecord) -> GuildQuestContribution {
        GuildQuestContribution(
            id: record.recordID.recordName,
            questID: record[Keys.questID] as? String ?? "",
            playerID: record[Keys.playerID] as? String ?? "",
            contributionValue: record[Keys.contributionValue] as? Int ?? 0,
            updatedAt: record[Keys.updatedAt] as? Date ?? Date()
        )
    }
}
