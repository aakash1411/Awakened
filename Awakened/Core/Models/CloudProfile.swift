import Foundation
import CloudKit

/// Represents a player's public profile synced to CloudKit
/// This is a CKRecord wrapper — NOT a SwiftData model
struct CloudProfile: Identifiable, Hashable {
    
    // MARK: - Identity
    
    /// CloudKit record ID (derived from local player UUID)
    let id: String
    
    /// Player's display name
    var displayName: String
    
    /// Avatar emoji (e.g., "⚔️", "🧙‍♂️", "🐉")
    var avatarEmoji: String
    
    /// Short bio tagline
    var bio: String
    
    /// Earnable title displayed under name (e.g., "Season 1 Champion")
    var activeTitle: String
    
    // MARK: - Progression
    
    /// Current player level
    var level: Int
    
    /// Current rank raw value
    var rankRaw: String
    
    /// Total accumulated XP
    var totalXP: Int
    
    /// Current active streak in days
    var currentStreak: Int
    
    /// Longest streak ever achieved
    var longestStreak: Int
    
    // MARK: - Stats (levels only — not full XP)
    
    /// Strength stat level
    var strengthLevel: Int
    
    /// Agility stat level
    var agilityLevel: Int
    
    /// Vitality stat level
    var vitalityLevel: Int
    
    /// Sense stat level
    var senseLevel: Int
    
    /// Intelligence stat level
    var intelligenceLevel: Int
    
    // MARK: - Social
    
    /// Guild ID if member of a guild
    var guildID: String?
    
    /// Guild name (denormalized for display)
    var guildName: String?
    
    /// Duel wins count
    var duelWins: Int
    
    /// Duel losses count
    var duelLosses: Int
    
    /// Total quests completed
    var questsCompleted: Int
    
    /// Total achievements unlocked
    var achievementsUnlocked: Int
    
    // MARK: - Meta
    
    /// Whether this profile is publicly discoverable
    var isPublic: Bool
    
    /// When the profile was first created
    var joinDate: Date
    
    /// When the profile was last updated
    var lastUpdated: Date
    
    // MARK: - Computed Properties
    
    /// Player rank enum
    var rank: PlayerRank {
        PlayerRank(rawValue: rankRaw) ?? .e
    }
    
    /// Stat levels as array for radar chart
    var statLevels: [Int] {
        [strengthLevel, agilityLevel, vitalityLevel, senseLevel, intelligenceLevel]
    }
    
    /// Duel win rate
    var duelWinRate: Double {
        let total = duelWins + duelLosses
        guard total > 0 else { return 0 }
        return Double(duelWins) / Double(total)
    }
    
    /// Formatted duel record
    var duelRecord: String {
        "\(duelWins)W - \(duelLosses)L"
    }
    
    // MARK: - CKRecord Keys
    
    enum Keys {
        static let displayName = "displayName"
        static let avatarEmoji = "avatarEmoji"
        static let bio = "bio"
        static let activeTitle = "activeTitle"
        static let level = "level"
        static let rankRaw = "rankRaw"
        static let totalXP = "totalXP"
        static let currentStreak = "currentStreak"
        static let longestStreak = "longestStreak"
        static let strengthLevel = "strengthLevel"
        static let agilityLevel = "agilityLevel"
        static let vitalityLevel = "vitalityLevel"
        static let senseLevel = "senseLevel"
        static let intelligenceLevel = "intelligenceLevel"
        static let guildID = "guildID"
        static let guildName = "guildName"
        static let duelWins = "duelWins"
        static let duelLosses = "duelLosses"
        static let questsCompleted = "questsCompleted"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let isPublic = "isPublic"
        static let joinDate = "joinDate"
        static let lastUpdated = "lastUpdated"
        static let ownerRecordName = "ownerRecordName"
    }
    
    // MARK: - CKRecord Conversion
    
