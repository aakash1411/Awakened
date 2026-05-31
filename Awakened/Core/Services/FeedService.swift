import Foundation
import CloudKit
import Combine
import SwiftUI

/// Manages the social activity feed — posting events and reactions via CloudKit
@MainActor
class FeedService: ObservableObject {
    
    // MARK: - Published State
    
    /// Feed events from friends
    @Published var friendFeed: [FeedEvent] = []
    
    /// Feed events from guild
    @Published var guildFeed: [FeedEvent] = []
    
    /// Whether feed is loading
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Post Events
    
    /// Post a feed event to CloudKit
    /// - Parameters:
    ///   - type: Event type
    ///   - detail: Human-readable detail string
    ///   - value: Optional numeric value (e.g., XP earned, level reached)
    ///   - guildID: Optional guild ID for guild feed
    func postEvent(
        type: FeedEventType,
        detail: String,
        value: Int = 0,
        guildID: String? = nil
    ) async {
        guard let myID = myPlayerID else { return }
        
        let playerName = UserDefaults.standard.string(forKey: "avatarEmoji").map { "\($0) " } ?? ""
        let displayName = playerName + (UserDefaults.standard.string(forKey: "playerDisplayName") ?? "Hunter")
        
        let record = CKRecord(recordType: CloudKitService.RecordType.feedEvent)
        record[FeedEvent.Keys.playerID] = myID
        record[FeedEvent.Keys.playerName] = displayName
        record[FeedEvent.Keys.eventType] = type.rawValue
        record[FeedEvent.Keys.detail] = detail
        record[FeedEvent.Keys.value] = value
        record[FeedEvent.Keys.guildID] = guildID
        record[FeedEvent.Keys.timestamp] = Date()
        
        do {
            try await cloudKit.savePublic(record)
        } catch {
            print("FeedService: Failed to post event — \(error)")
        }
    }
    
    // MARK: - Fetch Feed
    
    /// Fetch friend feed events
    /// - Parameter friendIDs: List of friend player IDs
    func fetchFriendFeed(friendIDs: [String]) async {
        guard !friendIDs.isEmpty else {
            friendFeed = []
            return
        }
        
        isLoading = true
        
        // CloudKit IN predicate for multiple friend IDs
        let predicate = NSPredicate(
            format: "%K IN %@",
            FeedEvent.Keys.playerID, friendIDs
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.feedEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: FeedEvent.Keys.timestamp, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 50)
            var events = records.map { FeedEvent.from(record: $0) }
            
            // Fetch reaction counts for each event
            for i in events.indices {
                events[i].reactions = await fetchReactions(for: events[i].id)
            }
            
            friendFeed = events
        } catch {
            print("FeedService: Failed to fetch friend feed — \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch guild feed events
    /// - Parameter guildID: Guild ID
    func fetchGuildFeed(guildID: String) async {
        let predicate = NSPredicate(
            format: "%K == %@",
            FeedEvent.Keys.guildID, guildID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.feedEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: FeedEvent.Keys.timestamp, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 50)
            guildFeed = records.map { FeedEvent.from(record: $0) }
        } catch {
            print("FeedService: Failed to fetch guild feed — \(error)")
        }
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to a feed event
    /// - Parameters:
    ///   - eventID: Feed event record ID
    ///   - type: Reaction type
    func addReaction(to eventID: String, type: ReactionType) async {
        guard let myID = myPlayerID else { return }
        
        let record = CKRecord(recordType: CloudKitService.RecordType.feedReaction)
        record[FeedReaction.Keys.eventID] = eventID
        record[FeedReaction.Keys.playerID] = myID
        record[FeedReaction.Keys.reactionType] = type.rawValue
        record[FeedReaction.Keys.timestamp] = Date()
        
        do {
            try await cloudKit.savePublic(record)
            SoundManager.shared.haptic(.light)
        } catch {
            print("FeedService: Failed to add reaction — \(error)")
        }
    }
    
    /// Fetch reactions for a feed event
    /// - Parameter eventID: Feed event record ID
    /// - Returns: Dictionary of reaction type to count
    func fetchReactions(for eventID: String) async -> [ReactionType: Int] {
        let predicate = NSPredicate(format: "%K == %@", FeedReaction.Keys.eventID, eventID)
        let query = CKQuery(recordType: CloudKitService.RecordType.feedReaction, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 100)
            var counts: [ReactionType: Int] = [:]
            for record in records {
                if let rawType = record[FeedReaction.Keys.reactionType] as? String,
                   let type = ReactionType(rawValue: rawType) {
                    counts[type, default: 0] += 1
                }
            }
            return counts
        } catch {
            return [:]
        }
    }
    
    // MARK: - Convenience Posters
    
    /// Post a level up event
    func postLevelUp(newLevel: Int, rank: PlayerRank) async {
        await postEvent(type: .levelUp, detail: "Reached Level \(newLevel) (\(rank.displayName))", value: newLevel)
    }
    
    /// Post a rank up event
    func postRankUp(newRank: PlayerRank) async {
        await postEvent(type: .rankUp, detail: "Promoted to \(newRank.displayName)!", value: newRank.minLevel)
    }
    
    /// Post a quest complete event
    func postQuestComplete(questTitle: String, xpEarned: Int) async {
        await postEvent(type: .questComplete, detail: questTitle, value: xpEarned)
    }
    
    /// Post an achievement unlocked event
    func postAchievementUnlocked(title: String) async {
        await postEvent(type: .achievementUnlocked, detail: title)
    }
    
    /// Post a personal record event
    func postPersonalRecord(exerciseName: String, weight: Double) async {
        await postEvent(type: .personalRecord, detail: "\(exerciseName) — \(String(format: "%.1f", weight)) kg")
    }
    
    /// Post a streak milestone event
    func postStreakMilestone(days: Int) async {
        await postEvent(type: .streakMilestone, detail: "\(days)-day streak!", value: days)
    }
}

// MARK: - Feed Event

/// Represents a social feed event
struct FeedEvent: Identifiable {
    let id: String
    let playerID: String
    let playerName: String
    let eventType: FeedEventType
    let detail: String
    let value: Int
    let guildID: String?
    let timestamp: Date
    var reactions: [ReactionType: Int] = [:]
    
