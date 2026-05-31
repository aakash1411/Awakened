import Foundation
import CloudKit
import Combine

/// Manages ranked seasons — fetching current season, tracking progress, leaderboards
@MainActor
class SeasonService: ObservableObject {
    
    // MARK: - Published State
    
    /// Current active season
    @Published var currentSeason: Season?
    
    /// Current player's season entry
    @Published var myEntry: SeasonEntry?
    
    /// Season leaderboard entries (top players)
    @Published var leaderboard: [SeasonEntry] = []
    
    /// Whether loading
    @Published var isLoading: Bool = false
    
    /// Earned titles from past seasons
    @Published var earnedTitles: [String] = []
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Fetch Current Season
    
    /// Fetch the currently active season
    func fetchCurrentSeason() async {
        isLoading = true
        
        let now = Date()
        let predicate = NSPredicate(
            format: "%K <= %@ AND %K >= %@",
            Season.Keys.startDate, now as NSDate,
            Season.Keys.endDate, now as NSDate
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.season, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                currentSeason = Season.from(record: record)
                await fetchMyEntry()
            }
        } catch {
            print("SeasonService: Failed to fetch current season — \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Player Entry
    
    /// Fetch or create the current player's season entry
    func fetchMyEntry() async {
        guard let myID = myPlayerID, let season = currentSeason else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            SeasonEntry.Keys.seasonID, season.id,
            SeasonEntry.Keys.playerID, myID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.seasonEntry, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                myEntry = SeasonEntry.from(record: record)
            } else {
                // Auto-create entry for current season
                myEntry = try await createEntry(seasonID: season.id, playerID: myID)
            }
        } catch {
            print("SeasonService: Failed to fetch my entry — \(error)")
        }
    }
    
    /// Create a new season entry
    private func createEntry(seasonID: String, playerID: String) async throws -> SeasonEntry {
        let record = CKRecord(recordType: CloudKitService.RecordType.seasonEntry)
        record[SeasonEntry.Keys.seasonID] = seasonID
        record[SeasonEntry.Keys.playerID] = playerID
        record[SeasonEntry.Keys.seasonXP] = 0
        record[SeasonEntry.Keys.seasonTier] = SeasonTier.unranked.rawValue
        record[SeasonEntry.Keys.questsCompleted] = 0
        record[SeasonEntry.Keys.duelsWon] = 0
        record[SeasonEntry.Keys.peakLevel] = 1
        try await cloudKit.savePublic(record)
        return SeasonEntry.from(record: record)
    }
    
    // MARK: - Contribute XP
    
    /// Add XP to the player's current season entry
    /// - Parameter xpEarned: XP earned by the player
    func contributeSeasonXP(_ xpEarned: Int) async {
        guard let myID = myPlayerID, let season = currentSeason, season.isActive else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            SeasonEntry.Keys.seasonID, season.id,
            SeasonEntry.Keys.playerID, myID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.seasonEntry, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                let current = record[SeasonEntry.Keys.seasonXP] as? Int ?? 0
                let newXP = current + xpEarned
                record[SeasonEntry.Keys.seasonXP] = newXP
                
                // Update tier
                let newTier = SeasonTier.from(xp: newXP)
                record[SeasonEntry.Keys.seasonTier] = newTier.rawValue
                
                try await cloudKit.savePublic(record)
                
                myEntry?.seasonXP = newXP
                myEntry?.seasonTier = newTier
            }
        } catch {
            print("SeasonService: Failed to contribute XP — \(error)")
        }
    }
    
    /// Increment quests completed counter
    func recordQuestComplete() async {
        guard let myID = myPlayerID, let season = currentSeason, season.isActive else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            SeasonEntry.Keys.seasonID, season.id,
            SeasonEntry.Keys.playerID, myID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.seasonEntry, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                let current = record[SeasonEntry.Keys.questsCompleted] as? Int ?? 0
                record[SeasonEntry.Keys.questsCompleted] = current + 1
                try await cloudKit.savePublic(record)
                myEntry?.questsCompleted = (myEntry?.questsCompleted ?? 0) + 1
            }
        } catch {
            print("SeasonService: Failed to record quest complete — \(error)")
        }
    }
    
    /// Increment duels won counter
    func recordDuelWin() async {
        guard let myID = myPlayerID, let season = currentSeason, season.isActive else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            SeasonEntry.Keys.seasonID, season.id,
            SeasonEntry.Keys.playerID, myID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.seasonEntry, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                let current = record[SeasonEntry.Keys.duelsWon] as? Int ?? 0
                record[SeasonEntry.Keys.duelsWon] = current + 1
                try await cloudKit.savePublic(record)
                myEntry?.duelsWon = (myEntry?.duelsWon ?? 0) + 1
            }
        } catch {
            print("SeasonService: Failed to record duel win — \(error)")
        }
    }
    
    // MARK: - Leaderboard
    
    /// Fetch the season leaderboard
    func fetchLeaderboard() async {
        guard let season = currentSeason else { return }
        
        let predicate = NSPredicate(format: "%K == %@", SeasonEntry.Keys.seasonID, season.id)
        let query = CKQuery(recordType: CloudKitService.RecordType.seasonEntry, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: SeasonEntry.Keys.seasonXP, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 50)
            var entries = records.map { SeasonEntry.from(record: $0) }
            
            // Load profiles
            for i in entries.indices {
                let profileID = CKRecord.ID(recordName: entries[i].playerID)
                if let profileRecord = try? await cloudKit.fetchPublic(recordID: profileID) {
                    entries[i].profile = CloudProfile.from(record: profileRecord)
                }
            }
            
            leaderboard = entries
        } catch {
            print("SeasonService: Failed to fetch leaderboard — \(error)")
        }
    }
    
    // MARK: - Titles
    
    /// Load earned titles from past seasons (stored in UserDefaults)
    func loadEarnedTitles() {
        earnedTitles = UserDefaults.standard.stringArray(forKey: "earnedSeasonTitles") ?? []
    }
    
    /// Save a newly earned title
    func earnTitle(_ title: String) {
        guard !title.isEmpty, !earnedTitles.contains(title) else { return }
        earnedTitles.append(title)
        UserDefaults.standard.set(earnedTitles, forKey: "earnedSeasonTitles")
    }
}
