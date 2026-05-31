import Foundation
import HealthKit
import Combine

/// Fetches and manages meditation sessions from HealthKit and manual logging
@MainActor
class MeditationService: ObservableObject {
    
    // MARK: - Properties
    
    private let healthKit: HealthKitManager
    
    @Published var recentSessions: [MeditationSession] = []
    @Published var weeklyMinutes: Double = 0
    @Published var weeklySessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init(healthKit: HealthKitManager? = nil) {
        self.healthKit = healthKit ?? HealthKitManager.shared
    }
    
    // MARK: - Fetch Recent Sessions
    
    /// Fetch recent meditation sessions from HealthKit mindful minutes
    /// - Parameter limit: Maximum number of sessions to return
    func fetchRecentSessions(limit: Int = 10) async {
        guard healthKit.isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let samples = try await fetchMindfulSamples(from: startDate, to: Date())
            
            let sessions = samples
                .map { MeditationSession.from(sample: $0, consecutiveDays: currentStreak) }
                .sorted { $0.date > $1.date }
                .prefix(limit)
            
            recentSessions = Array(sessions)
        } catch {
            print("MeditationService: Failed to fetch sessions — \(error)")
        }
    }
    
    // MARK: - Weekly Stats
    
    /// Fetch weekly meditation stats
    func fetchWeeklyStats() async {
        guard healthKit.isAuthorized else { return }
        
        do {
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2
            let weekStart = calendar.date(from: components) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            
            let samples = try await fetchMindfulSamples(from: weekStart, to: weekEnd)
            
            weeklyMinutes = samples.reduce(0.0) {
                $0 + $1.endDate.timeIntervalSince($1.startDate) / 60.0
            }
            weeklySessions = samples.count
        } catch {
            print("MeditationService: Failed to fetch weekly stats — \(error)")
        }
    }
    
    // MARK: - Streak Calculation
    
    /// Calculate consecutive meditation days
    func calculateStreak() async {
        guard healthKit.isAuthorized else { return }
        
        do {
            let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            let samples = try await fetchMindfulSamples(from: startDate, to: Date())
            
            let calendar = Calendar.current
            var streak = 0
            var checkDate = calendar.startOfDay(for: Date())
            
            let sessionDates = Set(samples.map { calendar.startOfDay(for: $0.startDate) })
            
            while sessionDates.contains(checkDate) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            }
            
            currentStreak = streak
        } catch {
            print("MeditationService: Failed to calculate streak — \(error)")
        }
    }
    
    // MARK: - Manual Logging
    
    /// Log a manual meditation session
    /// - Parameters:
    ///   - type: Type of meditation
    ///   - duration: Duration in seconds
    ///   - notes: Optional notes
    /// - Returns: The created session with XP earned
    func logManualSession(
        type: MeditationType,
        duration: TimeInterval,
        notes: String? = nil
    ) -> MeditationSession {
        let session = MeditationSession.manual(
            type: type,
            duration: duration,
            notes: notes,
            consecutiveDays: currentStreak
        )
        
        recentSessions.insert(session, at: 0)
        weeklyMinutes += duration / 60.0
        weeklySessions += 1
        
        return session
    }
    
    /// Log a session from the built-in timer
    /// - Parameters:
    ///   - type: Type of meditation
    ///   - duration: Duration in seconds
    /// - Returns: The created session with XP earned
    func logTimerSession(
        type: MeditationType,
        duration: TimeInterval
    ) -> MeditationSession {
        let session = MeditationSession.fromTimer(
            type: type,
            duration: duration,
            consecutiveDays: currentStreak
        )
        
        recentSessions.insert(session, at: 0)
        weeklyMinutes += duration / 60.0
        weeklySessions += 1
        
        return session
    }
    
    // MARK: - Daily Breakdown
    
    /// Get daily meditation minutes for the current week (Mon-Sun)
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
            
            let samples = try await fetchMindfulSamples(from: weekStart, to: weekEnd)
            
            var daily = Array(repeating: 0.0, count: 7)
            for sample in samples {
                let dayIndex = (calendar.component(.weekday, from: sample.startDate) + 5) % 7
                daily[dayIndex] += sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            }
            return daily
        } catch {
            return Array(repeating: 0, count: 7)
        }
    }
    
    // MARK: - HealthKit Query
    
    /// Fetch mindful session samples from HealthKit
    private func fetchMindfulSamples(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let samples = (results as? [HKCategorySample]) ?? []
                continuation.resume(returning: samples)
            }
            
            healthKit.healthStore.execute(query)
        }
    }
}
