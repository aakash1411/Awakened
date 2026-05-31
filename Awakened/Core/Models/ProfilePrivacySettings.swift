import Foundation

/// Controls what data is visible on a player's public profile
struct ProfilePrivacySettings: Codable {
    
    /// Show player level and rank
    var showLevel: Bool = true
    
    /// Show individual stat levels
    var showStats: Bool = true
    
    /// Show current and longest streak
    var showStreak: Bool = true
    
    /// Show workout count and stats
    var showWorkouts: Bool = false
    
    /// Show unlocked achievements
    var showAchievements: Bool = true
    
    /// Show duel win/loss record
    var showDuelRecord: Bool = true
    
    /// Allow other users to send friend requests
    var allowFriendRequests: Bool = true
    
    /// Allow guild invitations
    var allowGuildInvites: Bool = true
    
    /// Allow duel challenges
    var allowDuelChallenges: Bool = true
    
    // MARK: - Persistence
    
    private static let storageKey = "profilePrivacySettings"
    
    /// Load settings from UserDefaults
    static func load() -> ProfilePrivacySettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(ProfilePrivacySettings.self, from: data) else {
            return ProfilePrivacySettings()
        }
        return settings
    }
    
    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
