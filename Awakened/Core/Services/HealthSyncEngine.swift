import Foundation
import SwiftData
import HealthKit
import Combine

/// Orchestrates syncing HealthKit data → Player XP and Quest progress
@MainActor
class HealthSyncEngine: ObservableObject {
    
    // MARK: - Properties
    
    private let healthKit: HealthKitManager
    private var modelContext: ModelContext
    
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    
    // Today's cached health data for dashboard display
    @Published var todaySteps: Int = 0
    @Published var todaySleepHours: Double = 0
    @Published var todayMindfulMinutes: Double = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todayDistance: Double = 0
    @Published var todayWorkoutMinutes: Double = 0
    @Published var todayWorkoutCount: Int = 0
    @Published var currentWeight: Double?
    @Published var currentBodyFat: Double?
    @Published var averageHeartRate: Double?
    
    // Weekly cardio stats for CardioView
    @Published var weeklyCardioDistance: Double = 0
    @Published var weeklyCardioMinutes: Double = 0
    @Published var weeklyCardioSessions: Int = 0
    
    // Weekly agility & meditation stats
    @Published var weeklyAgilityMinutes: Double = 0
    @Published var weeklyMeditationMinutes: Double = 0
    
    /// UserDefaults key for last sync date
    private let lastSyncKey = "lastHealthSyncDate"
    
    /// UserDefaults key for last steps sync (to avoid re-crediting)
    private let lastStepsSyncDateKey = "lastStepsSyncDate"
    
    // MARK: - XP Caps
    
    private let maxStepsXPPerDay = 150
    private let maxActiveEnergyXPPerDay = 50
    
    // MARK: - Initialization
    
    init(healthKit: HealthKitManager? = nil, modelContext: ModelContext) {
        self.healthKit = healthKit ?? HealthKitManager.shared
        self.modelContext = modelContext
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }
    
    // MARK: - Full Sync
    
    /// Perform a full sync of all HealthKit data
    func syncAll() async {
        guard !isSyncing else { return }
        guard healthKit.isAuthorized else { return }
        
        guard let player = fetchCurrentPlayer() else {
            syncError = "No player found"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            let today = Date()
            
            // Sync all data types in parallel where possible
            async let stepsResult: () = syncSteps(for: today, player: player)
            async let sleepResult: () = syncSleep(for: today, player: player)
            async let mindfulResult: () = syncMindfulMinutes(for: today, player: player)
            async let workoutsResult: () = syncWorkouts(since: lastSyncDate ?? Calendar.current.startOfDay(for: today), player: player)
            async let metricsResult: () = syncBodyMetrics()
            async let energyResult: () = syncActiveEnergy(for: today, player: player)
            async let cardioResult: () = syncWeeklyCardioStats()
            async let agilityResult: () = syncWeeklyAgilityStats()
            async let meditationResult: () = syncWeeklyMeditationStats()
            
            // Await all
            _ = try await (stepsResult, sleepResult, mindfulResult, workoutsResult, metricsResult, energyResult, cardioResult, agilityResult, meditationResult)
            
            // Update quests from health data
            try await updateQuestsFromHealthData(player: player)
            
            // Save context
            try modelContext.save()
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            
            // Cleanup old sync records periodically
            SyncRecord.cleanupOldRecords(in: modelContext)
            
        } catch let error as HealthKitError {
            switch error {
            case .noData:
                // No data is normal on fresh device/simulator — not an error
                break
            case .queryFailed(let underlying):
                // HK code 11 = "no data available" — benign
                if let nsError = underlying as NSError?, nsError.domain == "com.apple.healthkit", nsError.code == 11 {
                    break
                }
                syncError = error.localizedDescription
                print("Health sync error: \(error)")
            default:
                syncError = error.localizedDescription
                print("Health sync error: \(error)")
            }
        } catch {
            // Ignore benign HK "no data" that slipped through
            let nsErr = error as NSError
            if nsErr.domain == "com.apple.healthkit", nsErr.code == 11 { /* no-op */ }
            else {
                syncError = error.localizedDescription
                print("Health sync error: \(error)")
            }
        }
        
        isSyncing = false
    }
    
    // MARK: - Steps Sync
    
    /// Sync step count for a given date
    func syncSteps(for date: Date, player: Player) async throws {
        let steps = try await healthKit.fetchSteps(for: date)
        todaySteps = steps
        
        // Calculate XP from steps: 1 XP per 100 steps, capped
        let stepsXP = min(steps / 100, maxStepsXPPerDay)
        
        // Check if we already credited steps today
        let syncKey = "steps_\(dateKey(for: date))"
        if !SyncRecord.isProcessed(syncKey, in: modelContext) && stepsXP > 0 {
            let (xpAdded, _) = player.addXP(stepsXP, to: .vitality)
            
            // Record the sync
            let record = SyncRecord(
                healthKitUUID: syncKey,
                sourceType: "steps",
                xpCredited: xpAdded,
                statType: .vitality,
                sampleDate: date
            )
            modelContext.insert(record)
        }
    }
    
