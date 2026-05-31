import Foundation
import CloudKit
import Combine
import SwiftUI

/// Manages competitive leaderboards via CloudKit
@MainActor
class LeaderboardService: ObservableObject {
    
    // MARK: - Published State
    
    /// Current leaderboard entries
    @Published var entries: [LeaderboardEntry] = []
    
    /// Current player's position on the active board
    @Published var myPosition: Int?
    
    /// Whether loading
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Fetch Leaderboard
    
    /// Fetch a leaderboard
    /// - Parameters:
    ///   - type: Board type (totalXP, weeklyXP, streak, etc.)
    ///   - scope: Scope (global, friends, guild)
    ///   - friendIDs: Friend IDs if scope is .friends
    ///   - guildMemberIDs: Guild member IDs if scope is .guild
    ///   - limit: Max entries
    func fetchLeaderboard(
        type: LeaderboardType,
        scope: LeaderboardScope = .global,
        friendIDs: [String] = [],
        guildMemberIDs: [String] = [],
        limit: Int = 50
    ) async {
        isLoading = true
        
        let sortKey = type.cloudProfileKey
        let predicate: NSPredicate
        
        switch scope {
        case .global:
            predicate = NSPredicate(format: "%K == %@", CloudProfile.Keys.isPublic, NSNumber(value: true))
        case .friends:
            guard let myID = myPlayerID else {
                isLoading = false
                return
            }
            let allIDs = friendIDs + [myID]
            predicate = NSPredicate(format: "%K IN %@", CloudProfile.Keys.ownerRecordName, allIDs)
        case .guild:
            predicate = NSPredicate(format: "%K IN %@", CloudProfile.Keys.ownerRecordName, guildMemberIDs)
        }
        
        let query = CKQuery(recordType: CloudKitService.RecordType.cloudProfile, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: limit)
            var leaderboard: [LeaderboardEntry] = []
            
            for (index, record) in records.enumerated() {
                let profile = CloudProfile.from(record: record)
                let score = type.extractScore(from: profile)
                
                leaderboard.append(LeaderboardEntry(
                    position: index + 1,
                    playerID: profile.id,
                    displayName: profile.displayName,
                    avatarEmoji: profile.avatarEmoji,
                    rank: profile.rank,
                    level: profile.level,
                    score: score,
                    isCurrentUser: profile.id == myPlayerID
                ))
            }
            
            entries = leaderboard
            myPosition = leaderboard.first(where: \.isCurrentUser)?.position
            
        } catch {
            print("LeaderboardService: Failed to fetch — \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch multiple board types for dashboard preview
    func fetchDashboardPreview(friendIDs: [String]) async -> (global: Int?, friends: Int?) {
        // Quick global rank
        await fetchLeaderboard(type: .totalXP, scope: .global, limit: 50)
        let globalPos = myPosition
        
        // Quick friends rank
        await fetchLeaderboard(type: .totalXP, scope: .friends, friendIDs: friendIDs, limit: 50)
        let friendsPos = myPosition
        
        return (globalPos, friendsPos)
    }
}

// MARK: - Leaderboard Entry

/// A single entry in a leaderboard
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let position: Int
    let playerID: String
    let displayName: String
    let avatarEmoji: String
    let rank: PlayerRank
    let level: Int
    let score: Int
    let isCurrentUser: Bool
    
    /// Position medal icon
    var medalIcon: String? {
        switch position {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal"
        default: return nil
        }
    }
    
    /// Position medal color
    var medalColor: Color {
        switch position {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return AppColors.textTertiary
        }
    }
}

// MARK: - Leaderboard Type

/// What the leaderboard measures
enum LeaderboardType: String, CaseIterable, Identifiable {
    case totalXP
    case level
    case streak
    case questsCompleted
    case duelWins
    case strengthLevel
    case agilityLevel
    case vitalityLevel
    case senseLevel
    case intelligenceLevel
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .totalXP: return "Total XP"
        case .level: return "Level"
        case .streak: return "Streak"
        case .questsCompleted: return "Quests"
        case .duelWins: return "Duel Wins"
        case .strengthLevel: return "Strength"
        case .agilityLevel: return "Sensation"
        case .vitalityLevel: return "Vitality"
        case .senseLevel: return "Spirit"
        case .intelligenceLevel: return "Intelligence"
        }
    }
    
    var icon: String {
        switch self {
        case .totalXP: return "bolt.fill"
        case .level: return "star.fill"
        case .streak: return "flame.fill"
        case .questsCompleted: return "checkmark.circle.fill"
        case .duelWins: return "crossed.swords"
        case .strengthLevel: return StatType.strength.icon
        case .agilityLevel: return StatType.agility.icon
        case .vitalityLevel: return StatType.vitality.icon
        case .senseLevel: return StatType.sense.icon
        case .intelligenceLevel: return StatType.intelligence.icon
        }
    }
    
    /// Corresponding CloudProfile key for sorting
    var cloudProfileKey: String {
        switch self {
        case .totalXP: return CloudProfile.Keys.totalXP
        case .level: return CloudProfile.Keys.level
        case .streak: return CloudProfile.Keys.currentStreak
        case .questsCompleted: return CloudProfile.Keys.questsCompleted
        case .duelWins: return CloudProfile.Keys.duelWins
        case .strengthLevel: return CloudProfile.Keys.strengthLevel
        case .agilityLevel: return CloudProfile.Keys.agilityLevel
        case .vitalityLevel: return CloudProfile.Keys.vitalityLevel
        case .senseLevel: return CloudProfile.Keys.senseLevel
        case .intelligenceLevel: return CloudProfile.Keys.intelligenceLevel
        }
    }
    
    /// Extract score from a CloudProfile
    func extractScore(from profile: CloudProfile) -> Int {
        switch self {
        case .totalXP: return profile.totalXP
        case .level: return profile.level
        case .streak: return profile.currentStreak
        case .questsCompleted: return profile.questsCompleted
        case .duelWins: return profile.duelWins
        case .strengthLevel: return profile.strengthLevel
        case .agilityLevel: return profile.agilityLevel
        case .vitalityLevel: return profile.vitalityLevel
        case .senseLevel: return profile.senseLevel
        case .intelligenceLevel: return profile.intelligenceLevel
        }
    }
}

/// Leaderboard scope
enum LeaderboardScope: String, CaseIterable {
    case global = "Global"
    case friends = "Friends"
    case guild = "Guild"
}