    enum Keys {
        static let playerID = "playerID"
        static let playerName = "playerName"
        static let eventType = "eventType"
        static let detail = "detail"
        static let value = "value"
        static let guildID = "guildID"
        static let timestamp = "timestamp"
    }
    
    static func from(record: CKRecord) -> FeedEvent {
        FeedEvent(
            id: record.recordID.recordName,
            playerID: record[Keys.playerID] as? String ?? "",
            playerName: record[Keys.playerName] as? String ?? "Hunter",
            eventType: FeedEventType(rawValue: record[Keys.eventType] as? String ?? "") ?? .questComplete,
            detail: record[Keys.detail] as? String ?? "",
            value: record[Keys.value] as? Int ?? 0,
            guildID: record[Keys.guildID] as? String,
            timestamp: record[Keys.timestamp] as? Date ?? Date()
        )
    }
    
    /// Icon for this event type
    var icon: String { eventType.icon }
    
    /// Color for this event type
    var color: Color { eventType.color }
    
    /// Formatted timestamp
    var timeAgo: String {
        timestamp.formatted(.relative(presentation: .named))
    }
}

/// Types of feed events
enum FeedEventType: String, Codable {
    case levelUp
    case rankUp
    case questComplete
    case achievementUnlocked
    case personalRecord
    case streakMilestone
    case guildJoined
    case duelWon
    case seasonRankAchieved
    
    var icon: String {
        switch self {
        case .levelUp: return "arrow.up.circle.fill"
        case .rankUp: return "star.circle.fill"
        case .questComplete: return "checkmark.circle.fill"
        case .achievementUnlocked: return "trophy.fill"
        case .personalRecord: return "flame.fill"
        case .streakMilestone: return "flame.fill"
        case .guildJoined: return "shield.lefthalf.filled"
        case .duelWon: return "bolt.fill"
        case .seasonRankAchieved: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .levelUp: return AppColors.primaryBlue
        case .rankUp: return AppColors.accentPurple
        case .questComplete: return AppColors.success
        case .achievementUnlocked: return .orange
        case .personalRecord: return AppColors.strengthColor
        case .streakMilestone: return .orange
        case .guildJoined: return AppColors.accentCyan
        case .duelWon: return AppColors.strengthColor
        case .seasonRankAchieved: return AppColors.accentPurple
        }
    }
    
    var label: String {
        switch self {
        case .levelUp: return "Level Up"
        case .rankUp: return "Rank Up"
        case .questComplete: return "Quest Complete"
        case .achievementUnlocked: return "Achievement"
        case .personalRecord: return "New PR"
        case .streakMilestone: return "Streak"
        case .guildJoined: return "Guild"
        case .duelWon: return "Duel Won"
        case .seasonRankAchieved: return "Season Rank"
        }
    }
}

// MARK: - Feed Reaction

/// A reaction on a feed event
struct FeedReaction {
    enum Keys {
        static let eventID = "eventID"
        static let playerID = "playerID"
        static let reactionType = "reactionType"
        static let timestamp = "timestamp"
    }
}

/// Available reaction types
enum ReactionType: String, CaseIterable, Codable, Hashable {
    case fire
    case strong
    case clap
    case energy
    case trophy
    case target
    
    var emoji: String {
        switch self {
        case .fire: return "🔥"
        case .strong: return "💪"
        case .clap: return "👏"
        case .energy: return "⚡"
        case .trophy: return "🏆"
        case .target: return "🎯"
        }
    }
}