    // MARK: - Sleep Sync
    
    /// Sync sleep data for a given date
    func syncSleep(for date: Date, player: Player) async throws {
        let sleepHours = try await healthKit.fetchSleepHours(for: date)
        todaySleepHours = sleepHours
        
        // Calculate sleep XP: hours × 5, bonus for optimal range
        var sleepXP = 0
        if sleepHours >= 6 {
            sleepXP = Int(sleepHours * 5)
            // Bonus for 7-9 hours (optimal)
            if sleepHours >= 7 && sleepHours <= 9 {
                sleepXP += 10
            }
        }
        
        let syncKey = "sleep_\(dateKey(for: date))"
        if !SyncRecord.isProcessed(syncKey, in: modelContext) && sleepXP > 0 {
            let (xpAdded, _) = player.addXP(sleepXP, to: .vitality)
            
            let record = SyncRecord(
                healthKitUUID: syncKey,
                sourceType: "sleep",
                xpCredited: xpAdded,
                statType: .vitality,
                sampleDate: date
            )
            modelContext.insert(record)
        }
    }
    
    // MARK: - Workouts Sync
    
    /// Sync workouts since a given date
    func syncWorkouts(since startDate: Date, player: Player) async throws {
        let workouts = try await healthKit.fetchWorkouts(from: startDate, to: Date())
        
        var totalMinutesToday = 0.0
        var countToday = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for workout in workouts {
            let uuidString = workout.uuid.uuidString
            
            // Track today's totals for dashboard
            if calendar.isDate(workout.startDate, inSameDayAs: today) {
                totalMinutesToday += workout.duration / 60.0
                countToday += 1
            }
            
            // Skip if already processed
            guard !SyncRecord.isProcessed(uuidString, in: modelContext) else { continue }
            
            // Calculate XP
            let (stat, xp) = WorkoutStatMapper.calculateXP(for: workout)
            
            guard xp > 0 else { continue }
            
            // Credit XP
            let (xpAdded, _) = player.addXP(xp, to: stat)
            
            // Record the sync
            let record = SyncRecord(
                healthKitUUID: uuidString,
                sourceType: "workout",
                xpCredited: xpAdded,
                statType: stat,
                sampleDate: workout.startDate
            )
            modelContext.insert(record)
        }
        
        todayWorkoutMinutes = totalMinutesToday
        todayWorkoutCount = countToday
    }
    
    // MARK: - Mindful Minutes Sync
    
    /// Sync mindful minutes for a given date
    func syncMindfulMinutes(for date: Date, player: Player) async throws {
        let minutes = try await healthKit.fetchMindfulMinutes(for: date)
        todayMindfulMinutes = minutes
        
        guard minutes > 0 else { return }
        
        let senseXP = XPCalculator.senseXP(
            durationMinutes: minutes,
            consecutiveDays: player.currentStreak
        )
        
        let syncKey = "mindful_\(dateKey(for: date))"
        if !SyncRecord.isProcessed(syncKey, in: modelContext) && senseXP > 0 {
            let (xpAdded, _) = player.addXP(senseXP, to: .sense)
            
            let record = SyncRecord(
                healthKitUUID: syncKey,
                sourceType: "mindfulSession",
                xpCredited: xpAdded,
                statType: .sense,
                sampleDate: date
            )
            modelContext.insert(record)
        }
    }
    
    // MARK: - Active Energy Sync
    
    /// Sync active energy and distance for a given date
    func syncActiveEnergy(for date: Date, player: Player) async throws {
        let kcal = try await healthKit.fetchActiveEnergy(for: date)
        todayActiveEnergy = kcal
        
        // Also sync today's walking/running distance (km)
        todayDistance = try await healthKit.fetchDistance(for: date)
        
        // XP: activeKcal / 50, capped
        let energyXP = min(Int(kcal / 50), maxActiveEnergyXPPerDay)
        
        let syncKey = "energy_\(dateKey(for: date))"
        if !SyncRecord.isProcessed(syncKey, in: modelContext) && energyXP > 0 {
            let (xpAdded, _) = player.addXP(energyXP, to: .vitality)
            
            let record = SyncRecord(
                healthKitUUID: syncKey,
                sourceType: "activeEnergy",
                xpCredited: xpAdded,
                statType: .vitality,
                sampleDate: date
            )
            modelContext.insert(record)
        }
    }
    
