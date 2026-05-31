import SwiftUI
import SwiftData
import Combine

/// Global app state manager
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Published State
    
    /// Whether onboarding has been completed
    @Published var isOnboardingComplete: Bool
    
    /// Currently active player
    @Published var currentPlayer: Player?
    
    /// Currently selected tab
    @Published var selectedTab: AppTab = .home
    
    /// Whether to show level up animation
    @Published var showLevelUpAnimation: Bool = false
    
    /// Level up information for animation
    @Published var levelUpInfo: LevelUpInfo?
    
    /// Pending system notifications to display
    @Published var pendingNotifications: [SystemNotification] = []
    
    /// Whether app is loading data
    @Published var isLoading: Bool = false
    
    // MARK: - Social State
    
    /// Profile sync engine for CloudKit
    @Published var profileSyncEngine = ProfileSyncEngine()
    
    /// Social friend service
    @Published var friendService = FriendService()
    
    /// Activity feed service
    @Published var feedService = FeedService()
    
    /// Guild service
    @Published var guildService = GuildService()
    
    /// Guild quest service
    @Published var guildQuestService = GuildQuestService()
    
    /// Leaderboard service
    @Published var leaderboardService = LeaderboardService()
    
    /// Duel service
    @Published var duelService = DuelService()
    
    /// Season service
    @Published var seasonService = SeasonService()
    
    // MARK: - Health State
    
    /// Health sync engine (initialized after model container is ready)
    @Published var healthSyncEngine: HealthSyncEngine?
    
    /// Whether HealthKit is authorized
    @Published var isHealthAuthorized: Bool = false
    
    /// Last HealthKit sync date
    @Published var lastHealthSyncDate: Date?
    
    // MARK: - User Defaults Keys
    
    private enum Keys {
        static let onboardingComplete = "onboardingComplete"
        static let playerId = "currentPlayerId"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }
    
    // MARK: - Initialization
    
    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Keys.onboardingComplete)
    }
    
    // MARK: - Onboarding
    
    /// Mark onboarding as complete
    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: Keys.onboardingComplete)
    }
    
    /// Reset onboarding (for testing)
    func resetOnboarding() {
        isOnboardingComplete = false
        UserDefaults.standard.set(false, forKey: Keys.onboardingComplete)
        UserDefaults.standard.removeObject(forKey: Keys.playerId)
        currentPlayer = nil
    }
    
    // MARK: - Player Management
    
    /// Set the current player
    /// - Parameter player: Player to set as current
    func setCurrentPlayer(_ player: Player) {
        currentPlayer = player
        UserDefaults.standard.set(player.id.uuidString, forKey: Keys.playerId)
        
        // Sync profile to CloudKit
        Task {
            await setupCloudKit()
            await profileSyncEngine.forceSync(for: player)
        }
    }
    
    /// Load the current player from persistence
    /// - Parameter context: SwiftData model context
    func loadPlayer(from context: ModelContext) {
        guard let playerIdString = UserDefaults.standard.string(forKey: Keys.playerId),
              let playerId = UUID(uuidString: playerIdString) else {
            return
        }
        
        let descriptor = FetchDescriptor<Player>(
            predicate: #Predicate { $0.id == playerId }
        )
        
        do {
            let players = try context.fetch(descriptor)
            currentPlayer = players.first
            
            // Generate daily quests if needed
            if let player = currentPlayer {
                player.generateDailyQuests()
                player.checkQuestExpirations()
                
                // Seed achievements if needed & check progress
                let achievementService = AchievementService(modelContext: context)
                achievementService.generateInitialAchievements(for: player)
                
                // Seed food database (idempotent)
                FoodDatabase.seedIfNeeded(in: context)
                let unlocked = achievementService.checkAndUnlock(player: player)
                for title in unlocked {
                    showSuccess("Achievement Unlocked!", message: title)
                    SoundManager.shared.playAchievementUnlocked()
                }
            }
        } catch {
            print("Failed to load player: \(error)")
        }
    }
    
    /// Create a new player
    /// - Parameters:
    ///   - name: Player name
    ///   - context: SwiftData model context
    /// - Returns: The created player
    @discardableResult
    func createPlayer(name: String, in context: ModelContext) -> Player {
        let player = Player(name: name)
        player.initializeStats()
        player.generateDailyQuests()
        
        context.insert(player)
        
        // Seed achievements for the new player
        let achievementService = AchievementService(modelContext: context)
        achievementService.generateInitialAchievements(for: player)
        
        do {
            try context.save()
            setCurrentPlayer(player)
        } catch {
            print("Failed to save player: \(error)")
        }
        
        return player
    }
    
    // MARK: - Level Up Animation
    
    /// Trigger level up animation
    /// - Parameters:
    ///   - oldLevel: Previous level
    ///   - newLevel: New level
    ///   - rank: Current rank
    func triggerLevelUp(from oldLevel: Int, to newLevel: Int, rank: PlayerRank) {
        levelUpInfo = LevelUpInfo(
            oldLevel: oldLevel,
            newLevel: newLevel,
            rank: rank
        )
        showLevelUpAnimation = true
        
        // Play sound effect (would need AVFoundation)
        // AudioManager.shared.playSound(.levelUp)
    }
    
    /// Dismiss level up animation
    func dismissLevelUp() {
        withAnimation(AppAnimations.fadeOut) {
            showLevelUpAnimation = false
        }
        
        // Clear info after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.levelUpInfo = nil
        }
    }
    
    // MARK: - Notifications
    
    /// Show a system notification
    /// - Parameter notification: Notification to show
    func showNotification(_ notification: SystemNotification) {
        withAnimation(AppAnimations.slideIn) {
            pendingNotifications.append(notification)
        }
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) { [weak self] in
            self?.dismissNotification(notification)
        }
    }
    
    /// Dismiss a specific notification
    /// - Parameter notification: Notification to dismiss
    func dismissNotification(_ notification: SystemNotification) {
        withAnimation(AppAnimations.fadeOut) {
            pendingNotifications.removeAll { $0.id == notification.id }
        }
    }
    
    /// Show a success notification
    func showSuccess(_ title: String, message: String = "") {
        showNotification(SystemNotification(title: title, message: message, type: .success))
    }
    
    /// Show an error notification
    func showError(_ title: String, message: String = "") {
        showNotification(SystemNotification(title: title, message: message, type: .error))
    }
    
    /// Show a quest complete notification
    func showQuestComplete(_ questTitle: String, xpEarned: Int) {
        showNotification(SystemNotification(
            title: "Quest Complete!",
            message: "\(questTitle) - +\(xpEarned) XP",
            type: .questComplete
        ))
    }
    
    /// Show a stat increase notification
    func showStatIncrease(stat: StatType, xpEarned: Int) {
        showNotification(SystemNotification(
            title: "\(stat.shortName) +\(xpEarned) XP",
            message: "",
            type: .success,
            duration: 2.0
        ))
    }
    
    // MARK: - CloudKit
    
    /// Initialize CloudKit and check availability
    func setupCloudKit() async {
        await CloudKitService.shared.setup()
    }
}

