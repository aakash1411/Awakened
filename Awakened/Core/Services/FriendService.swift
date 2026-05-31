import Foundation
import CloudKit
import Combine

/// Manages friend requests, friendships, and friend discovery via CloudKit
@MainActor
class FriendService: ObservableObject {
    
    // MARK: - Published State
    
    /// Current user's friends (profiles)
    @Published var friends: [CloudProfile] = []
    
    /// Pending incoming friend requests
    @Published var incomingRequests: [FriendRequestRecord] = []
    
    /// Pending outgoing friend requests
    @Published var outgoingRequests: [FriendRequestRecord] = []
    
    /// Whether data is loading
    @Published var isLoading: Bool = false
    
    /// Last error
    @Published var lastError: String?
    
    // MARK: - Properties
    
    private let cloudKit = CloudKitService.shared
    
    /// Current player's UUID string (used as CloudKit record key)
    private var myPlayerID: String? {
        UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    // MARK: - Send Request
    
    /// Send a friend request to another player
    /// - Parameter targetPlayerID: UUID string of the target player
    func sendFriendRequest(to targetPlayerID: String) async throws {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        guard myID != targetPlayerID else { return }
        
        // Check if already friends or request pending
        if friends.contains(where: { $0.id == targetPlayerID }) { return }
        if outgoingRequests.contains(where: { $0.receiverID == targetPlayerID }) { return }
        
        let record = CKRecord(recordType: CloudKitService.RecordType.friendRequest)
        record[FriendRequestRecord.Keys.senderID] = myID
        record[FriendRequestRecord.Keys.receiverID] = targetPlayerID
        record[FriendRequestRecord.Keys.status] = FriendRequestStatus.pending.rawValue
        record[FriendRequestRecord.Keys.sentAt] = Date()
        
        try await cloudKit.savePublic(record)
        await fetchOutgoingRequests()
    }
    
    // MARK: - Respond to Request
    
    /// Accept or decline a friend request
    /// - Parameters:
    ///   - request: The friend request record
    ///   - accept: Whether to accept
    func respondToRequest(_ request: FriendRequestRecord, accept: Bool) async throws {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        guard request.receiverID == myID else { return }
        
        // Update request status
        let recordID = CKRecord.ID(recordName: request.id)
        let existingRecord = try await cloudKit.fetchPublic(recordID: recordID)
        existingRecord[FriendRequestRecord.Keys.status] = (accept ? FriendRequestStatus.accepted : FriendRequestStatus.declined).rawValue
        existingRecord[FriendRequestRecord.Keys.respondedAt] = Date()
        try await cloudKit.savePublic(existingRecord)
        
        // If accepted, create friendship records (bidirectional)
        if accept {
            try await createFriendship(playerA: request.senderID, playerB: myID)
        }
        
        // Refresh lists
        await fetchIncomingRequests()
        await fetchFriends()
    }
    
    // MARK: - Remove Friend
    
    /// Remove a friend
    /// - Parameter friendID: UUID string of the friend to remove
    func removeFriend(_ friendID: String) async throws {
        guard let myID = myPlayerID else { throw CloudKitError.notAuthenticated }
        
        // Find and delete friendship records (both directions)
        let predicate = NSPredicate(
            format: "(%K == %@ AND %K == %@) OR (%K == %@ AND %K == %@)",
            FriendshipRecord.Keys.playerAID, myID,
            FriendshipRecord.Keys.playerBID, friendID,
            FriendshipRecord.Keys.playerAID, friendID,
            FriendshipRecord.Keys.playerBID, myID
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.friendship, predicate: predicate)
        let records = try await cloudKit.queryPublic(query)
        
        for record in records {
            try await cloudKit.deletePublic(recordID: record.recordID)
        }
        
        friends.removeAll { $0.id == friendID }
    }
    
    // MARK: - Fetch Friends
    
    /// Fetch all friends for the current player
    func fetchFriends() async {
        guard let myID = myPlayerID else { return }
        isLoading = true
        
        do {
            // Query friendships where I am playerA or playerB
            let predicateA = NSPredicate(format: "%K == %@", FriendshipRecord.Keys.playerAID, myID)
            let queryA = CKQuery(recordType: CloudKitService.RecordType.friendship, predicate: predicateA)
            let recordsA = try await cloudKit.queryPublic(queryA)
            
            let predicateB = NSPredicate(format: "%K == %@", FriendshipRecord.Keys.playerBID, myID)
            let queryB = CKQuery(recordType: CloudKitService.RecordType.friendship, predicate: predicateB)
            let recordsB = try await cloudKit.queryPublic(queryB)
            
            // Collect friend IDs
            var friendIDs: Set<String> = []
            for record in recordsA {
                if let friendID = record[FriendshipRecord.Keys.playerBID] as? String {
                    friendIDs.insert(friendID)
                }
            }
            for record in recordsB {
                if let friendID = record[FriendshipRecord.Keys.playerAID] as? String {
                    friendIDs.insert(friendID)
                }
            }
            
            // Fetch profiles for each friend
            var profiles: [CloudProfile] = []
            for friendID in friendIDs {
                let profileRecordID = CKRecord.ID(recordName: friendID)
                if let record = try? await cloudKit.fetchPublic(recordID: profileRecordID) {
                    profiles.append(CloudProfile.from(record: record))
                }
            }
            
            friends = profiles.sorted { $0.level > $1.level }
            
        } catch {
            lastError = "Failed to fetch friends: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch incoming friend requests
    func fetchIncomingRequests() async {
        guard let myID = myPlayerID else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            FriendRequestRecord.Keys.receiverID, myID,
            FriendRequestRecord.Keys.status, FriendRequestStatus.pending.rawValue
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.friendRequest, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: FriendRequestRecord.Keys.sentAt, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(query)
            incomingRequests = records.map { FriendRequestRecord.from(record: $0) }
        } catch {
            lastError = "Failed to fetch requests: \(error.localizedDescription)"
        }
    }
    
    /// Fetch outgoing friend requests
    func fetchOutgoingRequests() async {
        guard let myID = myPlayerID else { return }
        
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            FriendRequestRecord.Keys.senderID, myID,
            FriendRequestRecord.Keys.status, FriendRequestStatus.pending.rawValue
        )
        let query = CKQuery(recordType: CloudKitService.RecordType.friendRequest, predicate: predicate)
        
        do {
            let records = try await cloudKit.queryPublic(query)
            outgoingRequests = records.map { FriendRequestRecord.from(record: $0) }
        } catch {
            lastError = "Failed to fetch outgoing requests: \(error.localizedDescription)"
        }
    }
    
    /// Refresh all friend data
    func refreshAll() async {
        await fetchFriends()
        await fetchIncomingRequests()
        await fetchOutgoingRequests()
    }
    
    // MARK: - Search
    
    /// Search for players by display name
    /// - Parameter query: Search string
    /// - Returns: Matching profiles (excluding self and current friends)
    func searchPlayers(query: String) async -> [CloudProfile] {
        guard let myID = myPlayerID else { return [] }
        
        let predicate = NSPredicate(
            format: "%K BEGINSWITH[cd] %@ AND %K == %@ AND %K != %@",
            CloudProfile.Keys.displayName, query,
            CloudProfile.Keys.isPublic, NSNumber(value: true),
            CloudProfile.Keys.ownerRecordName, myID
        )
        let ckQuery = CKQuery(recordType: CloudKitService.RecordType.cloudProfile, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: CloudProfile.Keys.level, ascending: false)]
        
        do {
            let records = try await cloudKit.queryPublic(ckQuery, limit: 20)
            let profiles = records.map { CloudProfile.from(record: $0) }
            let friendIDs = Set(friends.map(\.id))
            return profiles.filter { !friendIDs.contains($0.id) }
        } catch {
            return []
        }
    }
    
