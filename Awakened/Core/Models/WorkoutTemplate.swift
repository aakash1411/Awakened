import Foundation
import SwiftData

/// A single exercise entry within a workout template
struct TemplateExercise: Codable, Identifiable, Hashable {
    
    /// Unique identifier
    var id: UUID
    
    /// Reference to Exercise entity
    var exerciseId: UUID
    
    /// Exercise name (denormalized for display)
    var exerciseName: String
    
    /// Target number of sets
    var targetSets: Int
    
    /// Target rep range (e.g., "8-12")
    var targetReps: String
    
    /// Last used weight (nil if never used)
    var targetWeight: Double?
    
    /// Rest duration in seconds
    var restSeconds: Int
    
    /// Optional notes
    var notes: String
    
    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        targetSets: Int = 3,
        targetReps: String = "8-12",
        targetWeight: Double? = nil,
        restSeconds: Int = 90,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

/// Saved workout template for recurring routines
@Model
final class WorkoutTemplate {
    
    /// Unique identifier
    var id: UUID
    
    /// Template name (e.g., "Push Day A")
    var name: String
    
    /// Description of the template
    var templateDescription: String
    
    /// Exercises stored as JSON data
    var exercisesData: Data
    
    /// When the template was created
    var createdAt: Date
    
    /// When the template was last used
    var lastUsedAt: Date?
    
    /// Number of times this template has been used
    var timesUsed: Int
    
    /// Whether this is a built-in template
    var isBuiltIn: Bool
    
    /// The player who owns this template
    @Relationship
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Decoded exercises array
    var exercises: [TemplateExercise] {
        get {
            (try? JSONDecoder().decode([TemplateExercise].self, from: exercisesData)) ?? []
        }
        set {
            exercisesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    /// Number of exercises in the template
    var exerciseCount: Int {
        exercises.count
    }
    
    /// Total target sets across all exercises
    var totalTargetSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }
    
    /// Muscle groups targeted (unique)
    var targetMuscleGroups: String {
        let names = exercises.map { $0.exerciseName }
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        return "\(names.prefix(2).joined(separator: ", ")) +\(names.count - 2) more"
    }
    
    // MARK: - Methods
    
    /// Mark template as used
    func markUsed() {
        lastUsedAt = Date()
        timesUsed += 1
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        templateDescription: String = "",
        exercises: [TemplateExercise] = [],
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        timesUsed: Int = 0,
        isBuiltIn: Bool = false,
        player: Player? = nil
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.exercisesData = (try? JSONEncoder().encode(exercises)) ?? Data()
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.timesUsed = timesUsed
        self.isBuiltIn = isBuiltIn
        self.player = player
    }
}
