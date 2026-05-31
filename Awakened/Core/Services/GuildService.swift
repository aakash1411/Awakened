import Foundation
import CloudKit
import Combine
import SwiftUI

/// Manages guild CRUD, membership, invites, and guild XP via CloudKit
@MainActor
class GuildService: ObservableObject {
    
    // MARK: - Published State
    
    /// Current player's guild (if any)
    @Published var myGuild: Guild?
    
    /// Members of the current guild
    @Published var members: [GuildMember] = []
    
    /// Whether data is loading
    @Published var isLoading: Bool = false
    
    /// Last error
    @Published var lastError: String?
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Create Guild
    
    /// Create a new guild
    /// - Parameters:
    ///   - name: Guild name
    ///   - description: Guild description
    ///   - emblem: Emblem emoji
    ///   - bannerColorHex: Banner color hex
    ///   - isPublic: Whether discoverable
    ///   - minRank: Minimum rank to join
    /// - Returns: Created guild
    @discardableResult
    func createGuild(
        name: String,
        description: String = "",
        emblem: String = "⚔️",
        bannerColorHex: String = "007AFF",
        isPublic: Bool = true,
        minRank: PlayerRank = .e
    ) async throws -> Guild {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        
        // Ensure player isn't already in a guild
        if myGuild != nil { throw GuildError.alreadyInGuild }
        
        let guildID = UUID().uuidString
        let guild = Guild(
            id: guildID,
            name: name,
            description: description,
            emblem: emblem,
            bannerColorHex: bannerColorHex,
            leaderID: myID,
            guildLevel: 1,
            totalGuildXP: 0,
            memberCount: 1,
            isPublic: isPublic,
            maxMembers: 30,
            minRankToJoinRaw: minRank.rawValue,
            createdAt: Date()
        )
        
        // Save guild record
        let record = guild.toCKRecord()
        try await cloudKit.savePublic(record)
        
        // Add creator as leader member
        try await addMember(guildID: guildID, playerID: myID, role: .leader)
        
        myGuild = guild
        return guild
    }
    
    // MARK: - Join / Leave
    
    /// Join a guild (direct join for public guilds meeting rank requirement)
    func joinGuild(_ guild: Guild, playerRank: PlayerRank) async throws {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        guard myGuild == nil else { throw GuildError.alreadyInGuild }
        guard guild.hasRoom else { throw GuildError.guildFull }
        guard playerRank >= guild.minRankToJoin else { throw GuildError.rankTooLow }
        
        // Add as member
        try await addMember(guildID: guild.id, playerID: myID, role: .member)
        
        // Update member count
        try await updateMemberCount(guildID: guild.id, delta: 1)
        
        myGuild = guild
        await fetchMembers()
    }
    
    /// Leave current guild
    func leaveGuild() async throws {
        guard let myID = myPlayerID, let guild = myGuild else { return }
        
        // Leaders can't leave (must transfer or disband)
        if guild.leaderID == myID { throw GuildError.leaderCannotLeave }
        
        // Remove member record
        try await removeMemberRecord(guildID: guild.id, playerID: myID)
        
        // Update member count
        try await updateMemberCount(guildID: guild.id, delta: -1)
        
        myGuild = nil
        members = []
    }
    
    /// Disband the guild (leader only)
    func disbandGuild() async throws {
        guard let myID = myPlayerID, let guild = myGuild else { return }
        guard guild.leaderID == myID else { throw GuildError.notAuthorized }
        
        // Delete all member records
        let predicate = NSPredicate(format: "%K == %@", GuildMember.Keys.guildID, guild.id)
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        let records = try await cloudKit.queryPublic(query, limit: 50)
        for record in records {
            try await cloudKit.deletePublic(recordID: record.recordID)
        }
        
        // Delete guild record
        let guildRecordID = CKRecord.ID(recordName: guild.id)
        try await cloudKit.deletePublic(recordID: guildRecordID)
        
        myGuild = nil
        members = []
    }
    
    // MARK: - Membership Management
    
    /// Kick a member (officer+ only)
    func kickMember(_ memberPlayerID: String) async throws {
        guard let guild = myGuild else { return }
        guard guild.leaderID == myPlayerID || isOfficer() else { throw GuildError.notAuthorized }
        
        try await removeMemberRecord(guildID: guild.id, playerID: memberPlayerID)
        try await updateMemberCount(guildID: guild.id, delta: -1)
        members.removeAll { $0.playerID == memberPlayerID }
    }
    
