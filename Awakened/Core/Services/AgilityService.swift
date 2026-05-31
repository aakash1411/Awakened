import Foundation
import HealthKit
import Combine

/// Fetches and manages flexibility/agility sessions from HealthKit and manual logging
@MainActor
class AgilityService: ObservableObject {
    
    // MARK: - Properties
    
    private let healthKit: HealthKitManager
    
    @Published var recentSessions: [FlexibilitySession] = []
    @Published var weeklyMinutes: Double = 0
    @Published var weeklySessions: Int = 0
    @Published var isLoading: Bool = false
    
    /// HK workout types that map to Agility
    static let agilityTypes: Set<HKWorkoutActivityType> = [
        .yoga,
        .flexibility,
        .coreTraining,
        .gymnastics,
        .pilates,
        .socialDance,
        .cardioDance,
        .martialArts
    ]
    
    // MARK: - Initialization
    
    init(healthKit: HealthKitManager? = nil) {
        self.healthKit = healthKit ?? HealthKitManager.shared
    }
    
    // MARK: - Fetch Recent Sessions
    
    /// Fetch recent flexibility sessions from HealthKit
    /// - Parameter limit: Maximum number of sessions to return
    func fetchRecentSessions(limit: Int = 10) async {
        guard healthKit.isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let workouts = try await healthKit.fetchWorkouts(from: startDate, to: Date())
            
            let agilitySessions = workouts
                .filter { Self.agilityTypes.contains($0.workoutActivityType) }
                .compactMap { FlexibilitySession.from(workout: $0) }
                .sorted { $0.date > $1.date }
                .prefix(limit)
            
            recentSessions = Array(agilitySessions)
        } catch {
            print("AgilityService: Failed to fetch sessions — \(error)")
        }
    }
    
    // MARK: - Weekly Stats
    
    /// Fetch weekly agility stats
    func fetchWeeklyStats() async {
        guard healthKit.isAuthorized else { return }
        
        do {
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2 // Monday
            let weekStart = calendar.date(from: components) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            
            let workouts = try await healthKit.fetchWorkouts(from: weekStart, to: weekEnd)
            let agilityWorkouts = workouts.filter { Self.agilityTypes.contains($0.workoutActivityType) }
            
            weeklyMinutes = agilityWorkouts.reduce(0.0) { $0 + $1.duration / 60.0 }
            weeklySessions = agilityWorkouts.count
        } catch {
            print("AgilityService: Failed to fetch weekly stats — \(error)")
        }
    }
    
    // MARK: - Manual Logging
    
    /// Log a manual flexibility session
    /// - Parameters:
    ///   - type: Type of flexibility activity
    ///   - duration: Duration in seconds
    ///   - intensity: Activity intensity
    ///   - notes: Optional notes
    /// - Returns: The created session with XP earned
    func logManualSession(
        type: FlexibilityType,
        duration: TimeInterval,
        intensity: ActivityIntensity,
        notes: String? = nil
    ) -> FlexibilitySession {
        let session = FlexibilitySession.manual(
            type: type,
            duration: duration,
            intensity: intensity,
            notes: notes
        )
        
        // Prepend to recent sessions
        recentSessions.insert(session, at: 0)
        weeklyMinutes += duration / 60.0
        weeklySessions += 1
        
        return session
    }
    
    // MARK: - Daily Breakdown
    
    /// Get daily agility minutes for the current week (Mon-Sun)
    /// - Returns: Array of 7 daily minute values
    func fetchDailyBreakdown() async -> [Double] {
        guard healthKit.isAuthorized else { return Array(repeating: 0, count: 7) }
        
        do {
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            let weekStart = calendar.date(from: components) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            
            let workouts = try await healthKit.fetchWorkouts(from: weekStart, to: weekEnd)
            let agilityWorkouts = workouts.filter { Self.agilityTypes.contains($0.workoutActivityType) }
            
            var daily = Array(repeating: 0.0, count: 7)
            for workout in agilityWorkouts {
                let dayIndex = (calendar.component(.weekday, from: workout.startDate) + 5) % 7
                daily[dayIndex] += workout.duration / 60.0
            }
            return daily
        } catch {
            return Array(repeating: 0, count: 7)
        }
    }
}
