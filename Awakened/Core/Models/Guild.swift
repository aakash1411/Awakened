import Foundation
import CloudKit
import SwiftUI

/// Represents a guild in the social system — CKRecord wrapper
struct Guild: Identifiable, Hashable {
    
    // MARK: - Identity
    
    /// CloudKit record name
    let id: String
    
    /// Guild name
    var name: String
    
    /// Guild description
    var description: String
    
    /// Emblem emoji
    var emblem: String
    
    /// Banner accent color hex
    var bannerColorHex: String
    
    /// Leader's player ID
    var leaderID: String
    
    // MARK: - Progression
    
    /// Guild level
    var guildLevel: Int
    
    /// Total guild XP
    var totalGuildXP: Int
    
    /// Current member count
    var memberCount: Int
    
    // MARK: - Settings
    
    /// Whether guild is publicly discoverable
    var isPublic: Bool
    
    /// Maximum members allowed
    var maxMembers: Int
    
    /// Minimum player rank to join
    var minRankToJoinRaw: String
    
    /// When the guild was created
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// Guild rank based on guild level
    var guildRank: GuildRank {
        GuildRank.from(level: guildLevel)
    }
    
    /// Minimum rank requirement
    var minRankToJoin: PlayerRank {
        PlayerRank(rawValue: minRankToJoinRaw) ?? .e
    }
    
    /// Banner accent color
    var bannerColor: Color {
        Color(hex: bannerColorHex)
    }
    
    /// XP needed for next guild level
    var xpForNextLevel: Int {
        guildLevel * 5000
    }
    
    /// Progress toward next level (0.0 to 1.0)
    var levelProgress: Double {
        let needed = xpForNextLevel
        guard needed > 0 else { return 0 }
        let currentLevelXP = (guildLevel - 1) * 5000
        let progressXP = totalGuildXP - currentLevelXP
        return min(max(Double(progressXP) / Double(needed - currentLevelXP), 0), 1)
    }
    
    /// Whether guild has room for more members
    var hasRoom: Bool {
        memberCount < maxMembers
    }
    
    /// XP bonus percentage from guild level
    var xpBonusPercent: Int {
        min(guildLevel, 5)
    }
    
    // MARK: - CKRecord Keys
    
    enum Keys {
        static let name = "name"
        static let description = "guildDescription"
        static let emblem = "emblem"
        static let bannerColorHex = "bannerColorHex"
        static let leaderID = "leaderID"
        static let guildLevel = "guildLevel"
        static let totalGuildXP = "totalGuildXP"
        static let memberCount = "memberCount"
        static let isPublic = "isPublic"
        static let maxMembers = "maxMembers"
        static let minRankToJoinRaw = "minRankToJoinRaw"
        static let createdAt = "createdAt"
    }
    
    // MARK: - CKRecord Conversion
    
    static func from(record: CKRecord) -> Guild {
        Guild(
            id: record.recordID.recordName,
            name: record[Keys.name] as? String ?? "Unnamed Guild",
            description: record[Keys.description] as? String ?? "",
            emblem: record[Keys.emblem] as? String ?? "⚔️",
            bannerColorHex: record[Keys.bannerColorHex] as? String ?? "007AFF",
            leaderID: record[Keys.leaderID] as? String ?? "",
            guildLevel: record[Keys.guildLevel] as? Int ?? 1,
            totalGuildXP: record[Keys.totalGuildXP] as? Int ?? 0,
            memberCount: record[Keys.memberCount] as? Int ?? 1,
            isPublic: record[Keys.isPublic] as? Bool ?? true,
            maxMembers: record[Keys.maxMembers] as? Int ?? 30,
            minRankToJoinRaw: record[Keys.minRankToJoinRaw] as? String ?? "E",
            createdAt: record[Keys.createdAt] as? Date ?? Date()
        )
    }
    
    func toCKRecord(existingRecord: CKRecord? = nil) -> CKRecord {
        let record = existingRecord ?? CKRecord(
            recordType: CloudKitService.RecordType.guild,
            recordID: CKRecord.ID(recordName: id)
        )
        record[Keys.name] = name
        record[Keys.description] = description
        record[Keys.emblem] = emblem
        record[Keys.bannerColorHex] = bannerColorHex
        record[Keys.leaderID] = leaderID
        record[Keys.guildLevel] = guildLevel
        record[Keys.totalGuildXP] = totalGuildXP
        record[Keys.memberCount] = memberCount
        record[Keys.isPublic] = isPublic
        record[Keys.maxMembers] = maxMembers
        record[Keys.minRankToJoinRaw] = minRankToJoinRaw
        record[Keys.createdAt] = createdAt
        return record
    }
}

// MARK: - Guild Rank

/// Guild rank tiers based on guild level
enum GuildRank: String, CaseIterable, Comparable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case legendary = "Legendary"
    
    var minLevel: Int {
        switch self {
        case .bronze: return 1
        case .silver: return 5
        case .gold: return 15
        case .platinum: return 30
        case .diamond: return 50
        case .legendary: return 75
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .platinum: return Color(hex: "E5E4E2")
        case .diamond: return Color(hex: "B9F2FF")
        case .legendary: return AppColors.accentPurple
        }
    }
    
    var icon: String {
        switch self {
        case .bronze: return "shield"
        case .silver: return "shield.fill"
        case .gold: return "shield.lefthalf.filled"
        case .platinum: return "shield.checkered"
        case .diamond: return "diamond"
        case .legendary: return "crown.fill"
        }
    }
    
    static func from(level: Int) -> GuildRank {
        for rank in GuildRank.allCases.reversed() {
            if level >= rank.minLevel { return rank }
        }
        return .bronze
    }
    
    static func < (lhs: GuildRank, rhs: GuildRank) -> Bool {
        lhs.minLevel < rhs.minLevel
    }
}

// MARK: - Guild Member

/// Represents a guild member — CKRecord wrapper
struct GuildMember: Identifiable {
    let id: String
    let guildID: String
    let playerID: String
    var role: GuildRole
    let joinedAt: Date
    var weeklyXPContribution: Int
    var totalXPContribution: Int
    
    /// Member's profile (loaded separately)
    var profile: CloudProfile?
    
    enum Keys {
        static let guildID = "guildID"
        static let playerID = "playerID"
        static let role = "role"
        static let joinedAt = "joinedAt"
        static let weeklyXPContribution = "weeklyXPContribution"
        static let totalXPContribution = "totalXPContribution"
    }
    
    static func from(record: CKRecord) -> GuildMember {
        GuildMember(
            id: record.recordID.recordName,
            guildID: record[Keys.guildID] as? String ?? "",
            playerID: record[Keys.playerID] as? String ?? "",
            role: GuildRole(rawValue: record[Keys.role] as? String ?? "") ?? .member,
            joinedAt: record[Keys.joinedAt] as? Date ?? Date(),
            weeklyXPContribution: record[Keys.weeklyXPContribution] as? Int ?? 0,
            totalXPContribution: record[Keys.totalXPContribution] as? Int ?? 0
        )
    }
}

/// Guild member roles
enum GuildRole: String, Codable, CaseIterable, Comparable {
    case leader
    case officer
    case member
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .leader: return "crown.fill"
        case .officer: return "star.fill"
        case .member: return "person.fill"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .leader: return 0
        case .officer: return 1
        case .member: return 2
        }
    }
    
    static func < (lhs: GuildRole, rhs: GuildRole) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