    /// Create a CloudProfile from a CKRecord
    /// - Parameter record: The CloudKit record
    /// - Returns: CloudProfile instance
    static func from(record: CKRecord) -> CloudProfile {
        CloudProfile(
            id: record.recordID.recordName,
            displayName: record[Keys.displayName] as? String ?? "Hunter",
            avatarEmoji: record[Keys.avatarEmoji] as? String ?? "⚔️",
            bio: record[Keys.bio] as? String ?? "",
            activeTitle: record[Keys.activeTitle] as? String ?? "",
            level: record[Keys.level] as? Int ?? 1,
            rankRaw: record[Keys.rankRaw] as? String ?? "E",
            totalXP: record[Keys.totalXP] as? Int ?? 0,
            currentStreak: record[Keys.currentStreak] as? Int ?? 0,
            longestStreak: record[Keys.longestStreak] as? Int ?? 0,
            strengthLevel: record[Keys.strengthLevel] as? Int ?? 1,
            agilityLevel: record[Keys.agilityLevel] as? Int ?? 1,
            vitalityLevel: record[Keys.vitalityLevel] as? Int ?? 1,
            senseLevel: record[Keys.senseLevel] as? Int ?? 1,
            intelligenceLevel: record[Keys.intelligenceLevel] as? Int ?? 1,
            guildID: record[Keys.guildID] as? String,
            guildName: record[Keys.guildName] as? String,
            duelWins: record[Keys.duelWins] as? Int ?? 0,
            duelLosses: record[Keys.duelLosses] as? Int ?? 0,
            questsCompleted: record[Keys.questsCompleted] as? Int ?? 0,
            achievementsUnlocked: record[Keys.achievementsUnlocked] as? Int ?? 0,
            isPublic: record[Keys.isPublic] as? Bool ?? true,
            joinDate: record[Keys.joinDate] as? Date ?? Date(),
            lastUpdated: record[Keys.lastUpdated] as? Date ?? Date()
        )
    }
    
    /// Convert to a CKRecord for saving
    /// - Parameter existingRecord: Optional existing record to update (preserves metadata)
    /// - Returns: CKRecord ready for CloudKit
    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let record = existingRecord ?? CKRecord(
            recordType: CloudKitService.RecordType.cloudProfile,
            recordID: CKRecord.ID(recordName: id)
        )
        
        record[Keys.displayName] = displayName
        record[Keys.avatarEmoji] = avatarEmoji
        record[Keys.bio] = bio
        record[Keys.activeTitle] = activeTitle
        record[Keys.level] = level
        record[Keys.rankRaw] = rankRaw
        record[Keys.totalXP] = totalXP
        record[Keys.currentStreak] = currentStreak
        record[Keys.longestStreak] = longestStreak
        record[Keys.strengthLevel] = strengthLevel
        record[Keys.agilityLevel] = agilityLevel
        record[Keys.vitalityLevel] = vitalityLevel
        record[Keys.senseLevel] = senseLevel
        record[Keys.intelligenceLevel] = intelligenceLevel
        record[Keys.guildID] = guildID
        record[Keys.guildName] = guildName
        record[Keys.duelWins] = duelWins
        record[Keys.duelLosses] = duelLosses
        record[Keys.questsCompleted] = questsCompleted
        record[Keys.achievementsUnlocked] = achievementsUnlocked
        record[Keys.isPublic] = isPublic
        record[Keys.joinDate] = joinDate
        record[Keys.lastUpdated] = Date()
        record[Keys.ownerRecordName] = id
        
        return record
    }
    
    /// Create a CloudProfile from a local Player model
    /// - Parameter player: Local Player model
    /// - Returns: CloudProfile reflecting current player state
    static func from(player: Player) -> CloudProfile {
        let completedQuests = player.quests.filter(\.isCompleted).count
        let unlockedAchievements = player.achievements.filter(\.isUnlocked).count
        
        return CloudProfile(
            id: player.id.uuidString,
            displayName: player.name,
            avatarEmoji: UserDefaults.standard.string(forKey: "avatarEmoji") ?? "⚔️",
            bio: UserDefaults.standard.string(forKey: "profileBio") ?? "",
            activeTitle: UserDefaults.standard.string(forKey: "activeTitle") ?? "",
            level: player.level,
            rankRaw: player.rank.rawValue,
            totalXP: player.totalXP,
            currentStreak: player.currentStreak,
            longestStreak: player.longestStreak,
            strengthLevel: player.stat(for: .strength)?.effectiveLevel ?? 1,
            agilityLevel: player.stat(for: .agility)?.effectiveLevel ?? 1,
            vitalityLevel: player.stat(for: .vitality)?.effectiveLevel ?? 1,
            senseLevel: player.stat(for: .sense)?.effectiveLevel ?? 1,
            intelligenceLevel: player.stat(for: .intelligence)?.effectiveLevel ?? 1,
            guildID: nil,
            guildName: nil,
            duelWins: 0,
            duelLosses: 0,
            questsCompleted: completedQuests,
            achievementsUnlocked: unlockedAchievements,
            isPublic: UserDefaults.standard.bool(forKey: "profileIsPublic"),
            joinDate: player.createdAt,
            lastUpdated: Date()
        )
    }
}