// MARK: - Supporting Types

/// App tab enumeration
/// Primary bottom-bar destinations, matching the Anime mockup:
/// Home · Progress · (center crest button) · Community · Profile.
/// Workout and Nutrition are reached from Home and the center quick-action button.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case progress
    case community
    case profile
    
    var id: String { rawValue }
    
    var title: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .progress: return "chart.bar.fill"
        case .community: return "person.2.fill"
        case .profile: return "person.fill"
        }
    }
}

/// Level up information for animation
struct LevelUpInfo {
    let oldLevel: Int
    let newLevel: Int
    let rank: PlayerRank
    
    var levelsGained: Int {
        newLevel - oldLevel
    }
    
    var isRankUp: Bool {
        PlayerRank.from(level: oldLevel) != rank
    }
}

/// System notification model
struct SystemNotification: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: NotificationType
    let duration: TimeInterval
    let createdAt: Date
    
    init(
        title: String,
        message: String = "",
        type: NotificationType,
        duration: TimeInterval = 3.0
    ) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
        self.createdAt = Date()
    }
    
    static func == (lhs: SystemNotification, rhs: SystemNotification) -> Bool {
        lhs.id == rhs.id
    }
}

/// Notification type for styling
enum NotificationType {
    case success
    case warning
    case error
    case info
    case levelUp
    case questComplete
    case statIncrease
    
    var color: Color {
        switch self {
        case .success, .questComplete: return AppColors.success
        case .warning: return AppColors.warning
        case .error: return AppColors.error
        case .info: return AppColors.info
        case .levelUp: return AppColors.accentPurple
        case .statIncrease: return AppColors.primaryBlue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .questComplete: return "star.fill"
        case .statIncrease: return "plus.circle.fill"
        }
    }
}
