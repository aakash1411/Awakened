import Foundation
import CloudKit
import Combine
import SwiftUI

/// Manages 1v1 PvP duels/challenges between friends via CloudKit
@MainActor
class DuelService: ObservableObject {
    
    // MARK: - Published State
    
    /// Active duels involving the current player
    @Published var activeDuels: [Duel] = []
    
    /// Pending duel challenges (incoming)
    @Published var pendingChallenges: [Duel] = []
    
    /// Completed duel history
    @Published var duelHistory: [Duel] = []
    
    /// Overall stats
    @Published var wins: Int = 0
    @Published var losses: Int = 0
    
    /// Whether loading
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Challenge
    
    /// Challenge a friend to a duel
    func challengeFriend(
        _ opponentID: String,
        type: DuelType,
        durationHours: Int = 168,
        stakes: Int = 100
    ) async throws {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        
        let record = CKRecord(recordType: CloudKitService.RecordType.duel)
        record[Duel.Keys.challengerID] = myID
        record[Duel.Keys.opponentID] = opponentID
        record[Duel.Keys.duelType] = type.rawValue
        record[Duel.Keys.status] = DuelStatus.pending.rawValue
        record[Duel.Keys.stakes] = stakes
        record[Duel.Keys.startDate] = Date()
        record[Duel.Keys.endDate] = Calendar.current.date(byAdding: .hour, value: durationHours, to: Date())
        record[Duel.Keys.challengerScore] = 0
        record[Duel.Keys.opponentScore] = 0
        record[Duel.Keys.winnerID] = ""
        
        try await cloudKit.savePublic(record)
        await fetchActiveDuels()
    }
    
    // MARK: - Respond
    
    /// Accept or decline a duel challenge
    func respondToChallenge(_ duel: Duel, accept: Bool) async throws {
        let recordID = CKRecord.ID(recordName: duel.id)
        let record = try await cloudKit.fetchPublic(recordID: recordID)
        
        if accept {
            record[Duel.Keys.status] = DuelStatus.active.rawValue
            record[Duel.Keys.startDate] = Date()
            // Reset end date from now
            let durationHours = 168 // 1 week
            record[Duel.Keys.endDate] = Calendar.current.date(byAdding: .hour, value: durationHours, to: Date())
        } else {
            record[Duel.Keys.status] = DuelStatus.declined.rawValue
        }
        
        try await cloudKit.savePublic(record)
        await fetchActiveDuels()
        await fetchPendingChallenges()
    }
    
    // MARK: - Update Progress
    
    /// Update the current player's score in an active duel
    /// - Parameters:
    ///   - duelID: Duel record ID
    ///   - score: New score value
    func updateMyScore(duelID: String, score: Int) async {
        guard let myID = myPlayerID else { return }
        
        let recordID = CKRecord.ID(recordName: duelID)
        do {
            let record = try await cloudKit.fetchPublic(recordID: recordID)
            let challengerID = record[Duel.Keys.challengerID] as? String ?? ""
            
            if challengerID == myID {
                record[Duel.Keys.challengerScore] = score
            } else {
                record[Duel.Keys.opponentScore] = score
            }
            
            try await cloudKit.savePublic(record)
        } catch {
            print("DuelService: Failed to update score — \(error)")
        }
    }
    
    /// Check and finalize completed duels
    func checkForCompletedDuels() async {
        for duel in activeDuels where duel.isExpired {
            await finalizeDuel(duel)
        }
    }
    
    /// Finalize a duel — determine winner and award XP
    private func finalizeDuel(_ duel: Duel) async {
        let recordID = CKRecord.ID(recordName: duel.id)
        do {
            let record = try await cloudKit.fetchPublic(recordID: recordID)
            
            let challengerScore = record[Duel.Keys.challengerScore] as? Int ?? 0
            let opponentScore = record[Duel.Keys.opponentScore] as? Int ?? 0
            
            let winnerID: String
            if challengerScore > opponentScore {
                winnerID = duel.challengerID
            } else if opponentScore > challengerScore {
                winnerID = duel.opponentID
            } else {
                winnerID = "tie"
            }
            
            record[Duel.Keys.winnerID] = winnerID
            record[Duel.Keys.status] = DuelStatus.completed.rawValue
            
            try await cloudKit.savePublic(record)
            await fetchActiveDuels()
            await fetchDuelHistory()
            
        } catch {
            print("DuelService: Failed to finalize duel — \(error)")
        }
    }
    
    // MARK: - Fetch
    
