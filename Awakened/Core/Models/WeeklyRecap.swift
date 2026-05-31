import Foundation

/// Aggregated weekly summary for the recap screen
struct WeeklyRecap: Codable {
    let weekStart: Date
    let totalXP: Int
    let xpByStatRaw: [String: Int]
    let questsCompleted: Int
    let questsFailed: Int
    let workoutsLogged: Int
    let cardioDistanceKm: Double
    let meditationMinutes: Double
    let readingMinutes: Double
    let streakDays: Int
    let achievementsUnlocked: [String]
    let levelFrom: Int
    let levelTo: Int
    
    // MARK: - Computed
    
    /// Whether the player leveled up this week
    var didLevelUp: Bool {
        levelTo > levelFrom
    }
    
    /// Total minutes of activity (cardio + meditation + reading)
    var totalActiveMinutes: Double {
        cardioDistanceKm * 6 + meditationMinutes + readingMinutes // rough estimate for cardio
    }
    
    /// XP by stat type
    var xpByStat: [StatType: Int] {
        var result: [StatType: Int] = [:]
        for (key, value) in xpByStatRaw {
            if let type = StatType(rawValue: key) {
                result[type] = value
            }
        }
        return result
    }
    
    /// Formatted week range (e.g., "Apr 7 – Apr 13")
    var weekRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: end))"
    }
}
