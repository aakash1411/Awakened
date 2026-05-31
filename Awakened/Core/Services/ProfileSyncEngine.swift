import Foundation
import CloudKit
import Combine

/// Watches local Player changes and syncs the public CloudProfile to CloudKit
@MainActor
class ProfileSyncEngine: ObservableObject {
    
    // MARK: - Properties
    
    /// The current user's cloud profile (cached locally)
    @Published var myProfile: CloudProfile?
    
    /// Whether a sync is in progress
    @Published var isSyncing: Bool = false
    
    /// Last sync error
    @Published var syncError: String?
    
    /// Cached CKRecord for updates (preserves server metadata)
    private var cachedRecord: CKRecord?
    
    /// Debounce timer for syncing
    private var syncTimer: Timer?
    
    /// Minimum interval between syncs (seconds)
    private let syncDebounceInterval: TimeInterval = 30
    
    /// Last successful sync date
    private var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastProfileSyncDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastProfileSyncDate") }
    }
    
    // MARK: - Profile Sync
    
    /// Push the current player's profile to CloudKit
    /// - Parameter player: The local Player model
    func syncProfile(for player: Player) async {
        guard CloudKitService.shared.isAvailable else {
            syncError = "CloudKit not available"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            var profile = CloudProfile.from(player: player)
            
            // Apply privacy settings
            let privacy = ProfilePrivacySettings.load()
            if !privacy.showStats {
                profile.strengthLevel = 0
                profile.agilityLevel = 0
                profile.vitalityLevel = 0
                profile.senseLevel = 0
                profile.intelligenceLevel = 0
            }
            if !privacy.showStreak {
                profile.currentStreak = 0
                profile.longestStreak = 0
            }
            if !privacy.showDuelRecord {
                profile.duelWins = 0
                profile.duelLosses = 0
            }
            if !privacy.showAchievements {
                profile.achievementsUnlocked = 0
            }
            
            // Try to fetch existing record first (to preserve metadata)
            let recordID = CKRecord.ID(recordName: player.id.uuidString)
            if cachedRecord == nil {
                cachedRecord = try? await CloudKitService.shared.fetchPublic(recordID: recordID)
            }
            
            let record = profile.toCKRecord(existingRecord: cachedRecord)
            let savedRecord = try await CloudKitService.shared.savePublic(record)
            
            cachedRecord = savedRecord
            myProfile = profile
            lastSyncDate = Date()
            
        } catch {
            syncError = "Profile sync failed: \(error.localizedDescription)"
            print("ProfileSyncEngine: \(syncError ?? "")")
        }
        
        isSyncing = false
    }
    
    /// Fetch a player's public profile by their UUID string
    /// - Parameter playerID: Player UUID string
    /// - Returns: CloudProfile if found
    func fetchProfile(playerID: String) async -> CloudProfile? {
        let recordID = CKRecord.ID(recordName: playerID)
        
        do {
            let record = try await CloudKitService.shared.fetchPublic(recordID: recordID)
            return CloudProfile.from(record: record)
        } catch {
            print("ProfileSyncEngine: Failed to fetch profile \(playerID) — \(error)")
            return nil
        }
    }
    
    /// Search for profiles by display name
    /// - Parameter query: Search string
    /// - Returns: Matching profiles
    func searchProfiles(query: String) async -> [CloudProfile] {
        let predicate = NSPredicate(
            format: "%K BEGINSWITH[cd] %@ AND %K == %@",
            CloudProfile.Keys.displayName, query,
            CloudProfile.Keys.isPublic, NSNumber(value: true)
        )
        let ckQuery = CKQuery(
            recordType: CloudKitService.RecordType.cloudProfile,
            predicate: predicate
        )
        ckQuery.sortDescriptors = [NSSortDescriptor(key: CloudProfile.Keys.level, ascending: false)]
        
        do {
            let records = try await CloudKitService.shared.queryPublic(ckQuery, limit: 25)
            return records.map { CloudProfile.from(record: $0) }
        } catch {
            print("ProfileSyncEngine: Search failed — \(error)")
            return []
        }
    }
    
    /// Schedule a debounced sync — call this after any player data change
    /// - Parameter player: The local Player model
    func scheduleSyncIfNeeded(for player: Player) {
        syncTimer?.invalidate()
        nonisolated(unsafe) let playerRef = player
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.syncProfile(for: playerRef)
            }
        }
    }
    
    /// Force an immediate sync (e.g., on app foreground)
    /// - Parameter player: The local Player model
    func forceSync(for player: Player) async {
        syncTimer?.invalidate()
        await syncProfile(for: player)
    }
    
    // MARK: - Profile Customization
    
    /// Update avatar emoji
    /// - Parameter emoji: New emoji string
    func updateAvatarEmoji(_ emoji: String) {
        UserDefaults.standard.set(emoji, forKey: "avatarEmoji")
    }
    
    /// Update bio tagline
    /// - Parameter bio: New bio string
    func updateBio(_ bio: String) {
        UserDefaults.standard.set(bio, forKey: "profileBio")
    }
    
    /// Update active title
    /// - Parameter title: New title string
    func updateActiveTitle(_ title: String) {
        UserDefaults.standard.set(title, forKey: "activeTitle")
    }
    
    /// Toggle profile public visibility
    /// - Parameter isPublic: Whether profile should be public
    func setProfilePublic(_ isPublic: Bool) {
        UserDefaults.standard.set(isPublic, forKey: "profileIsPublic")
    }
}