    /// Get friend count
    var friendCount: Int { friends.count }
    
    /// Get pending request count
    var pendingRequestCount: Int { incomingRequests.count }
    
    // MARK: - Private Helpers
    
    /// Create a bidirectional friendship record
    private func createFriendship(playerA: String, playerB: String) async throws {
        let record = CKRecord(recordType: CloudKitService.RecordType.friendship)
        record[FriendshipRecord.Keys.playerAID] = playerA
        record[FriendshipRecord.Keys.playerBID] = playerB
        record[FriendshipRecord.Keys.createdAt] = Date()
        try await cloudKit.savePublic(record)
    }
}

// MARK: - Friend Request Record

/// CKRecord wrapper for friend requests
struct FriendRequestRecord: Identifiable {
    let id: String
    let senderID: String
    let receiverID: String
    let status: FriendRequestStatus
    let sentAt: Date
    let respondedAt: Date?
    
    /// Sender's cached profile (loaded separately)
    var senderProfile: CloudProfile?
    
    enum Keys {
        static let senderID = "senderID"
        static let receiverID = "receiverID"
        static let status = "status"
        static let sentAt = "sentAt"
        static let respondedAt = "respondedAt"
    }
    
    static func from(record: CKRecord) -> FriendRequestRecord {
        FriendRequestRecord(
            id: record.recordID.recordName,
            senderID: record[Keys.senderID] as? String ?? "",
            receiverID: record[Keys.receiverID] as? String ?? "",
            status: FriendRequestStatus(rawValue: record[Keys.status] as? String ?? "") ?? .pending,
            sentAt: record[Keys.sentAt] as? Date ?? Date(),
            respondedAt: record[Keys.respondedAt] as? Date
        )
    }
}

/// Friend request status
enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}

// MARK: - Friendship Record

/// CKRecord wrapper for friendships
struct FriendshipRecord {
    enum Keys {
        static let playerAID = "playerAID"
        static let playerBID = "playerBID"
        static let createdAt = "createdAt"
    }
}