    /// Promote a member to officer
    func promoteToOfficer(_ memberPlayerID: String) async throws {
        guard let guild = myGuild else { return }
        guard guild.leaderID == myPlayerID else { throw GuildError.notAuthorized }
        
        try await updateMemberRole(guildID: guild.id, playerID: memberPlayerID, newRole: .officer)
        if let idx = members.firstIndex(where: { $0.playerID == memberPlayerID }) {
            members[idx].role = .officer
        }
    }
    
    /// Demote an officer to member
    func demoteToMember(_ memberPlayerID: String) async throws {
        guard let guild = myGuild else { return }
        guard guild.leaderID == myPlayerID else { throw GuildError.notAuthorized }
        
        try await updateMemberRole(guildID: guild.id, playerID: memberPlayerID, newRole: .member)
        if let idx = members.firstIndex(where: { $0.playerID == memberPlayerID }) {
            members[idx].role = .member
        }
    }
    
    /// Transfer leadership to another member
    func transferLeadership(to newLeaderID: String) async throws {
        guard let myID = myPlayerID, let guild = myGuild else { return }
        guard guild.leaderID == myID else { throw GuildError.notAuthorized }
        
        // Update guild leader
        let guildRecordID = CKRecord.ID(recordName: guild.id)
        let guildRecord = try await cloudKit.fetchPublic(recordID: guildRecordID)
        guildRecord[Guild.Keys.leaderID] = newLeaderID
        try await cloudKit.savePublic(guildRecord)
        
        // Update roles
        try await updateMemberRole(guildID: guild.id, playerID: newLeaderID, newRole: .leader)
        try await updateMemberRole(guildID: guild.id, playerID: myID, newRole: .officer)
        
        myGuild?.leaderID = newLeaderID
        await fetchMembers()
    }
    
    // MARK: - Guild XP
    
    /// Contribute XP to the guild (10% of member XP flows to guild)
    /// - Parameter xpEarned: XP the player earned
    func contributeXP(_ xpEarned: Int) async {
        guard let guild = myGuild, let myID = myPlayerID else { return }
        let contribution = max(1, xpEarned / 10)
        
        do {
            // Update guild total XP
            let guildRecordID = CKRecord.ID(recordName: guild.id)
            let guildRecord = try await cloudKit.fetchPublic(recordID: guildRecordID)
            let currentXP = guildRecord[Guild.Keys.totalGuildXP] as? Int ?? 0
            let newXP = currentXP + contribution
            guildRecord[Guild.Keys.totalGuildXP] = newXP
            
            // Check for level up
            let currentLevel = guildRecord[Guild.Keys.guildLevel] as? Int ?? 1
            let nextLevelXP = currentLevel * 5000
            if newXP >= nextLevelXP {
                guildRecord[Guild.Keys.guildLevel] = currentLevel + 1
                // Increase max members on level up
                let currentMax = guildRecord[Guild.Keys.maxMembers] as? Int ?? 30
                guildRecord[Guild.Keys.maxMembers] = min(currentMax + 2, 100)
            }
            
            try await cloudKit.savePublic(guildRecord)
            myGuild?.totalGuildXP = newXP
            
            // Update member's weekly contribution
            await updateMemberContribution(guildID: guild.id, playerID: myID, amount: contribution)
            
        } catch {
            print("GuildService: Failed to contribute XP — \(error)")
        }
    }
    
    // MARK: - Fetch
    
