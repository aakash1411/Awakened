import Foundation
import SwiftData

/// Parses the bundled exercises.json from free-exercise-db and seeds SwiftData
struct ExerciseDatabase {
    
    // MARK: - JSON Parsing Types
    
    /// Matches the JSON schema from yuhonas/free-exercise-db
    private struct ExerciseDBEntry: Codable {
        let id: String
        let name: String
        let force: String?
        let level: String
        let mechanic: String?
        let equipment: String?
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let instructions: [String]
        let category: String
        let images: [String]
    }
    
    // MARK: - Seeding
    
    /// Seed exercises from bundled JSON if not already done
    /// - Parameter context: SwiftData model context
    @MainActor
    static func seedIfNeeded(context: ModelContext) async {
        // Check if exercises already exist
        var descriptor = FetchDescriptor<Exercise>()
        descriptor.fetchLimit = 1
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else { return }
        
        // Parse and insert
        let exercises = parseExercisesJSON()
        for exercise in exercises {
            context.insert(exercise)
        }
        
        // Create built-in templates
        let templates = createBuiltInTemplates(from: exercises)
        for template in templates {
            context.insert(template)
        }
        
        try? context.save()
        
        #if DEBUG
        print("[ExerciseDatabase] Seeded \(exercises.count) exercises and \(templates.count) templates")
        #endif
    }
    
    // MARK: - JSON Parsing
    
