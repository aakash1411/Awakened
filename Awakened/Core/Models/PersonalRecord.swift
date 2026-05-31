import Foundation
import SwiftData

/// Type of personal record
enum RecordType: String, Codable, CaseIterable {
    case maxWeight      // Heaviest weight lifted for any reps
    case maxReps        // Most reps at any weight
    case maxVolume      // Highest single-set volume (weight × reps)
    case estimated1RM   // Estimated 1-rep max using Brzycki formula
    
    var displayName: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .maxReps: return "Max Reps"
        case .maxVolume: return "Max Volume"
        case .estimated1RM: return "Est. 1RM"
        }
    }
    
    var icon: String {
        switch self {
        case .maxWeight: return "scalemass.fill"
        case .maxReps: return "repeat"
        case .maxVolume: return "chart.bar.fill"
        case .estimated1RM: return "trophy.fill"
        }
    }
}

/// Tracks a personal record for a specific exercise
@Model
final class PersonalRecord {
    
    /// Unique identifier
    var id: UUID
    
    /// Reference to the Exercise entity
    var exerciseId: UUID
    
    /// Exercise name (denormalized)
    var exerciseName: String
    
    /// Type of record (raw value)
    var recordTypeRaw: String
    
    /// Record value (weight, reps, or volume)
    var value: Double
    
    /// Previous record value (for improvement tracking)
    var previousValue: Double?
    
    /// When this record was achieved
    var achievedAt: Date
    
    /// Reference to the workout session where this PR was set
    var workoutSessionId: UUID?
    
    /// The player who holds this record
    @Relationship
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Record type enum
    var recordType: RecordType {
        get { RecordType(rawValue: recordTypeRaw) ?? .maxWeight }
        set { recordTypeRaw = newValue.rawValue }
    }
    
    /// Improvement over previous record
    var improvement: Double? {
        guard let prev = previousValue, prev > 0 else { return nil }
        return value - prev
    }
    
    /// Improvement as percentage
    var improvementPercent: Double? {
        guard let prev = previousValue, prev > 0 else { return nil }
        return ((value - prev) / prev) * 100
    }
    
    /// Formatted value based on record type
    var formattedValue: String {
        switch recordType {
        case .maxWeight, .estimated1RM:
            if value == floor(value) {
                return String(format: "%.0f kg", value)
            }
            return String(format: "%.1f kg", value)
        case .maxReps:
            return "\(Int(value)) reps"
        case .maxVolume:
            if value >= 1000 {
                return String(format: "%.1fk kg", value / 1000)
            }
            return String(format: "%.0f kg", value)
        }
    }
    
    // MARK: - Static Helpers
    
    /// Calculate estimated 1RM using Brzycki formula
    /// - Parameters:
    ///   - weight: Weight lifted
    ///   - reps: Reps completed (must be <= 12 for accuracy)
    /// - Returns: Estimated 1RM
    static func estimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0, reps <= 12, weight > 0 else { return weight }
        if reps == 1 { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        recordType: RecordType,
        value: Double,
        previousValue: Double? = nil,
        achievedAt: Date = Date(),
        workoutSessionId: UUID? = nil,
        player: Player? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.recordTypeRaw = recordType.rawValue
        self.value = value
        self.previousValue = previousValue
        self.achievedAt = achievedAt
        self.workoutSessionId = workoutSessionId
        self.player = player
    }
}
