import Foundation
import CloudKit
import Combine

/// Manages guild quests — create, progress, complete, and contribution tracking
@MainActor
class GuildQuestService: ObservableObject {
    
    // MARK: - Published State
    
    /// Active guild quests
    @Published var activeQuests: [GuildQuest] = []
    
    /// Completed guild quests (history)
    @Published var completedQuests: [GuildQuest] = []
    
    /// Contributions for the currently viewed quest
    @Published var currentContributions: [GuildQuestContribution] = []
    
    /// Whether loading
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Create Quest
    
    /// Create a new guild quest (leader/officer only)
    /// - Parameters:
    ///   - guildID: Guild ID
    ///   - type: Quest type
    ///   - memberCount: Current guild member count (for scaling)
    @discardableResult
    func createQuest(guildID: String, type: GuildQuestType, memberCount: Int) async throws -> GuildQuest {
        let quest = GuildQuest.weeklyTemplate(guildID: guildID, type: type, memberCount: memberCount)
        let record = quest.toCKRecord()
        try await cloudKit.savePublic(record)
        await fetchActiveQuests(guildID: guildID)
        return quest
    }
    
    // MARK: - Contribute Progress
    
    /// Add progress to a guild quest from the current player
    /// - Parameters:
    ///   - questID: Quest ID
    ///   - amount: Amount to contribute
    func contribute(questID: String, amount: Int) async {
        guard let myID = myPlayerID, amount > 0 else { return }
        
        do {
            // Update quest total
            let questRecordID = CKRecord.ID(recordName: questID)
            let questRecord = try await cloudKit.fetchPublic(recordID: questRecordID)
            
            let isAlreadyComplete = questRecord[GuildQuest.Keys.isCompleted] as? Bool ?? false
            guard !isAlreadyComplete else { return }
            
            let current = questRecord[GuildQuest.Keys.currentValue] as? Int ?? 0
            let target = questRecord[GuildQuest.Keys.targetValue] as? Int ?? 0
            let newValue = current + amount
            questRecord[GuildQuest.Keys.currentValue] = newValue
            
            // Check completion
            if newValue >= target {
                questRecord[GuildQuest.Keys.isCompleted] = true
                questRecord[GuildQuest.Keys.completedAt] = Date()
            }
            
            try await cloudKit.savePublic(questRecord)
            
            // Update or create contribution record
            await updateContribution(questID: questID, playerID: myID, amount: amount)
            
        } catch {
            print("GuildQuestService: Failed to contribute — \(error)")
        }
    }
    
    // MARK: - Fetch
    
    /// Fetch active guild quests
    func fetchActiveQuests(guildID: String) async {
        isLoading = true
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildQuest.Keys.guildID, guildID,
            GuildQuest.Keys.isCompleted, NSNumber(value: false)
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildQuest, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: GuildQuest.Keys.expiresAt, ascending: true)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 10)
            activeQuests = records.map { GuildQuest.from(record: $0) }
        } catch {
            print("GuildQuestService: Failed to fetch active quests — \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch completed guild quests
    func fetchCompletedQuests(guildID: String) async {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildQuest.Keys.guildID, guildID,
            GuildQuest.Keys.isCompleted, NSNumber(value: true)
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildQuest, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: GuildQuest.Keys.completedAt, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 20)
            completedQuests = records.map { GuildQuest.from(record: $0) }
        } catch {
            print("GuildQuestService: Failed to fetch completed quests — \(error)")
        }
    }
    
    /// Fetch contributions for a specific quest
    func fetchContributions(questID: String) async {
        let predicate = NSPredicate(format: "%K == %@", GuildQuestContribution.Keys.questID, questID)
        let query = CKQuery(recordType: CloudKitService.RecordType.guildQuestContribution, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: GuildQuestContribution.Keys.contributionValue, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 50)
            var contributions = records.map { GuildQuestContribution.from(record: $0) }
            
            // Load profiles
            for i in contributions.indices {
                let profileID = CKRecord.ID(recordName: contributions[i].playerID)
                if let profileRecord = try? await cloudKit.fetchPublic(recordID: profileID) {
                    contributions[i].profile = CloudProfile.from(record: profileRecord)
                }
            }
            
            currentContributions = contributions
        } catch {
            print("GuildQuestService: Failed to fetch contributions — \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Update or create a contribution record
    private func updateContribution(questID: String, playerID: String, amount: Int) async {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildQuestContribution.Keys.questID, questID,
            GuildQuestContribution.Keys.playerID, playerID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildQuestContribution, predicate: predicate)
        
        do {
            let existing = try await cloudKit.queryPublic(query, limit: 1)
            
            if let record = existing.first {
                // Update existing
                let current = record[GuildQuestContribution.Keys.contributionValue] as? Int ?? 0
                record[GuildQuestContribution.Keys.contributionValue] = current + amount
                record[GuildQuestContribution.Keys.updatedAt] = Date()
                try await cloudKit.savePublic(record)
            } else {
                // Create new
                let record = CKRecord(recordType: CloudKitService.RecordType.guildQuestContribution)
                record[GuildQuestContribution.Keys.questID] = questID
                record[GuildQuestContribution.Keys.playerID] = playerID
                record[GuildQuestContribution.Keys.contributionValue] = amount
                record[GuildQuestContribution.Keys.updatedAt] = Date()
                try await cloudKit.savePublic(record)
            }
        } catch {
            print("GuildQuestService: Failed to update contribution — \(error)")
        }
    }
}