    /// Fetch active duels
    func fetchActiveDuels() async {
        guard let myID = myPlayerID else { return }
        isLoading = true
        
        let statusRaw = DuelStatus.active.rawValue
        let predA = NSPredicate(format: "%K == %@ AND %K == %@", Duel.Keys.challengerID, myID, Duel.Keys.status, statusRaw)
        let predB = NSPredicate(format: "%K == %@ AND %K == %@", Duel.Keys.opponentID, myID, Duel.Keys.status, statusRaw)
        
        do {
            let queryA = CKQuery(recordType: CloudKitService.RecordType.duel, predicate: predA)
            let queryB = CKQuery(recordType: CloudKitService.RecordType.duel, predicate: predB)
            
            let recordsA = try await cloudKit.queryPublic(queryA, limit: 20)
            let recordsB = try await cloudKit.queryPublic(queryB, limit: 20)
            
            activeDuels = (recordsA + recordsB).map { Duel.from(record: $0) }
        } catch {
            print("DuelService: Failed to fetch active duels — \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch pending incoming challenges
    func fetchPendingChallenges() async {
        guard let myID = myPlayerID else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            Duel.Keys.opponentID, myID,
            Duel.Keys.status, DuelStatus.pending.rawValue
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.duel, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 20)
            pendingChallenges = records.map { Duel.from(record: $0) }
        } catch {
            print("DuelService: Failed to fetch challenges — \(error)")
        }
    }
    
    /// Fetch duel history
    func fetchDuelHistory() async {
        guard let myID = myPlayerID else { return }
        
        let completedRaw = DuelStatus.completed.rawValue
        let predA = NSPredicate(format: "%K == %@ AND %K == %@", Duel.Keys.challengerID, myID, Duel.Keys.status, completedRaw)
        let predB = NSPredicate(format: "%K == %@ AND %K == %@", Duel.Keys.opponentID, myID, Duel.Keys.status, completedRaw)
        
        do {
            let queryA = CKQuery(recordType: CloudKitService.RecordType.duel, predicate: predA)
            let queryB = CKQuery(recordType: CloudKitService.RecordType.duel, predicate: predB)
            
            let recordsA = try await cloudKit.queryPublic(queryA, limit: 25)
            let recordsB = try await cloudKit.queryPublic(queryB, limit: 25)
            
            let allDuels = (recordsA + recordsB).map { Duel.from(record: $0) }
            duelHistory = allDuels.sorted { $0.endDate > $1.endDate }
            
            // Calculate W/L
            wins = allDuels.filter { $0.winnerID == myID }.count
            losses = allDuels.filter { $0.winnerID != "tie" && $0.winnerID != myID && !$0.winnerID.isEmpty }.count
        } catch {
            print("DuelService: Failed to fetch history — \(error)")
        }
    }
    
    /// Refresh all duel data
    func refreshAll() async {
        await fetchActiveDuels()
        await fetchPendingChallenges()
        await fetchDuelHistory()
        await checkForCompletedDuels()
    }
}

// MARK: - Duel Model

/// Represents a 1v1 duel — CKRecord wrapper
struct Duel: Identifiable {
    let id: String
    let challengerID: String
    let opponentID: String
    let duelType: DuelType
    let status: DuelStatus
    let stakes: Int
    let startDate: Date
    let endDate: Date
    let challengerScore: Int
    let opponentScore: Int
    let winnerID: String
    
    enum Keys {
        static let challengerID = "challengerID"
        static let opponentID = "opponentID"
        static let duelType = "duelType"
        static let status = "duelStatus"
        static let stakes = "stakes"
        static let startDate = "startDate"
        static let endDate = "endDate"
        static let challengerScore = "challengerScore"
        static let opponentScore = "opponentScore"
        static let winnerID = "winnerID"
    }
    
    static func from(record: CKRecord) -> Duel {
        Duel(
            id: record.recordID.recordName,
            challengerID: record[Keys.challengerID] as? String ?? "",
            opponentID: record[Keys.opponentID] as? String ?? "",
            duelType: DuelType(rawValue: record[Keys.duelType] as? String ?? "") ?? .xpSprint,
            status: DuelStatus(rawValue: record[Keys.status] as? String ?? "") ?? .pending,
            stakes: record[Keys.stakes] as? Int ?? 0,
            startDate: record[Keys.startDate] as? Date ?? Date(),
            endDate: record[Keys.endDate] as? Date ?? Date(),
            challengerScore: record[Keys.challengerScore] as? Int ?? 0,
            opponentScore: record[Keys.opponentScore] as? Int ?? 0,
            winnerID: record[Keys.winnerID] as? String ?? ""
        )
    }
    
    /// Whether this duel has expired
    var isExpired: Bool { Date() > endDate }
    
    /// Time remaining formatted
    var timeRemaining: String {
        guard !isExpired else { return "Ended" }
        let interval = endDate.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h" }
        return "\(hours)h"
    }
    
    /// Check if a given player is the winner
    func isWinner(_ playerID: String) -> Bool {
        winnerID == playerID
    }
}

/// Duel types
enum DuelType: String, CaseIterable, Codable, Identifiable {
    case statCompare
    case questRace
    case stepBattle
    case streakChallenge
    case xpSprint
    case workoutWarrior
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .statCompare: return "Stat Compare"
        case .questRace: return "Quest Race"
        case .stepBattle: return "Step Battle"
        case .streakChallenge: return "Streak Challenge"
        case .xpSprint: return "XP Sprint"
        case .workoutWarrior: return "Workout Warrior"
        }
    }
    
    var description: String {
        switch self {
        case .statCompare: return "Compare weekly stat XP gain"
        case .questRace: return "Complete more quests in a week"
        case .stepBattle: return "Walk more steps in the time limit"
        case .streakChallenge: return "Maintain the longest streak"
        case .xpSprint: return "Earn the most XP in a week"
        case .workoutWarrior: return "Log more workout minutes"
        }
    }
    
    var icon: String {
        switch self {
        case .statCompare: return "chart.bar.fill"
        case .questRace: return "flag.checkered"
        case .stepBattle: return "figure.walk"
        case .streakChallenge: return "flame.fill"
        case .xpSprint: return "bolt.fill"
        case .workoutWarrior: return "dumbbell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .statCompare: return AppColors.primaryBlue
        case .questRace: return AppColors.success
        case .stepBattle: return AppColors.vitalityColor
        case .streakChallenge: return .orange
        case .xpSprint: return AppColors.accentPurple
        case .workoutWarrior: return AppColors.strengthColor
        }
    }
}

/// Duel status
enum DuelStatus: String, Codable {
    case pending
    case active
    case completed
    case declined
}