    /// Fetch the current player's guild
    func fetchMyGuild() async {
        guard let myID = myPlayerID else { return }
        isLoading = true
        
        // Find my membership record
        let predicate = NSPredicate(format: "%K == %@", GuildMember.Keys.playerID, myID)
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let memberRecord = records.first,
               let guildID = memberRecord[GuildMember.Keys.guildID] as? String {
                let guildRecordID = CKRecord.ID(recordName: guildID)
                let guildRecord = try await cloudKit.fetchPublic(recordID: guildRecordID)
                myGuild = Guild.from(record: guildRecord)
                await fetchMembers()
            } else {
                myGuild = nil
            }
        } catch {
            lastError = "Failed to fetch guild: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Fetch members of the current guild
    func fetchMembers() async {
        guard let guild = myGuild else { return }
        
        let predicate = NSPredicate(format: "%K == %@", GuildMember.Keys.guildID, guild.id)
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query, limit: 50)
            var loadedMembers = records.map { GuildMember.from(record: $0) }
            
            // Load profiles for each member
            for i in loadedMembers.indices {
                let profileID = CKRecord.ID(recordName: loadedMembers[i].playerID)
                if let profileRecord = try? await cloudKit.fetchPublic(recordID: profileID) {
                    loadedMembers[i].profile = CloudProfile.from(record: profileRecord)
                }
            }
            
            members = loadedMembers.sorted { $0.role < $1.role }
        } catch {
            print("GuildService: Failed to fetch members — \(error)")
        }
    }
    
    /// Search for public guilds
    func searchGuilds(query: String) async -> [Guild] {
        let predicate: NSPredicate
        if query.isEmpty {
            predicate = NSPredicate(format: "%K == %@", Guild.Keys.isPublic, NSNumber(value: true))
        } else {
            predicate = NSPredicate(
                format: "%K BEGINSWITH[cd] %@ AND %K == %@",
                Guild.Keys.name, query,
                Guild.Keys.isPublic, NSNumber(value: true)
            )
        }
        let ckQuery = CKQuery(recordType: CloudKitService.RecordType.guild, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: Guild.Keys.guildLevel, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(ckQuery, limit: 25)
            return records.map { Guild.from(record: $0) }
        } catch {
            return []
        }
    }
    
    // MARK: - Helpers
    
    private func isOfficer() -> Bool {
        guard let myID = myPlayerID else { return false }
        return members.first(where: { $0.playerID == myID })?.role == .officer
    }
    
    private func addMember(guildID: String, playerID: String, role: GuildRole) async throws {
        let record = CKRecord(recordType: CloudKitService.RecordType.guildMember)
        record[GuildMember.Keys.guildID] = guildID
        record[GuildMember.Keys.playerID] = playerID
        record[GuildMember.Keys.role] = role.rawValue
        record[GuildMember.Keys.joinedAt] = Date()
        record[GuildMember.Keys.weeklyXPContribution] = 0
        record[GuildMember.Keys.totalXPContribution] = 0
        try await cloudKit.savePublic(record)
    }
    
    private func removeMemberRecord(guildID: String, playerID: String) async throws {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildMember.Keys.guildID, guildID,
            GuildMember.Keys.playerID, playerID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        let records = try await cloudKit.queryPublic(query, limit: 1)
        if let record = records.first {
            try await cloudKit.deletePublic(recordID: record.recordID)
        }
    }
    
    private func updateMemberRole(guildID: String, playerID: String, newRole: GuildRole) async throws {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildMember.Keys.guildID, guildID,
            GuildMember.Keys.playerID, playerID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        let records = try await cloudKit.queryPublic(query, limit: 1)
        if let record = records.first {
            record[GuildMember.Keys.role] = newRole.rawValue
            try await cloudKit.savePublic(record)
        }
    }
    
    private func updateMemberCount(guildID: String, delta: Int) async throws {
        let guildRecordID = CKRecord.ID(recordName: guildID)
        let record = try await cloudKit.fetchPublic(recordID: guildRecordID)
        let current = record[Guild.Keys.memberCount] as? Int ?? 0
        record[Guild.Keys.memberCount] = max(0, current + delta)
        try await cloudKit.savePublic(record)
    }
    
    private func updateMemberContribution(guildID: String, playerID: String, amount: Int) async {
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            GuildMember.Keys.guildID, guildID,
            GuildMember.Keys.playerID, playerID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.guildMember, predicate: predicate)
        do {
            let records = try await cloudKit.queryPublic(query, limit: 1)
            if let record = records.first {
                let weekly = record[GuildMember.Keys.weeklyXPContribution] as? Int ?? 0
                let total = record[GuildMember.Keys.totalXPContribution] as? Int ?? 0
                record[GuildMember.Keys.weeklyXPContribution] = weekly + amount
                record[GuildMember.Keys.totalXPContribution] = total + amount
                try await cloudKit.savePublic(record)
            }
        } catch {
            print("GuildService: Failed to update contribution — \(error)")
        }
    }
}

// MARK: - Guild Errors

enum GuildError: LocalizedError {
    case alreadyInGuild
    case guildFull
    case rankTooLow
    case leaderCannotLeave
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .alreadyInGuild: return "You are already in a guild"
        case .guildFull: return "This guild is full"
        case .rankTooLow: return "Your rank is too low to join this guild"
        case .leaderCannotLeave: return "Transfer leadership or disband before leaving"
        case .notAuthorized: return "You don't have permission for this action"
        }
    }
}
