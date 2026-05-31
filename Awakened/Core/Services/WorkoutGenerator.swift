import Foundation
import SwiftData

/// Protocol for workout generation — enables future AI implementation
protocol WorkoutGenerator {
    /// Generate a list of exercises for a workout
    /// - Parameters:
    ///   - focus: Target muscle groups
    ///   - duration: Target workout duration in minutes
    ///   - equipment: Available equipment
    ///   - level: Difficulty level
    /// - Returns: Array of template exercises
    func generateWorkout(
        focus: [MuscleGroup],
        duration: Int,
        equipment: [EquipmentType],
        level: ExerciseLevel
    ) async throws -> [TemplateExercise]
}

/// Default implementation: picks exercises from the database using filters
struct TemplateBasedGenerator: WorkoutGenerator {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func generateWorkout(
        focus: [MuscleGroup],
        duration: Int,
        equipment: [EquipmentType],
        level: ExerciseLevel
    ) async throws -> [TemplateExercise] {
        // Estimate exercise count from duration (~5 min per exercise including rest)
        let targetExerciseCount = max(3, min(12, duration / 5))
        
        // Fetch matching exercises
        let descriptor = FetchDescriptor<Exercise>()
        let allExercises = (try? context.fetch(descriptor)) ?? []
        
        // Filter by criteria
        let matching = allExercises.filter { exercise in
            let muscleMatch = focus.isEmpty || focus.contains(exercise.muscleGroup)
            let equipmentMatch = equipment.isEmpty || equipment.contains(exercise.equipment)
            let levelMatch = matchesLevel(exercise.level, target: level)
            return muscleMatch && equipmentMatch && levelMatch
        }
        
        guard !matching.isEmpty else { return [] }
        
        // Select exercises: prefer compound first, then isolation
        let compounds = matching.filter { $0.mechanic == .compound }.shuffled()
        let isolations = matching.filter { $0.mechanic == .isolation }.shuffled()
        
        var selected: [Exercise] = []
        
        // Add compound exercises (roughly 60% of workout)
        let compoundCount = max(2, Int(Double(targetExerciseCount) * 0.6))
        selected.append(contentsOf: compounds.prefix(compoundCount))
        
        // Fill remainder with isolation exercises
        let remainingCount = targetExerciseCount - selected.count
        selected.append(contentsOf: isolations.prefix(remainingCount))
        
        // Convert to TemplateExercise
        return selected.map { exercise in
            let isCompound = exercise.mechanic == .compound
            return TemplateExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                targetSets: isCompound ? 4 : 3,
                targetReps: isCompound ? "6-8" : "10-12",
                restSeconds: exercise.defaultRestSeconds
            )
        }
    }
    
    /// Check if an exercise level is appropriate for the target
    private func matchesLevel(_ exerciseLevel: ExerciseLevel, target: ExerciseLevel) -> Bool {
        switch target {
        case .beginner:
            return exerciseLevel == .beginner
        case .intermediate:
            return exerciseLevel == .beginner || exerciseLevel == .intermediate
        case .expert:
            return true // Expert can do any exercise
        }
    }
}

// MARK: - Future: AI Workout Generator (iOS 26+)
//
// When targeting iOS 26+, implement this:
//
// import FoundationModels
//
// @Generable struct GeneratedWorkout {
//     @Guide(description: "Workout name") let name: String
//     @Guide(description: "List of exercises with sets and reps") let exercises: [GeneratedExercise]
//     @Guide(description: "Estimated duration in minutes", .range(20...90)) let estimatedMinutes: Int
// }
//
// struct AIWorkoutGenerator: WorkoutGenerator {
//     func generateWorkout(...) async throws -> [TemplateExercise] {
//         let session = LanguageModelSession()
//         let prompt = "Generate a \(focus) workout for \(level) lifter, \(duration) minutes"
//         let response = try await session.respond(to: prompt, generating: GeneratedWorkout.self)
//         // Map GeneratedWorkout → [TemplateExercise]
//     }
// }
