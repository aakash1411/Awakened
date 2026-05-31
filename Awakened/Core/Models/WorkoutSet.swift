import Foundation
import SwiftData

/// Represents a single set within a workout session
@Model
final class WorkoutSet {
    
    /// Unique identifier
    var id: UUID
    
    /// Exercise name (denormalized for fast display)
    var exerciseName: String
    
    /// Reference to the Exercise entity
    var exerciseId: UUID?
    
    /// Set number within this exercise (1-based)
    var setNumber: Int
    
    /// Number of repetitions completed
    var reps: Int
    
    /// Weight used (in kg)
    var weight: Double
    
    /// Whether this was a warmup set
    var isWarmup: Bool
    
    /// Whether this was a drop set
    var isDropSet: Bool
    
    /// Whether the set was taken to failure
    var isFailure: Bool
    
    /// Rest taken after this set (seconds)
    var restSeconds: Int
    
    /// When this set was completed
    var completedAt: Date
    
    /// Optional notes for this set
    var notes: String
    
    /// The workout session this set belongs to
    @Relationship
    var session: WorkoutSession?
    
    // MARK: - Computed Properties
    
    /// Volume = weight × reps
    var volume: Double {
        Double(reps) * weight
    }
    
    /// Set type badge label
    var typeBadge: String? {
        if isWarmup { return "W" }
        if isDropSet { return "D" }
        if isFailure { return "F" }
        return nil
    }
    
    /// Formatted weight string
    var weightFormatted: String {
        if weight == floor(weight) {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseId: UUID? = nil,
        setNumber: Int = 1,
        reps: Int = 0,
        weight: Double = 0,
        isWarmup: Bool = false,
        isDropSet: Bool = false,
        isFailure: Bool = false,
        restSeconds: Int = 0,
        completedAt: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.isWarmup = isWarmup
        self.isDropSet = isDropSet
        self.isFailure = isFailure
        self.restSeconds = restSeconds
        self.completedAt = completedAt
        self.notes = notes
    }
}
