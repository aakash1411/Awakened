import Foundation
import HealthKit
import Combine

/// Fetches and assembles cardio activities from HealthKit
@MainActor
class CardioService: ObservableObject {
    
    // MARK: - Properties
    
    private let healthKit: HealthKitManager
    
    @Published var recentActivities: [CardioActivity] = []
    @Published var weeklyStats: WeeklyCardioStats = .empty
    @Published var isLoading = false
    
    /// Cardio workout activity types
    static let cardioTypes: Set<HKWorkoutActivityType> = [
        .running, .cycling, .swimming, .walking, .hiking,
        .highIntensityIntervalTraining, .elliptical, .rowing,
        .stairClimbing, .kickboxing, .skatingSports, .surfingSports,
        .snowSports, .paddleSports, .soccer, .basketball, .tennis,
        .badminton, .tableTennis, .handball, .volleyball, .baseball,
        .softball, .rugby, .hockey, .lacrosse
    ]
    
    // MARK: - Initialization
    
    init(healthKit: HealthKitManager? = nil) {
        self.healthKit = healthKit ?? HealthKitManager.shared
    }
    
    // MARK: - Fetch Methods
    
    /// Load recent cardio activities and weekly stats
    func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        async let recentResult = fetchRecentCardio(limit: 10)
        async let weeklyResult = fetchWeeklyStats()
        
        recentActivities = (try? await recentResult) ?? []
        weeklyStats = (try? await weeklyResult) ?? .empty
    }
    
    /// Fetch recent cardio workouts from HealthKit
    /// - Parameter limit: Maximum number of activities to return
    /// - Returns: Array of CardioActivity sorted by date descending
    func fetchRecentCardio(limit: Int = 10) async throws -> [CardioActivity] {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        let workouts = try await healthKit.fetchWorkouts(from: thirtyDaysAgo, to: now)
        
        return workouts
            .filter { Self.cardioTypes.contains($0.workoutActivityType) }
            .sorted { $0.startDate > $1.startDate }
            .prefix(limit)
            .map { CardioActivity(workout: $0) }
    }
    
    /// Fetch cardio history with optional type filter
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    ///   - type: Optional activity type filter (nil = all cardio)
    /// - Returns: Array of CardioActivity sorted by date descending
    func fetchCardioHistory(
        from startDate: Date,
        to endDate: Date,
        type: HKWorkoutActivityType? = nil
    ) async throws -> [CardioActivity] {
        let workouts = try await healthKit.fetchWorkouts(from: startDate, to: endDate)
        
        return workouts
            .filter { workout in
                let isCardio = Self.cardioTypes.contains(workout.workoutActivityType)
                if let filterType = type {
                    return isCardio && workout.workoutActivityType == filterType
                }
                return isCardio
            }
            .sorted { $0.startDate > $1.startDate }
            .map { CardioActivity(workout: $0) }
    }
    
    /// Fetch detailed activity with HR samples and route data
    /// - Parameter workout: The HKWorkout to enrich
    /// - Returns: CardioActivity with HR samples and route locations populated
    func fetchDetailedActivity(workout: HKWorkout) async throws -> CardioActivity {
        // Fetch HR samples for the workout's time range
        let hrSamples = try? await healthKit.fetchHeartRateSamples(
            from: workout.startDate,
            to: workout.endDate
        )
        
        // Fetch route locations
        let routeLocations = try? await healthKit.fetchWorkoutRoute(for: workout)
        
        return CardioActivity(
            workout: workout,
            heartRateSamples: hrSamples,
            routeLocations: routeLocations
        )
    }
    
    /// Compute weekly cardio stats
    /// - Returns: Aggregated stats for the current week
    func fetchWeeklyStats() async throws -> WeeklyCardioStats {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
        
        let workouts = try await healthKit.fetchWorkouts(from: weekStart, to: weekEnd)
        let cardioWorkouts = workouts.filter { Self.cardioTypes.contains($0.workoutActivityType) }
        
        var totalDistance = 0.0
        var totalDuration: TimeInterval = 0
        var dailyMinutes = Array(repeating: 0.0, count: 7)
        var dailyDistance = Array(repeating: 0.0, count: 7)
        
        for workout in cardioWorkouts {
            let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
            totalDistance += distance
            totalDuration += workout.duration
            
            // Determine day index (0 = Monday, 6 = Sunday)
            let dayIndex = (calendar.component(.weekday, from: workout.startDate) + 5) % 7
            dailyMinutes[dayIndex] += workout.duration / 60.0
            dailyDistance[dayIndex] += distance
        }
        
        return WeeklyCardioStats(
            totalDistanceKm: totalDistance,
            totalDuration: totalDuration,
            sessionCount: cardioWorkouts.count,
            dailyMinutes: dailyMinutes,
            dailyDistanceKm: dailyDistance
        )
    }
}
