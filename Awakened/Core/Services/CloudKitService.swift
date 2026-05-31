import Foundation
import CloudKit
import Combine

/// Singleton managing all CloudKit operations for the social layer
@MainActor
class CloudKitService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CloudKitService()
    
    // MARK: - Properties
    
    /// CloudKit container
    let container: CKContainer
    
    /// Public database for social data
    let publicDB: CKDatabase
    
    /// Private database for user-specific data
    let privateDB: CKDatabase
    
    /// Current user's CloudKit record ID
    @Published var currentUserRecordID: CKRecord.ID?
    
    /// Whether CloudKit is available
    @Published var isAvailable: Bool = false
    
    /// Account status
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    /// Last error encountered
    @Published var lastError: String?
    
    // MARK: - Record Types
    
    enum RecordType {
        static let cloudProfile = "CloudProfile"
        static let friendRequest = "FriendRequest"
        static let friendship = "Friendship"
        static let feedEvent = "FeedEvent"
        static let feedReaction = "FeedReaction"
        static let guild = "Guild"
        static let guildMember = "GuildMember"
        static let guildQuest = "GuildQuest"
        static let guildQuestContribution = "GuildQuestContribution"
        static let duel = "Duel"
        static let season = "Season"
        static let seasonEntry = "SeasonEntry"
    }
    
    // MARK: - Initialization
    
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    // MARK: - Setup
    
    /// Check CloudKit availability and fetch user record ID
    func setup() async {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            isAvailable = status == .available
            
            if isAvailable {
                let userID = try await container.userRecordID()
                currentUserRecordID = userID
            }
        } catch {
            lastError = "CloudKit setup failed: \(error.localizedDescription)"
            isAvailable = false
        }
    }
    
    // MARK: - Generic CRUD
    
    /// Save a record to the public database
    /// - Parameter record: CKRecord to save
    /// - Returns: Saved record
    @discardableResult
    func savePublic(_ record: CKRecord) async throws -> CKRecord {
        try await publicDB.save(record)
    }
    
    /// Fetch a single record by ID from the public database
    /// - Parameter recordID: Record ID to fetch
    /// - Returns: The fetched record
    func fetchPublic(recordID: CKRecord.ID) async throws -> CKRecord {
        try await publicDB.record(for: recordID)
    }
    
    /// Delete a record from the public database
    /// - Parameter recordID: Record ID to delete
    func deletePublic(recordID: CKRecord.ID) async throws {
        try await publicDB.deleteRecord(withID: recordID)
    }
    
    /// Query the public database
    /// - Parameters:
    ///   - query: CKQuery to execute
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching records
    func queryPublic(_ query: CKQuery, limit: Int = 50) async throws -> [CKRecord] {
        var results: [CKRecord] = []
        
        let (matchResults, _) = try await publicDB.records(
            matching: query,
            resultsLimit: limit
        )
        
        for (_, result) in matchResults {
            if let record = try? result.get() {
                results.append(record)
            }
        }
        
        return results
    }
    
    // MARK: - Subscriptions
    
    /// Subscribe to changes for a record type in the public database
    /// - Parameters:
    ///   - recordType: Record type to watch
    ///   - predicate: Filter predicate
    ///   - subscriptionID: Unique ID for this subscription
    func subscribeToChanges(
        recordType: String,
        predicate: NSPredicate,
        subscriptionID: String
    ) async throws {
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        info.shouldBadge = true
        subscription.notificationInfo = info
        
        try await publicDB.save(subscription)
    }
    
    /// Remove a subscription by ID
    /// - Parameter subscriptionID: Subscription to remove
    func removeSubscription(_ subscriptionID: String) async throws {
        try await publicDB.deleteSubscription(withID: subscriptionID)
    }
    
    // MARK: - User Discovery
    
    /// Discover the current user's CloudKit record name (stable identifier)
    /// - Returns: User record name string
    func currentUserRecordName() async throws -> String {
        guard let recordID = currentUserRecordID else {
            await setup()
            guard let recordID = currentUserRecordID else {
                throw CloudKitError.notAuthenticated
            }
            return recordID.recordName
        }
        return recordID.recordName
    }
    
    // MARK: - Batch Operations
    
    /// Save multiple records in a batch
    /// - Parameter records: Records to save
    /// - Returns: Successfully saved records
    func batchSavePublic(_ records: [CKRecord]) async throws -> [CKRecord] {
        let operation = CKModifyRecordsOperation(
            recordsToSave: records,
            recordIDsToDelete: nil
        )
        operation.savePolicy = .changedKeys
        
        return try await withCheckedThrowingContinuation { continuation in
            var savedRecords: [CKRecord] = []
            
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: savedRecords)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            operation.perRecordSaveBlock = { _, result in
                if let record = try? result.get() {
                    savedRecords.append(record)
                }
            }
            
            publicDB.add(operation)
        }
    }
}

// MARK: - Errors

/// CloudKit-specific errors
enum CloudKitError: LocalizedError {
    case notAuthenticated
    case notAvailable
    case recordNotFound
    case permissionDenied
    case quotaExceeded
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not signed in to iCloud"
        case .notAvailable: return "CloudKit is not available"
        case .recordNotFound: return "Record not found"
        case .permissionDenied: return "Permission denied"
        case .quotaExceeded: return "Storage quota exceeded"
        case .networkError: return "Network error — check your connection"
        case .unknown(let msg): return msg
        }
    }
}