    /// Parse the bundled exercises.json file
    /// - Returns: Array of Exercise models
    static func parseExercisesJSON() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            print("[ExerciseDatabase] exercises.json not found in bundle")
            return []
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("[ExerciseDatabase] Failed to read exercises.json")
            return []
        }
        
        guard let entries = try? JSONDecoder().decode([ExerciseDBEntry].self, from: data) else {
            print("[ExerciseDatabase] Failed to decode exercises.json")
            return []
        }
        
        return entries.map { entry in
            let externalId = entry.id
            
            let primaryMuscle = entry.primaryMuscles.first ?? "full body"
            let secondaryMuscles = entry.secondaryMuscles.joined(separator: ",")
            let instructions = entry.instructions.joined(separator: "\n\n")
            let images = entry.images.joined(separator: ",")
            
            return Exercise(
                externalId: externalId,
                name: entry.name,
                muscleGroupRaw: primaryMuscle,
                secondaryMusclesRaw: secondaryMuscles,
                equipmentRaw: entry.equipment ?? "body only",
                mechanicRaw: entry.mechanic ?? "compound",
                forceRaw: entry.force ?? "push",
                levelRaw: entry.level,
                instructions: instructions,
                imagePaths: images,
                isCustom: false,
                dbCategory: entry.category
            )
        }
    }
    
    // MARK: - Built-in Templates
    
    /// Create the 6 built-in workout templates
    /// - Parameter exercises: All seeded exercises
    /// - Returns: Array of WorkoutTemplate models
    static func createBuiltInTemplates(from exercises: [Exercise]) -> [WorkoutTemplate] {
        let exerciseMap = Dictionary(grouping: exercises) { $0.name.lowercased() }
        
        func findExercise(_ name: String) -> Exercise? {
            // Try exact match first, then partial
            if let matches = exerciseMap[name.lowercased()], let first = matches.first {
                return first
            }
            return exercises.first { $0.name.localizedCaseInsensitiveContains(name) }
        }
        
        func makeTemplateExercise(
            _ name: String,
            sets: Int = 3,
            reps: String = "8-12",
            rest: Int = 90
        ) -> TemplateExercise? {
            guard let exercise = findExercise(name) else { return nil }
            return TemplateExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                targetSets: sets,
                targetReps: reps,
                restSeconds: rest
            )
        }
        
        // Push Day
        let pushExercises = [
            makeTemplateExercise("Barbell Bench Press - Medium Grip", sets: 4, reps: "6-8", rest: 120),
            makeTemplateExercise("Overhead Press", sets: 3, reps: "8-10", rest: 90),
            makeTemplateExercise("Incline Dumbbell Press", sets: 3, reps: "8-12"),
            makeTemplateExercise("Side Lateral Raise", sets: 3, reps: "12-15", rest: 60),
            makeTemplateExercise("Triceps Pushdown", sets: 3, reps: "10-12", rest: 60),
            makeTemplateExercise("Dumbbell One-Arm Triceps Extension", sets: 3, reps: "10-12", rest: 60)
        ].compactMap { $0 }
        
        let pushDay = WorkoutTemplate(
            name: "Push Day",
            templateDescription: "Chest, shoulders, and triceps",
            exercises: pushExercises,
            isBuiltIn: true
        )
        
        // Pull Day
        let pullExercises = [
            makeTemplateExercise("Barbell Deadlift", sets: 4, reps: "5-6", rest: 180),
            makeTemplateExercise("Bent Over Barbell Row", sets: 4, reps: "6-8", rest: 120),
            makeTemplateExercise("Pullups", sets: 3, reps: "6-10", rest: 90),
            makeTemplateExercise("Seated Cable Rows", sets: 3, reps: "10-12"),
            makeTemplateExercise("Barbell Curl", sets: 3, reps: "10-12", rest: 60),
            makeTemplateExercise("Face Pull", sets: 3, reps: "12-15", rest: 60)
        ].compactMap { $0 }
        
        let pullDay = WorkoutTemplate(
            name: "Pull Day",
            templateDescription: "Back and biceps",
            exercises: pullExercises,
            isBuiltIn: true
        )
        
        // Leg Day
        let legExercises = [
            makeTemplateExercise("Barbell Squat", sets: 4, reps: "6-8", rest: 180),
            makeTemplateExercise("Leg Press", sets: 3, reps: "10-12", rest: 120),
            makeTemplateExercise("Romanian Deadlift", sets: 3, reps: "8-10", rest: 90),
            makeTemplateExercise("Leg Extensions", sets: 3, reps: "12-15", rest: 60),
            makeTemplateExercise("Lying Leg Curls", sets: 3, reps: "10-12", rest: 60),
            makeTemplateExercise("Standing Calf Raises", sets: 4, reps: "12-15", rest: 60)
        ].compactMap { $0 }
        
        let legDay = WorkoutTemplate(
            name: "Leg Day",
            templateDescription: "Quadriceps, hamstrings, glutes, and calves",
            exercises: legExercises,
            isBuiltIn: true
        )
        
        // Upper Body
        let upperExercises = [
            makeTemplateExercise("Barbell Bench Press - Medium Grip", sets: 3, reps: "8-10", rest: 120),
            makeTemplateExercise("Overhead Press", sets: 3, reps: "8-10", rest: 90),
            makeTemplateExercise("Bent Over Barbell Row", sets: 3, reps: "8-10", rest: 90),
            makeTemplateExercise("Pullups", sets: 3, reps: "6-10", rest: 90),
            makeTemplateExercise("Barbell Curl", sets: 3, reps: "10-12", rest: 60),
            makeTemplateExercise("Triceps Pushdown", sets: 3, reps: "10-12", rest: 60)
        ].compactMap { $0 }
        
        let upperBody = WorkoutTemplate(
            name: "Upper Body",
            templateDescription: "Complete upper body workout",
            exercises: upperExercises,
            isBuiltIn: true
        )
        
        // Lower Body
        let lowerExercises = [
            makeTemplateExercise("Barbell Squat", sets: 4, reps: "6-8", rest: 180),
            makeTemplateExercise("Barbell Deadlift", sets: 3, reps: "5-6", rest: 180),
            makeTemplateExercise("Dumbbell Lunges", sets: 3, reps: "10-12", rest: 90),
            makeTemplateExercise("Lying Leg Curls", sets: 3, reps: "10-12", rest: 60),
            makeTemplateExercise("Barbell Hip Thrust", sets: 3, reps: "10-12", rest: 90),
            makeTemplateExercise("Standing Calf Raises", sets: 4, reps: "12-15", rest: 60)
        ].compactMap { $0 }
        
        let lowerBody = WorkoutTemplate(
            name: "Lower Body",
            templateDescription: "Legs and glutes focus",
            exercises: lowerExercises,
            isBuiltIn: true
        )
        
        // Full Body
        let fullBodyExercises = [
            makeTemplateExercise("Barbell Squat", sets: 3, reps: "8-10", rest: 120),
            makeTemplateExercise("Barbell Bench Press - Medium Grip", sets: 3, reps: "8-10", rest: 120),
            makeTemplateExercise("Barbell Deadlift", sets: 3, reps: "5-6", rest: 180),
            makeTemplateExercise("Overhead Press", sets: 3, reps: "8-10", rest: 90),
            makeTemplateExercise("Pullups", sets: 3, reps: "6-10", rest: 90),
            makeTemplateExercise("Plank", sets: 3, reps: "30-60s", rest: 60)
        ].compactMap { $0 }
        
        let fullBody = WorkoutTemplate(
            name: "Full Body",
            templateDescription: "Hit every major muscle group",
            exercises: fullBodyExercises,
            isBuiltIn: true
        )
        
        return [pushDay, pullDay, legDay, upperBody, lowerBody, fullBody]
    }
}