    // MARK: - Body Metrics Sync
    
    /// Sync body metrics (display only, no XP)
    func syncBodyMetrics() async throws {
        currentWeight = try await healthKit.fetchBodyMass()
        currentBodyFat = try await healthKit.fetchBodyFatPercentage()
    }
    
    // MARK: - Quest Auto-Tracking
    
    /// Update quest progress from HealthKit data
    func updateQuestsFromHealthData(player: Player) async throws {
        let todayQuests = player.todayQuests
        
        for quest in todayQuests {
            guard quest.isActive else { continue }
            
            switch quest.category {
            case .steps:
                quest.updateProgress(Double(todaySteps))
                
            case .sleep:
                quest.updateProgress(todaySleepHours)
                
            case .workout:
                quest.updateProgress(todayWorkoutMinutes)
                
            case .meditation:
                quest.updateProgress(todayMindfulMinutes)
                
            case .cardioDistance:
                // Use today's cardio workout minutes (more meaningful than km for VIT)
                quest.updateProgress(todayWorkoutMinutes)
                
            case .strength:
                // Composite Strength Points: bodyweight reps + walking bonus
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let todaySets = player.workoutSessions
                    .filter { $0.date >= startOfDay }
                    .flatMap { $0.sets }
                let sp = StrengthPointsCalculator.points(fromSets: todaySets, steps: todaySteps)
                quest.updateProgress(sp)
                
            case .knowledge:
                // Combined reading + learning minutes
                let startOfDay = Calendar.current.startOfDay(for: Date())
                let readingMin = player.readingEntries
                    .filter { $0.date >= startOfDay }
                    .reduce(0.0) { $0 + $1.minutesRead }
                let learningMin = player.learningSessions
                    .filter { $0.date >= startOfDay }
                    .reduce(0.0) { $0 + $1.durationMinutes }
                quest.updateProgress(readingMin + learningMin)
                
            case .flexibility:
                // Flexibility minutes from agility/yoga workouts (uses weeklyAgilityMinutes today)
                // Manual logs update via LogFlexibilityView; HK sync via weekly stats
                break
                
            default:
                // water, protein, reading, learning, custom tracked manually elsewhere
                break
            }
            
            // Complete quest if target met
            if quest.progress >= 1.0 && !quest.isCompleted {
                player.completeQuest(quest)
            }
        }
        
        // Check if all daily quests are completed
        let allCompleted = player.todayQuests.allSatisfy { $0.isCompleted }
        if allCompleted && !player.todayQuests.isEmpty {
            player.updateStreak(completedDailyQuests: true)
        }
    }
    
    // MARK: - Weekly Cardio Stats
    
    /// Sync weekly cardio summary for dashboard display
    func syncWeeklyCardioStats() async throws {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        
        let workouts = try await healthKit.fetchWorkouts(from: weekStart, to: weekEnd)
        let cardioWorkouts = workouts.filter { CardioService.cardioTypes.contains($0.workoutActivityType) }
        
        weeklyCardioDistance = cardioWorkouts.reduce(0.0) {
            $0 + ($1.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0)
        }
        weeklyCardioMinutes = cardioWorkouts.reduce(0.0) { $0 + $1.duration / 60.0 }
        weeklyCardioSessions = cardioWorkouts.count
    }
    
    // MARK: - Weekly Agility Stats
    
    /// Sync weekly agility/flexibility summary
    func syncWeeklyAgilityStats() async throws {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        
        let workouts = try await healthKit.fetchWorkouts(from: weekStart, to: weekEnd)
        let agilityWorkouts = workouts.filter { AgilityService.agilityTypes.contains($0.workoutActivityType) }
        
        weeklyAgilityMinutes = agilityWorkouts.reduce(0.0) { $0 + $1.duration / 60.0 }
    }
    
    // MARK: - Weekly Meditation Stats
    
    /// Sync weekly meditation summary from mindful sessions
    func syncWeeklyMeditationStats() async throws {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2
        let weekStart = calendar.date(from: components) ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        
        weeklyMeditationMinutes = try await healthKit.fetchMindfulMinutes(from: weekStart, to: weekEnd)
    }
    
    // MARK: - Helpers
    
    /// Fetch the current player from the model context
    private func fetchCurrentPlayer() -> Player? {
        let descriptor = FetchDescriptor<Player>()
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to fetch player: \(error)")
            return nil
        }
    }
    
    /// Generate a date key string for deduplication (e.g., "2024-01-15")
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
