import Foundation
import HealthKit
import CoreLocation

/// Lightweight wrapper around HKWorkout for cardio display — not persisted in SwiftData
struct CardioActivity: Identifiable {
    
    // MARK: - Core Properties
    
    /// Unique identifier (from HKWorkout UUID)
    let id: UUID
    
    /// HealthKit workout activity type
    let activityType: HKWorkoutActivityType
    
    /// When the activity started
    let date: Date
    
    /// Duration in seconds
    let duration: TimeInterval
    
    /// Distance in meters (nil if not applicable, e.g. stationary bike)
    let distanceMeters: Double?
    
    /// Active energy burned in kilocalories
    let activeCalories: Double?
    
    /// Average heart rate in BPM (nil if no HR data)
    let averageHeartRate: Double?
    
    /// Max heart rate in BPM (nil if no HR data)
    let maxHeartRate: Double?
    
    // MARK: - Detailed Data (populated on demand)
    
    /// GPS route locations (nil until detail view fetches them)
    var routeLocations: [CLLocation]?
    
    /// Heart rate samples during the activity
    var heartRateSamples: [HeartRateSample]?
    
    /// Time spent in each HR zone
    var zoneDistribution: [HeartRateZone: TimeInterval]?
    
    // MARK: - Computed Properties
    
    /// Distance in kilometers
    var distanceKm: Double? {
        guard let m = distanceMeters, m > 0 else { return nil }
        return m / 1000.0
    }
    
    /// Formatted distance (e.g., "5.23 km")
    var distanceFormatted: String {
        guard let km = distanceKm else { return "—" }
        return String(format: "%.2f km", km)
    }
    
    /// Pace in seconds per kilometer (nil if no distance)
    var paceSecondsPerKm: Double? {
        guard let km = distanceKm, km > 0, duration > 0 else { return nil }
        return duration / km
    }
    
