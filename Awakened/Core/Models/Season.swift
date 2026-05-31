import Foundation
import CloudKit
import SwiftUI

/// A ranked season with rewards and titles — CKRecord wrapper
struct Season: Identifiable {
    
    let id: String
    
    /// Season name (e.g. "Season 1 — Rise of the Hunters")
    var name: String
    
    /// Season number
    var seasonNumber: Int
    
    /// Start date
    var startDate: Date
    
    /// End date
    var endDate: Date
    
    /// Whether this season is currently active
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    /// Whether this season has ended
    var hasEnded: Bool {
        Date() > endDate
    }
    
    /// Days remaining
    var daysRemaining: Int {
        guard !hasEnded else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
    
    enum Keys {
        static let name = "name"
        static let seasonNumber = "seasonNumber"
        static let startDate = "startDate"
        static let endDate = "endDate"
    }
    
    static func from(record: CKRecord) -> Season {
        Season(
            id: record.recordID.recordName,
            name: record[Keys.name] as? String ?? "Season",
            seasonNumber: record[Keys.seasonNumber] as? Int ?? 1,
            startDate: record[Keys.startDate] as? Date ?? Date(),
            endDate: record[Keys.endDate] as? Date ?? Date()
        )
    }
}

// MARK: - Season Entry

/// A player's entry in a season — tracks XP earned during the season
struct SeasonEntry: Identifiable {
    let id: String
    let seasonID: String
    let playerID: String
    var seasonXP: Int
    var seasonTier: SeasonTier
    var questsCompleted: Int
    var duelsWon: Int
    var peakLevel: Int
    
    /// Player profile (loaded separately)
    var profile: CloudProfile?
    
    enum Keys {
        static let seasonID = "seasonID"
        static let playerID = "playerID"
        static let seasonXP = "seasonXP"
        static let seasonTier = "seasonTier"
        static let questsCompleted = "questsCompleted"
        static let duelsWon = "duelsWon"
        static let peakLevel = "peakLevel"
    }
    
    static func from(record: CKRecord) -> SeasonEntry {
        SeasonEntry(
            id: record.recordID.recordName,
            seasonID: record[Keys.seasonID] as? String ?? "",
            playerID: record[Keys.playerID] as? String ?? "",
            seasonXP: record[Keys.seasonXP] as? Int ?? 0,
            seasonTier: SeasonTier(rawValue: record[Keys.seasonTier] as? String ?? "") ?? .unranked,
            questsCompleted: record[Keys.questsCompleted] as? Int ?? 0,
            duelsWon: record[Keys.duelsWon] as? Int ?? 0,
            peakLevel: record[Keys.peakLevel] as? Int ?? 1
        )
    }
}

// MARK: - Season Tier

/// Seasonal rank tiers with XP thresholds and rewards
enum SeasonTier: String, CaseIterable, Comparable, Codable, Identifiable {
    case unranked
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case champion
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    /// Title string awarded at season end
    var title: String {
        switch self {
        case .unranked: return ""
        case .bronze: return "Bronze Hunter"
        case .silver: return "Silver Hunter"
        case .gold: return "Golden Warrior"
        case .platinum: return "Platinum Slayer"
        case .diamond: return "Diamond Elite"
        case .champion: return "Season Champion"
        }
    }
    
    /// Minimum season XP to reach this tier
    var minXP: Int {
        switch self {
        case .unranked: return 0
        case .bronze: return 1000
        case .silver: return 5000
        case .gold: return 15000
        case .platinum: return 35000
        case .diamond: return 75000
        case .champion: return 150000
        }
    }
    
    /// XP bonus reward at season end
    var xpReward: Int {
        switch self {
        case .unranked: return 0
        case .bronze: return 200
        case .silver: return 500
        case .gold: return 1000
        case .platinum: return 2000
        case .diamond: return 5000
        case .champion: return 10000
        }
    }
    
    var icon: String {
        switch self {
        case .unranked: return "circle.dashed"
        case .bronze: return "shield"
        case .silver: return "shield.fill"
        case .gold: return "shield.lefthalf.filled"
        case .platinum: return "shield.checkered"
        case .diamond: return "diamond"
        case .champion: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .unranked: return AppColors.textTertiary
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .platinum: return Color(hex: "E5E4E2")
        case .diamond: return Color(hex: "B9F2FF")
        case .champion: return AppColors.accentPurple
        }
    }
    
    /// Next tier (nil if champion)
    var next: SeasonTier? {
        let all = SeasonTier.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
    
    /// Progress toward next tier (0.0 to 1.0)
    func progress(currentXP: Int) -> Double {
        guard let nextTier = next else { return 1.0 }
        let range = nextTier.minXP - minXP
        guard range > 0 else { return 0 }
        let progress = currentXP - minXP
        return min(max(Double(progress) / Double(range), 0), 1.0)
    }
    
    /// Determine tier from XP
    static func from(xp: Int) -> SeasonTier {
        for tier in SeasonTier.allCases.reversed() {
            if xp >= tier.minXP { return tier }
        }
        return .unranked
    }
    
    static func < (lhs: SeasonTier, rhs: SeasonTier) -> Bool {
        lhs.minXP < rhs.minXP
    }
}