    /// Formatted pace (e.g., "5:23 /km")
    var paceFormatted: String {
        guard let pace = paceSecondsPerKm else { return "—" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    /// Duration formatted as "1h 23m" or "45m"
    var durationFormatted: String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Human-readable activity name
    var displayName: String {
        WorkoutStatMapper.displayName(for: activityType)
    }
    
    /// SF Symbol icon for this activity type
    var icon: String {
        WorkoutStatMapper.icon(for: activityType)
    }
    
    /// Calories formatted
    var caloriesFormatted: String {
        guard let cal = activeCalories, cal > 0 else { return "—" }
        return "\(Int(cal)) kcal"
    }
    
    /// Average HR formatted
    var averageHRFormatted: String {
        guard let hr = averageHeartRate else { return "—" }
        return "\(Int(hr)) bpm"
    }
    
    /// XP earned for this activity
    var xpEarned: Int {
        var xp = XPCalculator.vitalityXP(
            durationMinutes: duration / 60.0,
            distanceKm: distanceKm,
            averageHeartRate: averageHeartRate != nil ? Int(averageHeartRate!) : nil
        )
        
        // Apply zone bonus if we have zone distribution
        if let zones = zoneDistribution {
            let totalZoneTime = zones.values.reduce(0, +)
            guard totalZoneTime > 0 else { return xp }
            var weightedMultiplier = 0.0
            for (zone, time) in zones {
                weightedMultiplier += zone.xpMultiplier * (time / totalZoneTime)
            }
            xp = Int(Double(xp) * weightedMultiplier)
        }
        
        return max(1, xp)
    }
    
    /// Date formatted for display (e.g., "Today", "Yesterday", or "Mon, Apr 7")
    var dateFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    /// Time formatted (e.g., "6:30 AM")
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    /// Create from an HKWorkout
    /// - Parameters:
    ///   - workout: HealthKit workout object
    ///   - heartRateSamples: Optional HR samples fetched separately
    ///   - routeLocations: Optional GPS locations fetched separately
    init(
        workout: HKWorkout,
        heartRateSamples: [HeartRateSample]? = nil,
        routeLocations: [CLLocation]? = nil
    ) {
        self.id = workout.uuid
        self.activityType = workout.workoutActivityType
        self.date = workout.startDate
        self.duration = workout.duration
        self.distanceMeters = workout.totalDistance?.doubleValue(for: .meter())
        self.activeCalories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
        self.heartRateSamples = heartRateSamples
        self.routeLocations = routeLocations
        
        // Compute average and max HR from samples
        if let samples = heartRateSamples, !samples.isEmpty {
            self.averageHeartRate = samples.reduce(0.0) { $0 + $1.bpm } / Double(samples.count)
            self.maxHeartRate = samples.map(\.bpm).max()
            self.zoneDistribution = Self.computeZoneDistribution(samples: samples)
        } else {
            self.averageHeartRate = nil
            self.maxHeartRate = nil
            self.zoneDistribution = nil
        }
    }
    
    /// Preview/mock initializer
    init(
        id: UUID = UUID(),
        activityType: HKWorkoutActivityType,
        date: Date,
        duration: TimeInterval,
        distanceMeters: Double?,
        activeCalories: Double?,
        averageHeartRate: Double?,
        maxHeartRate: Double? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.date = date
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.routeLocations = nil
        self.heartRateSamples = nil
        self.zoneDistribution = nil
    }
    
    // MARK: - Helpers
    
    /// Compute time in each HR zone from sorted samples
    private static func computeZoneDistribution(samples: [HeartRateSample]) -> [HeartRateZone: TimeInterval] {
        guard samples.count >= 2 else { return [:] }
        
        let sorted = samples.sorted { $0.date < $1.date }
        var distribution: [HeartRateZone: TimeInterval] = [:]
        
        for i in 0..<(sorted.count - 1) {
            let zone = HeartRateZone.from(bpm: sorted[i].bpm)
            let timeDelta = sorted[i + 1].date.timeIntervalSince(sorted[i].date)
            // Cap individual gap at 5 minutes to handle sparse data
            let clampedDelta = min(timeDelta, 300)
            distribution[zone, default: 0] += clampedDelta
        }
        
        return distribution
    }
}

// MARK: - Weekly Stats

/// Aggregated weekly cardio statistics
struct WeeklyCardioStats {
    /// Total distance in km
    let totalDistanceKm: Double
    
    /// Total duration in seconds
    let totalDuration: TimeInterval
    
    /// Number of cardio sessions
    let sessionCount: Int
    
    /// Daily breakdown (7 entries, index 0 = Monday)
    let dailyMinutes: [Double]
    
    /// Daily distance breakdown
    let dailyDistanceKm: [Double]
    
    /// Formatted total distance
    var totalDistanceFormatted: String {
        String(format: "%.1f km", totalDistanceKm)
    }
    
    /// Formatted total duration
    var totalDurationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Average pace across the week (seconds per km)
    var averagePace: Double? {
        guard totalDistanceKm > 0 else { return nil }
        return totalDuration / totalDistanceKm
    }
    
    /// Formatted average pace
    var averagePaceFormatted: String {
        guard let pace = averagePace else { return "—" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    static let empty = WeeklyCardioStats(
        totalDistanceKm: 0,
        totalDuration: 0,
        sessionCount: 0,
        dailyMinutes: Array(repeating: 0, count: 7),
        dailyDistanceKm: Array(repeating: 0, count: 7)
    )
}

// MARK: - Split Data

/// Per-kilometer split for pace analysis
struct SplitData: Identifiable {
    let id = UUID()
    
    /// Split number (1-indexed)
    let number: Int
    
    /// Distance of this split in meters
    let distanceMeters: Double
    
    /// Duration of this split in seconds
    let duration: TimeInterval
    
    /// Average heart rate during this split
    let averageHeartRate: Double?
    
    /// Elevation gain in meters
    let elevationGain: Double
    
    /// Elevation loss in meters
    let elevationLoss: Double
    
    /// Pace in seconds per km
    var paceSecondsPerKm: Double {
        guard distanceMeters > 0 else { return 0 }
        return duration / (distanceMeters / 1000.0)
    }
    
    /// Formatted pace (e.g., "5:23")
    var paceFormatted: String {
        let minutes = Int(paceSecondsPerKm) / 60
        let seconds = Int(paceSecondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted elevation
    var elevationFormatted: String {
        let net = elevationGain - elevationLoss
        let sign = net >= 0 ? "+" : ""
        return String(format: "%@%.0fm", sign, net)
    }
}
